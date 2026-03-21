import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:user_mobile/core/services/voice_api_service.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:firebase_auth/firebase_auth.dart';


class BlindVoiceRecordScreen extends StatefulWidget {
  final String targetChatId;
  final String targetCaregiverId;
  final String caregiverName;

  const BlindVoiceRecordScreen({
    super.key,
    required this.targetChatId,
    required this.targetCaregiverId,
    required this.caregiverName,
  });

  @override
  State<BlindVoiceRecordScreen> createState() => _BlindVoiceRecordScreenState();
}

class _BlindVoiceRecordScreenState extends State<BlindVoiceRecordScreen> {
  bool _isRecording = false;
  bool _isPreparing = true; 
  
  final AudioRecorder _audioRecorder = AudioRecorder();
  final VoiceApiService _voiceApi = VoiceApiService();
  final FlutterTts _tts = FlutterTts();
  String? _recordedFilePath;

  @override
  void initState() {
    super.initState();
    _initAndStart();
  }

  Future<void> _initAndStart() async {
    await _tts.setLanguage("en-US");
    await _tts.awaitSpeakCompletion(true); 
    await _tts.speak("Recording to ${widget.caregiverName}. Tap anywhere when finished.");

    if (mounted) {
      setState(() => _isPreparing = false);
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        HapticFeedback.heavyImpact(); 
        
        final directory = await getTemporaryDirectory();
        _recordedFilePath = '${directory.path}/blind_voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(
          const RecordConfig(encoder: AudioEncoder.aacLc), 
          path: _recordedFilePath!
        );
        
        setState(() => _isRecording = true);
      }
    } catch (e) {
      debugPrint("Error starting record: $e");
    }
  }

  Future<void> _stopRecordingAndSend() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      
      HapticFeedback.mediumImpact();
      await Future.delayed(const Duration(milliseconds: 150));
      HapticFeedback.mediumImpact();

      if (path != null) {
        await _tts.speak("Sending message. Please wait.");

        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "unknown_sender";

        final success = await _voiceApi.sendVoiceMessage(
          audioFilePath: path,
          senderId: currentUserId, 
          receiverId: widget.targetCaregiverId,
          chatId: widget.targetChatId,
        );

        if (success && mounted) {
           await _tts.speak("Message sent successfully.");
           Navigator.pop(context); 
        } else if (mounted) {
           await _tts.speak("Failed to send message. Please check your connection and try again.");
           Navigator.pop(context); 
        }
      }
    } catch (e) {
      debugPrint("Error stopping record: $e");
      setState(() => _isRecording = false);
    }
  }

  @override
  void dispose() {
    _audioRecorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isRecording ? Colors.red.shade800 : AppColors.primaryDark,
      body: SafeArea(
        child: GestureDetector(
          // Only stop the recording if they tap WHILE it is actually recording!
          onTap: () {
            if (_isRecording) {
              _stopRecordingAndSend();
            }
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent, 
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  
                  _isPreparing ? Icons.speaker_phone : (_isRecording ? Icons.mic : Icons.check_circle),
                  size: 100,
                  color: Colors.white,
                ),
                const SizedBox(height: 30),
                Text(
                  
                  _isPreparing 
                      ? "Listen to instructions..." 
                      : (_isRecording ? "Recording...\nTap anywhere to send" : "Processing..."),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
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