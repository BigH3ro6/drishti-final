import 'dart:developer';
import 'dart:typed_data';
import 'dart:isolate';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:yaml/yaml.dart';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';

class LocalObstacleService {
  Interpreter? _interpreter;
  Map<int, String> _labels = {};
  bool _isModelLoaded = false;

  bool get isModelLoaded => _isModelLoaded;

  Future<void> initModel() async {
    try {
      _interpreter = await Interpreter.fromAsset('assets/models/best_int8.tflite');
      debugPrint("🟢 INPUT SHAPE: ${_interpreter!.getInputTensor(0).shape}");
      debugPrint("🟢 INPUT TYPE: ${_interpreter!.getInputTensor(0).type}");
      debugPrint("🟢 OUTPUT SHAPE: ${_interpreter!.getOutputTensor(0).shape}");
      debugPrint("🟢 OUTPUT TYPE: ${_interpreter!.getOutputTensor(0).type}");
      final yamlString = await rootBundle.loadString('assets/models/metadata.yaml');
      final yamlMap = loadYaml(yamlString);
      
      if (yamlMap['names'] != null) {
        final names = yamlMap['names'] as Map;
        names.forEach((key, value) {
          _labels[key as int] = value.toString();
        });
      }
      
      _isModelLoaded = true;
      log("✅ TFLite Model & Labels loaded successfully!");
    } catch (e) {
      log("❌ Failed to load TFLite model: $e");
    }
  }

  void dispose() {
    _interpreter?.close();
  }

  // --- THE INFERENCE ENGINE ---
  Future<List<String>> detectObstacles(CameraImage cameraImage) async {
    if (!_isModelLoaded || _interpreter == null) return [];

    try {
      // 1. OFF-LOAD TO BACKGROUND THREAD: This completely cures the UI stutter!
      // We pass the raw bytes to an Isolate so the main app stays at 60 FPS.
      final int targetSize = 640;
      var inputTensor = await Isolate.run(() => _processImageInIsolate({
        'yPlane': cameraImage.planes[0].bytes,
        'uPlane': cameraImage.planes[1].bytes,
        'vPlane': cameraImage.planes[2].bytes,
        'yRowStride': cameraImage.planes[0].bytesPerRow,
        'uvRowStride': cameraImage.planes[1].bytesPerRow,
        'uvPixelStride': cameraImage.planes[1].bytesPerPixel!,
        'width': cameraImage.width,
        'height': cameraImage.height,
        'targetSize': targetSize,
      }));

      // 2. Prepare the output tensor. 
      // (We will likely need to adjust this based on your error log!)
      var outputTensor = List.generate(
        1, (i) => List.generate(
          11, (j) => List.filled(8400, 0.0) // <-- Changed 84 to 11!
        )
      );

      _interpreter!.run(inputTensor, outputTensor);

      return _parseYOLOv8Output(outputTensor, 0.55); 

    } catch (e) {
      // THIS LOG IS THE KEY TO FIXING THE BLINDNESS!
      debugPrint("❌ Inference Error: $e");
      return [];
    }
  }


  // Helper: Parses the complex YOLOv8 output matrix
  List<String> _parseYOLOv8Output(List<dynamic> output, double confidenceThreshold) {
    List<String> detectedObjects = [];
    
    double absoluteMaxScore = 0.0;
    String bestOverallGuess = "Nothing";
    
    // The output is [1][11][8400]. 
    for (int col = 0; col < 8400; col++) {
      double maxClassScore = 0.0;
      int classIndex = -1;

      // Scan through the 7 custom classes (rows 4 through 10)
      for (int row = 4; row < 11; row++) { 
        double score = output[0][row][col];
        if (score > maxClassScore) {
          maxClassScore = score;
          classIndex = row - 4; 
        }
      }

      // Track the absolute highest score in the entire frame for debugging
      if (maxClassScore > absoluteMaxScore) {
        absoluteMaxScore = maxClassScore;
        bestOverallGuess = _labels[classIndex] ?? "Unknown object";
      }

      // Lowered to 0.45 for mobile environments
      if (maxClassScore > 0.45) {
        String label = _labels[classIndex] ?? "Unknown object";
        if (!detectedObjects.contains(label)) {
          detectedObjects.add(label);
        }
      }
    }
    
    // Read the AI's mind!
    debugPrint("🧠 Best Guess: $bestOverallGuess at ${(absoluteMaxScore * 100).toStringAsFixed(1)}% confidence.");
    
    return detectedObjects;
}
}
// --- BACKGROUND WORKER (Runs on a separate CPU core) ---
List<List<List<List<double>>>> _processImageInIsolate(Map<String, dynamic> data) {
  final int targetSize = data['targetSize'];
  final int width = data['width'];
  final int height = data['height'];
  
  final Uint8List yPlane = data['yPlane'];
  final Uint8List uPlane = data['uPlane'];
  final Uint8List vPlane = data['vPlane'];
  final int yRowStride = data['yRowStride']; // The padding fix!
  final int uvRowStride = data['uvRowStride'];
  final int uvPixelStride = data['uvPixelStride'];

  // 1. Safely reconstruct the Android frame using the image package
  final img.Image rgbImage = img.Image(width: width, height: height);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final int uvIndex = (uvPixelStride * (x ~/ 2)) + (uvRowStride * (y ~/ 2));
      final int yIndex = (y * yRowStride) + x; // <-- Grabs the exact pixel, ignoring padding

      final yp = yPlane[yIndex];
      final up = uPlane[uvIndex];
      final vp = vPlane[uvIndex];

      int r = (yp + vp * 1436 ~/ 1024 - 179).clamp(0, 255);
      int g = (yp - up * 46549 ~/ 131072 + 44 - vp * 93604 ~/ 131072 + 91).clamp(0, 255);
      int b = (yp + up * 1814 ~/ 1024 - 227).clamp(0, 255);

      rgbImage.setPixelRgb(x, y, r, g, b);
    }
  }

  // 2. Rotate the image 90 degrees right-side-up and crop to 640x640
  img.Image rotatedImage = img.copyRotate(rgbImage, angle: 90);
  img.Image resizedImage = img.copyResize(rotatedImage, width: targetSize, height: targetSize);

  // 3. Normalize into the YOLOv8 Float32 Tensor [1, 640, 640, 3]
  var inputTensor = List.generate(
    1,
    (batch) => List.generate(
      targetSize,
      (y) => List.generate(
        targetSize,
        (x) {
          final pixel = resizedImage.getPixel(x, y);
          // YOLOv8 expects values between 0.0 and 1.0
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        },
      ),
    ),
  );

  return inputTensor;
}
