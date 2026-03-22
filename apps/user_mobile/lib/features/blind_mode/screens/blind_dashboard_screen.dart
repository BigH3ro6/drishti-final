import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/core/services/voice_assistant_service.dart';
import 'package:user_mobile/features/blind_mode/screens/blind_audio_player_screen.dart';
import 'package:user_mobile/features/blind_mode/screens/blind_profile_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:user_mobile/core/services/weather_api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:user_mobile/features/blind_mode/screens/blind_voice_record_screen.dart';
import 'package:user_mobile/features/blind_mode/screens/blind_walking_mode_screen.dart';
import 'package:volume_controller/volume_controller.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:intl/intl.dart';
import 'package:user_mobile/core/services/pairing_api_service.dart';
import 'package:user_mobile/core/services/live_location_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:user_mobile/core/services/system_telemetry_service.dart';
import 'package:user_mobile/core/services/safety_api_service.dart';
import 'package:flutter_phone_direct_caller/flutter_phone_direct_caller.dart';
import 'package:image_picker/image_picker.dart';
import 'package:user_mobile/core/services/vision_api_service.dart';
import 'package:user_mobile/features/blind_mode/screens/accessible_camera_screen.dart';

class BlindDashboardScreen extends StatefulWidget {
  const BlindDashboardScreen({super.key});

  @override
  State<BlindDashboardScreen> createState() => _BlindDashboardScreenState();
}

class _BlindDashboardScreenState extends State<BlindDashboardScreen> {
  late VoiceAssistantService _voiceService;
  bool _isListeningUI = false;
  final LiveLocationService _locationService = LiveLocationService();
  final SystemTelemetryService _telemetryService = SystemTelemetryService();
  bool _isSelectingCaregiver = false;
  String _pendingCaregiverAction = "";

  final PairingApiService _pairingApi = PairingApiService();
  List<Map<String, dynamic>> _caregivers = [];

  @override
  void initState() {
    super.initState();
    _locationService.startTracking();
    _telemetryService.startTelemetry();
    _voiceService = VoiceAssistantService(
      onCommandRecognized: _handleVoiceCommand,
      onListeningStateChanged: (bool isListening) {
        if (mounted) {
          setState(() {
            _isListeningUI = isListening;
          });
        }
        _fetchRealCaregivers();
      },
    );

    // Initialize background wake word listener
    String accessKey = dotenv.env['PICOVOICE_ACCESS_KEY'] ?? '';
    _voiceService.initWakeWord(accessKey);
    _runStartupCheck();
    // Initial greeting
    Future.delayed(const Duration(seconds: 1), () {
      _voiceService.speak(
        "Welcome to Drishti. Tap anywhere on the screen and speak.",
      );
    });
  }

  Future<void> _runStartupCheck() async {
    await Future.delayed(const Duration(seconds: 1));
    await _voiceService.speak(
      "Welcome to Drishti. Tap anywhere on the screen and speak.",
    );
  }

  Future<void> _fetchRealCaregivers() async {
    final realList = await _pairingApi.getLinkedUsers();

    if (mounted) {
      setState(() {
        _caregivers = realList;
      });
      debugPrint("Fetched Caregivers: $_caregivers");
    }
  }

  @override
  void dispose() {
    _locationService.stopTracking();
    _telemetryService.stopTelemetry();
    super.dispose();
  }

  Future<void> _makePhoneCall(String? phoneNumber, String caregiverName) async {
    if (phoneNumber == null || phoneNumber.isEmpty) {
      await _voiceService.speak(
        "Sorry, I don't have a phone number saved for $caregiverName.",
      );
      return;
    }

    await _voiceService.speak("Calling $caregiverName.");

    // 1. Trigger the direct phone call!
    bool? didCall = await FlutterPhoneDirectCaller.callNumber(phoneNumber);

    // 2. Handle failures (e.g., if the user denied the phone permission)
    if (didCall == null || !didCall) {
      await _voiceService.speak(
        "I was unable to place the call. Please ensure phone permissions are granted in your settings.",
      );
    }
  }

