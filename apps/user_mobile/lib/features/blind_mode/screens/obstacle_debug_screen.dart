import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:user_mobile/core/constants/api_constants.dart';
import 'package:user_mobile/core/app_colors.dart';

class ObstacleDebugScreen extends StatefulWidget {
  const ObstacleDebugScreen({super.key});

  @override
  State<ObstacleDebugScreen> createState() => _ObstacleDebugScreenState();
}

class _ObstacleDebugScreenState extends State<ObstacleDebugScreen> {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isRecording = false;
  String _statusText = "Ready to test.";
  String _serverResponse = "";

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Use the back camera
      final backCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      // Medium resolution is usually best for ML (faster uploads, less memory)
      _cameraController = CameraController(backCamera, ResolutionPreset.medium);
      await _cameraController!.initialize();
      
      if (mounted) {
        setState(() => _isCameraInitialized = true);
      }
    } catch (e) {
      setState(() => _statusText = "Camera Error: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  // --- METHOD 1: TEST IMAGE PIPELINE ---
  Future<void> _testImageDetection() async {
    if (!_isCameraInitialized || _cameraController == null) return;

    setState(() {
      _isProcessing = true;
      _statusText = "Snapping picture...";
      _serverResponse = "";
    });

    try {
      final XFile imageFile = await _cameraController!.takePicture();
      setState(() => _statusText = "Uploading image to Python...");
      
      await _uploadMedia(imageFile.path, "detect-obstacle-image");
    } catch (e) {
      setState(() => _statusText = "Error taking picture: $e");
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // --- METHOD 2: TEST VIDEO PIPELINE (5 SECONDS) ---
  Future<void> _testVideoDetection() async {
    if (!_isCameraInitialized || _cameraController == null) return;

    setState(() {
      _isProcessing = true;
      _isRecording = true;
      _statusText = "Recording 5-second video...";
      _serverResponse = "";
    });

    try {
      await _cameraController!.startVideoRecording();
      
      // Wait exactly 5 seconds!
      await Future.delayed(const Duration(seconds: 5));
      
      final XFile videoFile = await _cameraController!.stopVideoRecording();
      
      setState(() {
        _isRecording = false;
        _statusText = "Uploading video to Python...";
      });

      await _uploadMedia(videoFile.path, "detect-obstacle-video");
    } catch (e) {
      setState(() {
        _isRecording = false;
        _statusText = "Error recording video: $e";
      });
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // --- THE NETWORK UPLOADER ---
  Future<void> _uploadMedia(String filePath, String endpoint) async {
    try {
      var request = http.MultipartRequest(
        'POST', 
        Uri.parse('${ApiConstants.baseUrl}/$endpoint')
      );
      
      // Attach the file to the 'file' field matching your Flask route
      request.files.add(await http.MultipartFile.fromPath('file', filePath));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var data = jsonDecode(response.body);
        setState(() {
          _statusText = "Success!";
          _serverResponse = "Model Output: ${data['message']}";
        });
      } else {
        setState(() => _statusText = "Server Error: ${response.statusCode}\n${response.body}");
      }
    } catch (e) {
      setState(() => _statusText = "Network Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Obstacle ML Debugger", style: GoogleFonts.poppins()),
        backgroundColor: AppColors.purpleDark,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // CAMERA PREVIEW BOX
            Container(
              height: 300,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(15),
              ),
              clipBehavior: Clip.hardEdge,
              child: _isCameraInitialized
                  ? CameraPreview(_cameraController!)
                  : const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
            const SizedBox(height: 20),

            // STATUS MONITOR
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(10)),
              child: Column(
                children: [
                  Text(_statusText, style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: _isRecording ? Colors.red : Colors.black)),
                  const SizedBox(height: 10),
                  Text(_serverResponse, style: GoogleFonts.poppins(color: AppColors.purpleDark, fontSize: 16), textAlign: TextAlign.center),
                ],
              ),
            ),
            const Spacer(),

            // THE TWO TEST BUTTONS
            ElevatedButton.icon(
              icon: const Icon(Icons.camera_alt),
              label: const Text("Test Image Pipeline"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purpleLight,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: _isProcessing ? null : _testImageDetection,
            ),
            const SizedBox(height: 15),
            
            ElevatedButton.icon(
              icon: _isRecording ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.videocam),
              label: Text(_isRecording ? "Recording..." : "Test 5s Video Pipeline"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purpleDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              onPressed: _isProcessing ? null : _testVideoDetection,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}