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

  final Function(String command, String rawText) onCommandRecognized;
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
    await _flutterTts.awaitSpeakCompletion(true);
    
    await _speechToText.initialize(
      onError: (error) {
        debugPrint('Speech error: ${error.errorMsg}');
        _isListening = false;
        onListeningStateChanged?.call(false);
        
       if (error.errorMsg == 'error_speech_timeout' || error.errorMsg == 'error_no_match') {
          speak("I missed that. Please tap the screen and try again.");
        }
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
    if (_isWakeWordListening) return; 

    _isWakeWordListening = true; 

    try {
      // 1.5 seconds to fully release the STT microphone.
      await Future.delayed(const Duration(milliseconds: 1500));
      
      await _porcupineManager?.start();
      debugPrint("Listening for wake word quietly in the background...");
      
    } catch (e) {
      debugPrint("Failed to start wake word: $e");
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
        await Future.delayed(const Duration(milliseconds: 500));
        
        _speechToText.listen(
          onResult: (result) {
            if (result.finalResult) {
              _isListening = false;
              _processCommand(result.recognizedWords.toLowerCase());
            }
          },
          //Tell the engine to wait up to 5 seconds of silence before timing out
          pauseFor: const Duration(seconds: 3),
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
  Future<void> _processCommand(String text) async {
    debugPrint("User said: $text");
    
    if (text.contains("call") && (text.contains("caretaker") || text.contains("caregiver") || text.contains("doctor"))) {
      await speak("Calling your caregiver."); // --- ADDED AWAIT ---
      onCommandRecognized("call_caregiver",text);
      
    } else if (text.contains("currency") || text.contains("money")) {
      await speak("Activating currency recognition.");
      onCommandRecognized("currency",text);
      
    } else if (text.contains("navigate") || text.contains("location") || text.contains("directions")) {
      await speak("Where would you like to go?");
      onCommandRecognized("navigate",text);
      
    } else if (text.contains("weather")) {
      await speak("Checking the weather.");
      onCommandRecognized("weather",text);
      
    } else if (text.contains("play") && text.contains("message")) {
      await speak("Checking for messages.");
      onCommandRecognized("play_messages", text);
      
    } else if (text.contains("message") || text.contains("voice note") || text.contains("send")) {
      await speak("Ready to send a voice to your caregiver."); // --- ADDED AWAIT ---
      onCommandRecognized("message_caregiver",text);
      
    } else if (text.contains("sos") || text.contains("help") || text.contains("emergency")) {
      await speak("Activating S O S. Please wait.");
      onCommandRecognized("sos",text);
      
    } else if (text.contains("obstacle") || text.contains("detect")) {
      await speak("Activating obstacle detection.");
      onCommandRecognized("obstacle",text);
      
    } else if (text.contains("read") || text.contains("text") || text.contains("document")) {
      await speak("Opening document scanner.");
      onCommandRecognized("read_text",text);
      
    } else if (text.contains("where am i") || text.contains("current location")) {
      await speak("Fetching your current location.");
      onCommandRecognized("current_location",text);
      
    } else if (text.contains("time")) {
      await speak("Checking time.");
      onCommandRecognized("time",text);
      
    } else if (text.contains("battery")) {
      await speak("Checking battery.");
      onCommandRecognized("battery",text);
      
    } else if (text.contains("status")) {
      await speak("Checking system status.");
      onCommandRecognized("system_status",text);

    } else if (text.contains("pair") || text.contains("caregiver") || text.contains("link")) {
      await speak("Pairing mode activated.");
      onCommandRecognized("pair_caregiver",text);
      
    } else {
      onCommandRecognized("raw_text", text); 
      await speak("I heard: $text. If you want to call your caregiver, say 'Call Caregiver'. For messages, say 'Play Messages' or 'Send Message'.");
    }
  }
}