  // Maps recognized voice commands to specific app features
  void _handleVoiceCommand(String command, String rawText) async {
    if (mounted) {
      setState(() {
        _isListeningUI = false;
      });
    }
    if (_isSelectingCaregiver) {
      _processCaregiverSelection(rawText);
      return;
    }

    switch (command) {
      case "call_caregiver":
        if (_caregivers.isEmpty) {
          await _voiceService.speak(
            "You don't have any caregivers paired yet.",
          );
        } else if (_caregivers.length == 1) {
          final singleCaregiver = _caregivers[0];
          await _makePhoneCall(
            singleCaregiver['phone'],
            singleCaregiver['name'] ?? "Caregiver",
          );
        } else {
          _isSelectingCaregiver = true;
          _pendingCaregiverAction = "call";
          List<String> caregiverNames = _caregivers
              .map((c) => c["name"]?.toString() ?? "Caregiver")
              .toList();
          String namesToSpeak = caregiverNames.join(", or ");

          await _voiceService.speak(
            "Which caregiver do you want to call? Say the name. $namesToSpeak.",
          );
          await _voiceService.triggerManualListen();
        }
        break;
      case "currency":
        // 1. Open the accessible full-screen camera
        final XFile? image = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AccessibleCameraScreen(
              instructionText: "Currency scanner ready. Hold the note in front of the camera and tap anywhere to capture.",
            ),
          ),
        );
        
