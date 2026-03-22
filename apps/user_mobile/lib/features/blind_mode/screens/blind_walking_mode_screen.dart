import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:vibration/vibration.dart';
import 'package:user_mobile/core/services/local_obstacle_service.dart';

class BlindWalkingModeScreen extends StatefulWidget {
  const BlindWalkingModeScreen({super.key});

  @override
  State<BlindWalkingModeScreen> createState() => _BlindWalkingModeScreenState();
}

class _BlindWalkingModeScreenState extends State<BlindWalkingModeScreen> {
  CameraController? _cameraController;
  final FlutterTts _tts = FlutterTts();
  final LocalObstacleService _mlService = LocalObstacleService();
  
  bool _isCameraReady = false;
  bool _isProcessingFrame = false;
  bool _isShuttingDown = false;
  bool _canPop = false; // <-- NEW: Allows us to securely bypass the PopScope

  @override
  void initState() {
    super.initState();
    _initSystem();
  }

  Future<void> _initSystem() async {
    await _tts.speak("Walking mode activated. Scanning environment.");
    await _mlService.initModel();

    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

    _cameraController = CameraController(cameras.first, ResolutionPreset.low, enableAudio: false);
    await _cameraController!.initialize();
    
    if (mounted) {
      setState(() => _isCameraReady = true);
    }

    _cameraController!.startImageStream((CameraImage frame) {
      if (_isProcessingFrame || !_mlService.isModelLoaded) return;
      _processCameraFrame(frame);
    });
  }

  Future<void> _processCameraFrame(CameraImage frame) async {
    if (_isShuttingDown) return;
    _isProcessingFrame = true;

    try {
      List<String> detections = await _mlService.detectObstacles(frame);
      
      if (detections.isNotEmpty && !_isShuttingDown) {
        // We check for the vibrator safely
        final hasVibrator = await Vibration.hasVibrator();
        
        if (hasVibrator == true) { // Explicitly check for true
          Vibration.vibrate(duration: 300, amplitude: 255);
        }
        
        String primaryObstacle = detections.first;
        await _tts.speak("Caution. $primaryObstacle ahead.");
        
        await Future.delayed(const Duration(seconds: 3)); 
      }
    } finally {
      _isProcessingFrame = false; 
    }
  }

  // --- THE NEW, PERFECTLY SEQUENCED SHUTDOWN ---
  Future<void> _closeScreen() async {
    if (_isShuttingDown) return;
    _isShuttingDown = true; // 1. Lock out new frames instantly

    try {
      // 2. Stop the stream WHILE the CameraPreview is still on the screen!
      if (_cameraController != null && _cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
      
      // 3. Give the hardware a microsecond to breathe
      await Future.delayed(const Duration(milliseconds: 100));
      
      // 4. Dispose the camera
      if (_cameraController != null) {
        await _cameraController!.dispose();
        _cameraController = null;
      }
    } catch (e) {
      debugPrint("Camera Teardown Error: $e");
    } finally {
      // 5. Clean up AI and safely pop the screen
      if (mounted) {
        setState(() => _canPop = true); // Tell PopScope we are allowed to leave
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    // Failsafe in case the OS destroys the app
    if (!_isShuttingDown) {
      _cameraController?.dispose();
    }
    _mlService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 6. Wrap the ENTIRE widget tree in PopScope
    return PopScope(
      canPop: _canPop, 
      onPopInvoked: (didPop) async {
        if (didPop) return;
        await _tts.speak("Walking mode deactivated.");
        await _closeScreen();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        // Wait for camera to be ready, otherwise show loader
        body: !_isCameraReady 
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : GestureDetector(
              onTap: () async {
                await _tts.speak("Walking mode deactivated.");
                await _closeScreen(); // Call our safe teardown
              },
              behavior: HitTestBehavior.opaque,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_cameraController != null) CameraPreview(_cameraController!),
                  Container(
                    color: Colors.redAccent.withOpacity(0.2),
                    child: const Center(
                      child: Icon(Icons.directions_walk, color: Colors.white54, size: 100),
                    ),
                  ),
                  const Positioned(
                    bottom: 40,
                    left: 0,
                    right: 0,
                    child: Text(
                      "Tap anywhere to stop walking mode",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
      ),
    );
  }
}