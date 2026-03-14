import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/core/services/voice_assistant_service.dart';
import 'package:user_mobile/features/blind_mode/screens/blind_profile_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class BlindDashboardScreen extends StatefulWidget {
  const BlindDashboardScreen({super.key});

  @override
  State<BlindDashboardScreen> createState() => _BlindDashboardScreenState();
}

class _BlindDashboardScreenState extends State<BlindDashboardScreen> {
  late VoiceAssistantService _voiceService;
  bool _isListeningUI = false; 

  @override
  void initState() {
    super.initState();
    
    // Initialize voice service and handle UI state changes
    _voiceService = VoiceAssistantService(
      onCommandRecognized: _handleVoiceCommand,
      onListeningStateChanged: (bool isListening) {
        if (mounted) {
          setState(() {
            _isListeningUI = isListening;
          });
        }
      },
    );

    // Initialize background wake word listener
    String accessKey = dotenv.env['PICOVOICE_ACCESS_KEY'] ?? '';
    _voiceService.initWakeWord(accessKey);

    // Initial greeting
    Future.delayed(const Duration(seconds: 1), () {
      _voiceService.speak(
        "Welcome to Drishti. Tap anywhere on the screen and speak.",
      );
    });
  }

  // Maps recognized voice commands to specific app features
  void _handleVoiceCommand(String command) {
    setState(() => _isListeningUI = false); 

    switch (command) {
      case "call_caregiver":
        _showDummyAction("📞 Calling Caregiver...");
        break;
      case "currency":
        _showDummyAction("💵 Opening Currency Scanner...");
        break;
      case "navigate":
        _showDummyAction("🗺️ Opening GPS Navigation...");
        break;
      case "weather":
        _showDummyAction("🌤️ Fetching Weather...");
        break;
      case "message_caregiver":
        _showDummyAction("🎙️ Opening Voice Recorder...");
        break;
      case "sos":
        _showDummyAction("🚨 ACTIVATING SOS!");
        // TODO: Navigate to SOS countdown screen
        break;
      case "obstacle":
        _showDummyAction("🚧 Opening Obstacle Detection...");
        break;
      case "read_text":
        _showDummyAction("📄 Opening Document Scanner...");
        break;
      case "current_location":
        _showDummyAction("📍 Finding Current Location...");
        break;
      case "system_status":
        _showDummyAction("🔋 Checking Time & Battery...");
        break;
      default:
        break;
    }
  }

  // Temporary helper for testing command routing
  void _showDummyAction(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurpleAccent,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 30),
            onPressed: () {
              // Pause microphone before navigating away
              if (_isListeningUI) {
                _voiceService.stopListening();
                setState(() => _isListeningUI = false);
              }
              
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const BlindProfileScreen(), 
                ),
              );
            },
          ),
          const SizedBox(width: 10), 
        ],
      ),
      // Full-screen tap target for accessibility
      body: GestureDetector(
        onTap: () {
          setState(() => _isListeningUI = true);
          _voiceService.startListening();
        },
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(gradient: AppColors.mainGradient),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _isListeningUI ? Icons.mic : Icons.touch_app,
                  size: 120,
                  color: _isListeningUI ? Colors.redAccent : Colors.white,
                ),
                const SizedBox(height: 40),
                Text(
                  _isListeningUI ? "Listening..." : "Tap anywhere to speak",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    "Try saying:\n'Call my caregiver'\n'Read currency'\n'Activate SOS'",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white70,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}