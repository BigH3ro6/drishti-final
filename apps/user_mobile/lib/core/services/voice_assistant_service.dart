import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:porcupine_flutter/porcupine_manager.dart'; 
import 'package:porcupine_flutter/porcupine_error.dart';

class VoiceAssistantService {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  PorcupineManager? _porcupineManager; 
  
  bool _isListening = false;
  bool _isWakeWordListening = false;

  final Function(String command) onCommandRecognized;
  final Function(bool isListening)? onListeningStateChanged;

  VoiceAssistantService({
    required this.onCommandRecognized,
    this.onListeningStateChanged,
  }) {
    _init();
  }

  Future<void> _init() async {
    await _flutterTts.setLanguage("en-US");
    await _flutterTts.setSpeechRate(0.5); 
    await _flutterTts.setPitch(1.0);
    
    await _speechToText.initialize(
      onError: (error) {
        debugPrint('Speech error: ${error.errorMsg}');
        _isListening = false;
        onListeningStateChanged?.call(false);
        
        if (error.errorMsg == 'error_speech_timeout') {
          speak("I didn't hear anything. Tap the screen to try again.");
        }
        
        // If STT fails or times out, go back to listening for the wake word
        _startWakeWordListening();
      },
      onStatus: (status) {
        debugPrint('Speech status: $status');
        if (status == 'done' || status == 'notListening') {
          _isListening = false;
          onListeningStateChanged?.call(false);
          
          // If STT finishes successfully, go back to listening for the wake word
          _startWakeWordListening();
        }
      },
    );
  }

  // --- WAKE WORD LOGIC ---
  Future<void> initWakeWord(String accessKey) async {
    try {
      _porcupineManager = await PorcupineManager.fromKeywordPaths(
        accessKey,
        ["assets/wake_words/Hey-Dish-tea_en_android_v4_0_0.ppn"],
        _wakeWordCallback,
      );
      await _startWakeWordListening();
    } on PorcupineException catch (e) {
      debugPrint("Failed to initialize Porcupine: $e");
    }
  }

void _wakeWordCallback(int keywordIndex) async {
    if (keywordIndex >= 0) {
      debugPrint("Wake word detected!");
      _isWakeWordListening = false; 
      await _porcupineManager?.stop(); 
      
      onListeningStateChanged?.call(true); 
      await Future.delayed(const Duration(milliseconds: 800));
      await startListening(); 
    }
  }

  // Safely starts the background listener
Future<void> _startWakeWordListening() async {
    // 1. If it's already listening (or preparing to listen), ignore!
    if (_isWakeWordListening) return; 

    _isWakeWordListening = true; 

    try {
      // 1.5 seconds to fully release the STT microphone.
      await Future.delayed(const Duration(milliseconds: 1500));
      
      await _porcupineManager?.start();
      debugPrint("Listening for wake word quietly in the background...");
      
    } catch (e) {
      debugPrint("Failed to start wake word: $e");
      // Only unlock if it actually crashed
      _isWakeWordListening = false; 
    }
  }
  // 2. The app speaks back to the user
  Future<void> speak(String text) async {
    await _flutterTts.speak(text);
  }

  Future<void> triggerManualListen() async {
    debugPrint("Manual screen tap detected. Handing over microphone...");
    
    // Force Porcupine to let go of the microphone
    if (_isWakeWordListening) {
      _isWakeWordListening = false; 
      await _porcupineManager?.stop();  
      // Give the phone's hardware a tiny fraction of a second to release the mic lock
      await Future.delayed(const Duration(milliseconds: 500)); 
    }
    await startListening(); 
  }

  // 3. Start listening to the user's microphone
  Future<void> startListening() async {
    if (!_isListening) {
      bool available = await _speechToText.initialize();
      if (available) {
        _isListening = true;
        // Play an audio cue so the user knows they can talk
        await speak("Listening..."); 
        
        _speechToText.listen(
          onResult: (result) {
            // Wait until they finish their sentence
            if (result.finalResult) {
              _isListening = false;
              _processCommand(result.recognizedWords.toLowerCase());
            }
          },
          //Tell the engine to wait up to 5 seconds of silence before timing out
          pauseFor: const Duration(seconds: 5),
          // Set a maximum listening time of 10 seconds per command
          listenFor: const Duration(seconds: 10), 
        );
      } else {
        await speak("Microphone permission denied.");
      }
    }
  }

  // 4. Stop listening manually (optional)
  Future<void> stopListening() async {
    await _speechToText.stop();
    _isListening = false;
  }

  // 5.Match the spoken words to the features!
  void _processCommand(String text) {
    debugPrint("User said: $text");
    
    if (text.contains("call") && text.contains("caretaker") || text.contains("caregiver") || text.contains("doctor")) {
      speak("Calling your caregiver.");
      onCommandRecognized("call_caregiver");
      
    } else if (text.contains("currency") || text.contains("money")) {
      speak("Activating currency recognition.");
      onCommandRecognized("currency");
      
    } else if (text.contains("navigate") || text.contains("location") || text.contains("directions")) {
      speak("Where would you like to go?");
      onCommandRecognized("navigate");
      
    } else if (text.contains("weather")) {
      speak("Checking the weather.");
      onCommandRecognized("weather");
      
    } else if (text.contains("message") || text.contains("voice note")) {
      speak("Ready to send a message to your caregiver.");
      onCommandRecognized("message_caregiver");
      
    } else if (text.contains("sos") || text.contains("help") || text.contains("emergency")) {
      speak("Activating S O S. Please wait.");
      onCommandRecognized("sos");
      
    } else if (text.contains("obstacle") || text.contains("detect")) {
      speak("Activating obstacle detection.");
      onCommandRecognized("obstacle");
      
    }
    else if (text.contains("read") || text.contains("text") || text.contains("document")) {
      speak("Opening document scanner.");
      onCommandRecognized("read_text");
      
    } else if (text.contains("where am i") || text.contains("current location")) {
      speak("Fetching your current location.");
      onCommandRecognized("current_location");
      
    } else if (text.contains("time")) {
      speak("Checking time.");
      onCommandRecognized("time");
      
    } else if (text.contains("battery")) {
      speak("Checking battery.");
      onCommandRecognized("battery");
      
    } else if (text.contains("status")) {
      speak("Checking system status.");
      onCommandRecognized("system_status");
    } else {
      speak("I didn't catch that. Please try again.");
    }
  }
}