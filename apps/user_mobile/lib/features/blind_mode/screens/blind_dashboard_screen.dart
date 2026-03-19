import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/core/services/voice_assistant_service.dart';
import 'package:user_mobile/features/blind_mode/screens/blind_profile_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:user_mobile/core/services/weather_api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:user_mobile/features/blind_mode/screens/obstacle_debug_screen.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:intl/intl.dart';
import 'package:user_mobile/core/services/pairing_api_service.dart';
import 'package:user_mobile/core/services/live_location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class BlindDashboardScreen extends StatefulWidget {
  const BlindDashboardScreen({super.key});

  @override
  State<BlindDashboardScreen> createState() => _BlindDashboardScreenState();
}

class _BlindDashboardScreenState extends State<BlindDashboardScreen> {
  late VoiceAssistantService _voiceService;
  bool _isListeningUI = false; 
  final LiveLocationService _locationService = LiveLocationService();

  @override
  void initState() {
    super.initState();
    _locationService.startTracking();
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

  @override
  void dispose() {
    // Make sure to stop the timer if they close the screen
    _locationService.stopTracking();
    super.dispose();
  }
  // Maps recognized voice commands to specific app features
  void _handleVoiceCommand(String command) async{
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
        // 1. Tell the user we are working on it
        _showDummyAction("🌤️ Fetching Weather...");
        await _voiceService.speak("Checking the weather for your location...");
        
        // 2. Call the backend API
        String weatherResult = await WeatherApiService().fetchCurrentWeather();
        
        // 3. Speak the result out loud!
        await _voiceService.speak(weatherResult);
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
        try {
          // 1. Ask the phone for the exact current GPS coordinates
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high
          );
          
          // 2. Translate the coordinates into a human-readable street name
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude, position.longitude
          );
          
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            // Format it to sound natural when spoken out loud
            String address = "${place.street}, ${place.locality}";
            
            // 3. Speak the result to the user!
            await _voiceService.speak("You are currently near $address.");
          } else {
            await _voiceService.speak("I found your location, but couldn't determine the exact street name.");
          }
        } catch (e) {
          debugPrint("Location error: $e");
          await _voiceService.speak("Sorry, I couldn't access your GPS. Please make sure your location services are turned on.");
        }
        break;
      case "time":
        _showDummyAction("🕒 Checking Time...");
        final now = DateTime.now();
        final timeString = DateFormat('h:mm a').format(now);
        await _voiceService.speak("It is $timeString.");
        break;

      case "battery":
        _showDummyAction("🔋 Checking Battery...");
        final battery = Battery();
        final batteryLevel = await battery.batteryLevel;
        await _voiceService.speak("Your battery is at $batteryLevel percent.");
        break;

      case "system_status":
        _showDummyAction("📊 Checking System Status...");
        try {
          // 1. Time & Date
          final now = DateTime.now();
          final timeString = DateFormat('h:mm a').format(now);
          final dateString = DateFormat('EEEE, MMMM d').format(now);

          // 2. Battery
          final battery = Battery();
          final batteryLevel = await battery.batteryLevel;

          // 3. Network Connectivity
          final connectivityResult = await Connectivity().checkConnectivity();
          String networkStatus = "no internet connection";
          
          if (connectivityResult.contains(ConnectivityResult.wifi)) {
            networkStatus = "connected to Wi-Fi";
          } else if (connectivityResult.contains(ConnectivityResult.mobile)) {
            networkStatus = "connected to a mobile network";
          }

          // 4. Volume Level (Returns 0.0 to 1.0, so we multiply by 100)
          double volumeVal = await VolumeController.instance.getVolume();           int volumePercent = (volumeVal * 100).round();

          // 5. Construct status report!
          String fullStatus = "It is $timeString on $dateString. "
              "Your battery is at $batteryLevel percent. "
              "You are $networkStatus, and your device volume is at $volumePercent percent.";

          await _voiceService.speak(fullStatus);
          
        } catch (e) {
          debugPrint("System status error: $e");
          await _voiceService.speak("I couldn't read the full system status right now.");
        }
        break;
      case "pair_caregiver":
        _showDummyAction("🔗 Generating pairing code...");
        
        await _voiceService.speak("Getting your secure pairing code. Please wait.");
        
        String? code = await PairingApiService().generatePairingCode();
        
        if (code != null) {
          // 1. THE VISUAL FIX: Display the code on the screen for sighted helpers!
          _showDummyAction("Pairing Code:\n$code");
          
          // 2. THE AUDIO FIX: Commas force the TTS engine to pause between characters.
          String spokenCode = code.split('').join(', ');
          
          String message = "Your pairing code is, $spokenCode. "
              "I will repeat that. $spokenCode. "
              "Please ask your caregiver to enter this code in their app.";
              
          await _voiceService.speak(message);
        } else {
          _showDummyAction("❌ Connection Error");
          await _voiceService.speak("Sorry, I couldn't generate a code right now. Please check your internet connection.");
        }
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const ObstacleDebugScreen()));
        },
        child: const Icon(Icons.bug_report),
      ),
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
        onTap: () async {
          setState(() => _isListeningUI = true);
          await _voiceService.triggerManualListen();
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