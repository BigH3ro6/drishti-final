import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:user_mobile/core/services/voice_api_service.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BlindAudioPlayerScreen extends StatefulWidget {
  final String chatId;
  final String caregiverName;

  const BlindAudioPlayerScreen({
    super.key,
    required this.chatId,
    required this.caregiverName,
  });

  @override
  State<BlindAudioPlayerScreen> createState() => _BlindAudioPlayerScreenState();
}

class _BlindAudioPlayerScreenState extends State<BlindAudioPlayerScreen> {
  final VoiceApiService _voiceApi = VoiceApiService();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterTts _tts = FlutterTts();

  bool _isLoading = true;
  bool _isPlaying = false;
  List<Map<String, dynamic>> _caregiverMessages = [];

  @override
  void initState() {
    super.initState();
    _initTts();
    _fetchAndPlayLatestMessage();

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() => _isPlaying = false);
        _tts.speak("Message finished. Swipe down to go back.");
      }
    });
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.awaitSpeakCompletion(true); 
  }

  Future<void> _fetchAndPlayLatestMessage() async {
    try {
      final allMessages = await _voiceApi.getVoiceMessages(widget.chatId);
      
      if (mounted) {
        // ---  GET FIREBASE ID ---
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "unknown";

        // --- FILTER USING THE ID ---
        _caregiverMessages = allMessages.where((msg) => msg["sender_id"] != currentUserId).toList();
        
        setState(() => _isLoading = false);

        if (_caregiverMessages.isEmpty) {
          await _tts.speak("You have no new messages from ${widget.caregiverName}. Swipe down to go back.");
          return;
        }

        // Play the most recent message (the last one in the list)
        final latestMessage = _caregiverMessages.last;
        final audioUrl = latestMessage["content_url"]; 

        if (audioUrl != null && audioUrl.isNotEmpty) {
          await _tts.speak("Playing latest message from ${widget.caregiverName}.");
          
          // Start the audio stream!
          await _audioPlayer.play(UrlSource(audioUrl));
          setState(() => _isPlaying = true);
          HapticFeedback.mediumImpact();
        } else {
          await _tts.speak("Sorry, the audio file is corrupted.");
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        _tts.speak("Failed to load messages. Please check your internet connection.");
      }
    }
  }

  void _togglePlayPause() async {
    if (_caregiverMessages.isEmpty) return;

    HapticFeedback.lightImpact();
    if (_isPlaying) {
      await _audioPlayer.pause();
      setState(() => _isPlaying = false);
      _tts.speak("Paused."); 
    } else {
      await _audioPlayer.resume();
      setState(() => _isPlaying = true);
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _isPlaying ? Colors.teal.shade800 : AppColors.primaryDark,
      body: SafeArea(
        child: GestureDetector(
          // 1. Tapping anywhere pauses/plays
          onTap: _togglePlayPause,
          
          // 2. Swiping down closes the screen
          onVerticalDragEnd: (details) {
            if (details.primaryVelocity! > 0) {
              Navigator.pop(context);
            }
          },
          child: Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.transparent, 
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.white)
                else ...[
                  Icon(
                    _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                    size: 120,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 40),
                  Text(
                    _isPlaying ? "Playing..." : "Paused\nTap to resume",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Swipe down to close",
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
                  ),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}