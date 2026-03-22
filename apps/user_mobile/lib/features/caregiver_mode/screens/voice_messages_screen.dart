import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:user_mobile/core/services/voice_api_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VoiceMessagesScreen extends StatefulWidget {
  final String userName;
  final bool isOnline;
  final String chatId;
  final String targetUserId;

  const VoiceMessagesScreen({super.key, required this.userName, required this.isOnline,required this.chatId,required this.targetUserId,});

  @override
  State<VoiceMessagesScreen> createState() => _VoiceMessagesScreenState();
}

class _VoiceMessagesScreenState extends State<VoiceMessagesScreen> with SingleTickerProviderStateMixin{
  bool _isRecording = false;
  bool _isCancelled = false;
  // --- HARDWARE VARIABLES ---
  final AudioRecorder _audioRecorder = AudioRecorder();
  final VoiceApiService _voiceApi = VoiceApiService();
  String? _recordedFilePath;

  double _dragOffset = 0.0;
  late AnimationController _springController;
  late Animation<double> _springAnimation;

  List<Map<String, dynamic>> _realMessages = [];
  bool _isLoadingMessages = true;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  String? _currentlyPlayingId;


@override
  void initState() {
    super.initState();
    _springController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _springController.addListener(() => setState(() => _dragOffset = _springAnimation.value));

    _fetchMessages();

    // --- NEW: Audio Player Listeners ---
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _totalDuration = duration);
    });
    
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) setState(() => _currentPosition = position);
    });

    _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _currentlyPlayingId = null;
          _currentPosition = Duration.zero;
        });
      }
    });
  }

Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        // Create a unique file name
        _recordedFilePath = '${directory.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
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

      if (path != null) {
        // Show a quick loading snackbar
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sending voice message...")));

        // --- GET FIREBASE UID ---
        final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? "unknown_sender";
        final success = await _voiceApi.sendVoiceMessage(
          audioFilePath: path,
          senderId: currentUserId, 
          receiverId: widget.targetUserId,
          chatId: widget.chatId,
        );

        if (success && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sent successfully!")));
          _fetchMessages();        
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to send message.")));
        }
      }
    } catch (e) {
      debugPrint("Error stopping record: $e");
      setState(() => _isRecording = false);
    }
  }

 void _resetButtonPosition() {
    // Smoothly animate the button from its current drag position back to 0.0
    _springAnimation = Tween<double>(begin: _dragOffset, end: 0.0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.easeOutBack)
    );
    _springController.forward(from: 0.0);
  }

  Future<void> _cancelRecording() async {
    // 1. INSTANTLY shut down the UI to prevent spam
    setState(() {
      _isRecording = false;
    });
    _resetButtonPosition(); // Spring it back immediately

    try {
      // 2. Now stop the hardware safely in the background
      final path = await _audioRecorder.stop();

      if (path != null) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
      
      if (mounted) {
        // 3. Clear any existing snackbars so they don't queue up!
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Recording cancelled 🗑️"), duration: Duration(seconds: 1)),
        );
      }
    } catch (e) {
      debugPrint("Error canceling record: $e");
    }
  }
 

  Future<void> _fetchMessages() async {
    final messages = await _voiceApi.getVoiceMessages(widget.chatId); 
    if (mounted) {
      setState(() {
        _realMessages = messages;
        _isLoadingMessages = false;
      });
    }
  }