        // 2. Process the image through the API
        if (image != null) {
          await _voiceService.speak("Analyzing currency. Please wait.");
          
          final String? result = await VisionApiService().recognizeCurrency(image.path);
          
          if (result != null && result.isNotEmpty) {
            await _voiceService.speak(result);
          } else {
            await _voiceService.speak("I couldn't analyze the note. Please ensure it is well lit and try again.");
          }
        } else {
          await _voiceService.speak("Scan cancelled.");
        }
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
      case "play_messages":
        if (_caregivers.isEmpty) {
          await _voiceService.speak(
            "You don't have any paired caregivers yet.",
          );
        } else {
          // Pass the Chat ID and Name of the first paired caregiver!
          final targetCaregiver = _caregivers[0];

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BlindAudioPlayerScreen(
                chatId: targetCaregiver["chatId"] ?? "",
                caregiverName: targetCaregiver["name"] ?? "Caregiver",
              ),
            ),
          );
        }
        break;
      case "message_caregiver":
        if (_caregivers.isEmpty) {
          // Safety check: No caregivers paired at all
          await _voiceService.speak(
            "You don't have any caregivers paired yet.",
          );
        } else if (_caregivers.length == 1) {
          final singleCaregiver = _caregivers[0];

          await _voiceService.speak(
            "Getting ready to send a message to ${singleCaregiver['name']}.",
          );

          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BlindVoiceRecordScreen(
                  targetChatId: singleCaregiver["chatId"]!,
                  targetCaregiverId: singleCaregiver["id"]!,
                  caregiverName: singleCaregiver["name"]!,
                ),
              ),
            );
          }
        } else {
          _isSelectingCaregiver = true;
          _pendingCaregiverAction = "message";
          List<String> caregiverNames = _caregivers
              .map((c) => c["name"]?.toString() ?? "Caregiver")
              .toList();
          String namesToSpeak = caregiverNames.join(", or ");

          await _voiceService.speak(
            "Which caregiver? Say the name. $namesToSpeak.",
          );
          await _voiceService.triggerManualListen();
        }
        break;
      case "sos":
        _showDummyAction("🚨 ACTIVATING SOS!");

        try {
          // Grab the live emergency GPS coordinates
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          // Hit the Python backend!
          bool success = await SafetyApiService().triggerSOS(
            position.latitude,
            position.longitude,
          );

          if (success) {
            // Speak ONLY ONCE when the alert is successfully sent
            await _voiceService.speak(
              "S O S activated. Your caregivers have been alerted.",
            );
          } else {
            await _voiceService.speak(
              "Failed to send alert to the server. Please call for help immediately.",
            );
          }
        } catch (e) {
          debugPrint("SOS Location Error: $e");
          // Fallback: Send with 0.0, 0.0 if GPS fails so the Caregiver still gets the alarm!
          bool success = await SafetyApiService().triggerSOS(0.0, 0.0);
          if (success) {
            await _voiceService.speak(
              "S O S activated without location. Caregivers alerted.",
            );
          }
        }
        break;
      case "obstacle":
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const BlindWalkingModeScreen(),
          ),
        );
        break;
      case "describe":
        // 1. Open our custom accessible camera!
        final XFile? image = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AccessibleCameraScreen(
              instructionText: "Scene describer ready. Point your phone ahead and tap anywhere to capture.",
            ),
          ),
        );
        
        // 2. Process the image through the Cloud API
        if (image != null) {
          await _voiceService.speak("Analyzing scene. Please wait.");
          
          final String? description = await VisionApiService().describeSurroundings(image.path);
          
          if (description != null && description.isNotEmpty) {
            await _voiceService.speak("Here is what I see: $description");
          } else {
            await _voiceService.speak("I couldn't analyze the scene right now. Please check your internet connection and try again.");
          }
        } else {
          await _voiceService.speak("Scan cancelled.");
        }
        break;
      case "read_text":
        // 1. Open our custom full-screen camera and pass the OCR instructions!
        final XFile? image = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AccessibleCameraScreen(
              instructionText:
                  "Document scanner ready. Point your phone at the text and tap anywhere on the screen to capture.",
            ),
          ),
        );

        // 2. If they took a picture, send it to Python!
        if (image != null) {
          await _voiceService.speak("Processing image. Please wait.");

          final String? extractedText = await VisionApiService()
              .readTextFromImage(image.path);

          if (extractedText != null &&
              extractedText.isNotEmpty &&
              extractedText != "No text detected") {
            await _voiceService.speak("Here is what I read: $extractedText");
          } else {
            await _voiceService.speak(
              "I couldn't detect any readable text. Please ensure the area is well lit and try again.",
            );
          }
        } else {
          await _voiceService.speak("Scan cancelled.");
        }
        break;
      case "current_location":
        _showDummyAction("📍 Finding Current Location...");
        try {
          // 1. Ask the phone for the exact current GPS coordinates
          Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          // 2. Translate the coordinates into a human-readable street name
          List<Placemark> placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          );

          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            // Format it to sound natural when spoken out loud
            String address = "${place.street}, ${place.locality}";

            // 3. Speak the result to the user!
            await _voiceService.speak("You are currently near $address.");
          } else {
            await _voiceService.speak(
              "I found your location, but couldn't determine the exact street name.",
            );
          }
        } catch (e) {
          debugPrint("Location error: $e");
          await _voiceService.speak(
            "Sorry, I couldn't access your GPS. Please make sure your location services are turned on.",
          );
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
          double volumeVal = await VolumeController.instance.getVolume();
          int volumePercent = (volumeVal * 100).round();

          // 5. Construct status report!
          String fullStatus =
              "It is $timeString on $dateString. "
              "Your battery is at $batteryLevel percent. "
              "You are $networkStatus, and your device volume is at $volumePercent percent.";

          await _voiceService.speak(fullStatus);
        } catch (e) {
          debugPrint("System status error: $e");
          await _voiceService.speak(
            "I couldn't read the full system status right now.",
          );
        }
        break;
      case "pair_caregiver":
        _showDummyAction("🔗 Generating pairing code...");

        await _voiceService.speak(
          "Getting your secure pairing code. Please wait.",
        );

        String? code = await PairingApiService().generatePairingCode();

        if (code != null) {
          _showDummyAction("Pairing Code:\n$code");
          String spokenCode = code.split('').join(', ');

          String message =
              "Your pairing code is, $spokenCode. "
              "I will repeat that. $spokenCode. "
              "Please ask your caregiver to enter this code in their app.";

          await _voiceService.speak(message);
        } else {
          _showDummyAction("❌ Connection Error");
          await _voiceService.speak(
            "Sorry, I couldn't generate a code right now. Please check your internet connection.",
          );
        }
        break;

      case "raw_text":
        // Fallback for random noise
        await _voiceService.speak("I didn't catch that. Please try again.");
        break;
      default:
        break;
    }
  }

  void _processCaregiverSelection(String rawText) async {
    _isSelectingCaregiver = false;
    Map<String, dynamic>? selectedCaregiver;

    // ---Loop through the names ---
    for (int i = 0; i < _caregivers.length; i++) {
      final String caregiverName = _caregivers[i]["name"]
          .toString()
          .toLowerCase();
      final String caregiverNumber = (i + 1)
          .toString(); // Checks for "1", "2", etc.

      // If the user says their actual name, or their number in the list:
      if (rawText.toLowerCase().contains(caregiverName) ||
          rawText.contains(caregiverNumber)) {
        selectedCaregiver = _caregivers[i];
        break;
      }
    }

    if (selectedCaregiver != null) {
      if (_pendingCaregiverAction == "call") {
        // ACTION: Trigger the phone dialer!
        await _makePhoneCall(
          selectedCaregiver["phone"],
          selectedCaregiver["name"] ?? "Caregiver",
        );
      } else {
        // ACTION: Default to voice message screen!
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlindVoiceRecordScreen(
              targetChatId: selectedCaregiver!["chatId"]!,
              targetCaregiverId: selectedCaregiver["id"]!,
              caregiverName: selectedCaregiver["name"]!,
            ),
          ),
        );
      }
    } else {
      await _voiceService.speak(
        "I didn't recognize that caregiver. Selection cancelled.",
      );
    }
    // Reset the pending action so it's clean for next time
    _pendingCaregiverAction = "";
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
