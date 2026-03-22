import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AccessibleCameraScreen extends StatefulWidget {
  final String instructionText; 
  
  const AccessibleCameraScreen({super.key, required this.instructionText});

  @override
  State<AccessibleCameraScreen> createState() => _AccessibleCameraScreenState();
}

class _AccessibleCameraScreenState extends State<AccessibleCameraScreen> {
  CameraController? _controller;
  final FlutterTts _tts = FlutterTts();
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      // 1. Get the list of available cameras
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;
      
      // 2. Grab the first camera (which is almost always the rear camera)
      final firstCamera = cameras.first;

      // 3. Initialize it with medium resolution (perfect for fast API uploads)
      _controller = CameraController(firstCamera, ResolutionPreset.medium, enableAudio: false);
      await _controller!.initialize();

      if (mounted) {
        setState(() => _isCameraInitialized = true);
        // 4. Read the instructions out loud as soon as the camera opens!
        await _tts.speak(widget.instructionText);
      }
    } catch (e) {
      debugPrint("Camera initialization error: $e");
      await _tts.speak("Error opening camera.");
      if (mounted) Navigator.pop(context, null);
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    if (_controller!.value.isTakingPicture) return;

    try {
      // 1. Give instant audio feedback that the tap worked
      await _tts.speak("Capturing photo.");
      
      // 2. Snap the picture!
      final XFile file = await _controller!.takePicture();
      
      // 3. Close the screen and return the file to the Dashboard
      if (mounted) Navigator.pop(context, file);
    } catch (e) {
      debugPrint("Picture capture error: $e");
      await _tts.speak("Failed to take photo.");
      if (mounted) Navigator.pop(context, null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _takePicture, 
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: double.infinity,
          height: double.infinity,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Show the live camera feed so sighted helpers can see it if needed
              CameraPreview(_controller!),
              
              // Add a subtle overlay so it looks like a scanner
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: Icon(Icons.document_scanner, color: Colors.white54, size: 100),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}