Future<void> _playPauseAudio(String messageId, String? audioUrl) async {
    if (audioUrl == null || audioUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error: Audio link is missing from database!"))
      );
      return;
    }

    try {
      if (_currentlyPlayingId == messageId) {
        // Pause if it's the same bubble
        await _audioPlayer.pause();
        setState(() => _currentlyPlayingId = null);
      } else {
        await _audioPlayer.stop();
        setState(() => _currentlyPlayingId = messageId);
        
        // Load and play the new URL
        await _audioPlayer.play(UrlSource(audioUrl));
      }
    } catch (e) {
      debugPrint("Error playing audio: $e");
      setState(() => _currentlyPlayingId = null); // Reset UI on failure
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not play this audio format."))
      );
    }
  }
  // 1. Converts "Fri, 20 Mar 2026 14:50:21 GMT" to "2:50 PM"
 String _formatTime(String? timestamp) {
    if (timestamp == null) return "Unknown";
    try {
      final date = HttpDate.parse(timestamp); 
      
      final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
      final ampm = date.hour >= 12 ? "PM" : "AM";
      final minute = date.minute.toString().padLeft(2, '0');
      
      return "$hour:$minute $ampm";
    } catch (e) {
      return "Just now";
    }
  }

  // 2. Converts Duration to "0:12"
  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  // 3. Delete Message UI Function
 void _confirmDeleteMessage(String messageId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Delete Message", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        content: Text("Are you sure you want to delete this voice note?", style: GoogleFonts.poppins()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); 
              setState(() {
                _realMessages.removeWhere((msg) => msg["id"] == messageId);
              });
              
              final success = await _voiceApi.deleteVoiceMessage(messageId);
              
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Message deleted permanently 🗑️"))
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Network error: Could not delete."))
                  );
                  _fetchMessages(); 
                }
              }
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  @override
  void dispose() {
    _springController.dispose(); 
    _audioRecorder.dispose();
    _audioPlayer.dispose(); 
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.primaryDark, 
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white.withOpacity(0.2),
              child: Text(widget.userName[0], style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(widget.isOnline ? "Online" : "Offline", style: GoogleFonts.poppins(fontSize: 12, color: widget.isOnline ? Colors.greenAccent : Colors.white54)),
              ],
            ),
          ],
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          bottom: false, 
          child: Column(
            children: [
              const SizedBox(height: 10), 
              
              // The White Chat Sheet
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F6FA), 
                    borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                  ),
                  child: Column(
                    children: [
                      // Scrollable Chat Area
                      Expanded(
                        child: _isLoadingMessages 
                        ? const Center(child: CircularProgressIndicator())
                        : ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: _realMessages.length,
                          itemBuilder: (context, index) {
                            final msg = _realMessages[index];
                            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                            final isMe = msg["sender_id"] == currentUserId;
                            final isPlaying = _currentlyPlayingId == msg["id"];
                            
                            // Calculate the moving progress bar (0.0 to 1.0)
                            double progress = 0.0;
                            String durationText = "Audio"; // Fallback text

                            if (isPlaying && _totalDuration.inMilliseconds > 0) {
                              progress = _currentPosition.inMilliseconds / _totalDuration.inMilliseconds;
                              // Shows real-time progress like "0:05 / 0:12"
                              durationText = "${_formatDuration(_currentPosition)} / ${_formatDuration(_totalDuration)}";
                            }

                            return _buildVoiceBubble(
                              isMe: isMe,
                              duration: durationText, 
                              time: _formatTime(msg["timestamp"]), 
                              isPlaying: isPlaying,
                              progress: progress, // Pass the moving progress factor
                              onTapPlay: () => _playPauseAudio(msg["id"], msg["content_url"]),
                              onLongPress: () => _confirmDeleteMessage(msg["id"]), // Add delete trigger
                            );
                          },
                        ),
                      ),
                      
                      // Bottom Recording Bar
                      _buildBottomRecordingBar(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
Widget _buildVoiceBubble({
    required bool isMe, 
    required String duration, 
    required String time, 
    required bool isPlaying,
    required double progress,
    required VoidCallback onTapPlay,
    required VoidCallback onLongPress,
  }) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onLongPress: onLongPress, // Triggers the delete dialog!
        child: Container(
          margin: const EdgeInsets.only(bottom: 20),
          width: MediaQuery.of(context).size.width * 0.75,
          child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: isMe ? AppColors.mainGradient : null,
                  color: isMe ? null : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : 5),
                    bottomRight: Radius.circular(isMe ? 5 : 20),
                  ),
                  boxShadow: isMe ? [] : [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: isMe ? Colors.white.withOpacity(0.2) : AppColors.primaryLight.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: isMe ? Colors.white : AppColors.primaryDark),
                        onPressed: onTapPlay,
                      ),
                    ),
                    const SizedBox(width: 10),
                    
                    Expanded(
                      child: Container(
                        height: 4,
                        decoration: BoxDecoration(
                          color: isMe ? Colors.white.withOpacity(0.3) : Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          // Use the real-time progress factor here!
                          widthFactor: isPlaying ? progress : 0.0, 
                          child: Container(
                            decoration: BoxDecoration(
                              color: isMe ? Colors.white : AppColors.primaryLight,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    
                    Text(
                      duration, // Shows "Audio" or "0:02 / 0:14"
                      style: GoogleFonts.poppins(color: isMe ? Colors.white : Colors.black87, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Text(time, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 10)),
            ],
          ),
        ),
      ),
    );
  }
Widget _buildBottomRecordingBar() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 1. THE HIDDEN TRASH CAN
          AnimatedOpacity(
            opacity: _isRecording ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 30),
                child: Icon(Icons.delete_sweep, color: Colors.grey[400], size: 28),
              ),
            ),
          ),

          // 2. THE SMOOTH DRAGGABLE BUTTON
          Transform.translate(
            offset: Offset(_dragOffset, 0),
            child: GestureDetector(
              // Trigger recording instantly on press
              onLongPressStart: (_) {
                _springController.stop(); // Stop any current animations
                setState(() => _dragOffset = 0.0);
                _isCancelled = false;
                _startRecording();
              },
              
              // Track the slide flawlessly
              onLongPressMoveUpdate: (details) {
                if (!_isRecording || _isCancelled) return;
                setState(() {
                  // offsetFromOrigin is the magic variable! It calculates distance perfectly.
                  _dragOffset = details.offsetFromOrigin.dx.clamp(-200.0, 0.0);
                  
                  // If they drag far enough to the left, cancel it!
                  if (_dragOffset <= -120.0) {
                    _isCancelled = true;
                    _cancelRecording();
                  }
                });
              },
              
              // Send the message when released (if not cancelled)
              onLongPressEnd: (_) {
                if (_isRecording && !_isCancelled) {
                  _stopRecordingAndSend();
                  _resetButtonPosition();
                }else if (_isCancelled) {
                  _resetButtonPosition();
                }
              },
              
              // Lock the height so it doesn't jitter when the text changes
              child: SizedBox(
                height: 56, 
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: _isRecording ? Colors.redAccent : AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: _isRecording ? [BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 15)] : [],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_isRecording ? Icons.mic : Icons.mic_none, color: Colors.white, size: 28),
                      const SizedBox(width: 10),
                      Text(
                        _isRecording ? "◁ Slide to cancel" : "Hold to Record",
                        style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}