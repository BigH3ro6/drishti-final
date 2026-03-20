import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';

class VoiceMessagesScreen extends StatefulWidget {
  final String userName;
  final bool isOnline;

  const VoiceMessagesScreen({super.key, required this.userName, required this.isOnline});

  @override
  State<VoiceMessagesScreen> createState() => _VoiceMessagesScreenState();
}

class _VoiceMessagesScreenState extends State<VoiceMessagesScreen> {
  bool _isRecording = false;

  final List<Map<String, dynamic>> _messages = [
    {"isMe": true, "duration": "0:12", "time": "10:30 AM", "isPlaying": false},
    {"isMe": false, "duration": "0:08", "time": "10:32 AM", "isPlaying": true},
    {"isMe": true, "duration": "0:24", "time": "10:45 AM", "isPlaying": false},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors.primaryDark, // Fallback color
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
          bottom: false, // Let the white container flow to the very bottom
          child: Column(
            children: [
              const SizedBox(height: 10), // Small gap below app bar
              
              // The White Chat Sheet
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F6FA), // Very light cool grey/white
                    borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                  ),
                  child: Column(
                    children: [
                      // Scrollable Chat Area
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(24),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            return _buildVoiceBubble(
                              isMe: msg["isMe"],
                              duration: msg["duration"],
                              time: msg["time"],
                              isPlaying: msg["isPlaying"],
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

  Widget _buildVoiceBubble({required bool isMe, required String duration, required String time, required bool isPlaying}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        width: MediaQuery.of(context).size.width * 0.7,
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // Caregiver gets a solid purple gradient, User gets a clean white bubble with a shadow
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
                  // Play/Pause Button
                  Container(
                    decoration: BoxDecoration(
                      color: isMe ? Colors.white.withOpacity(0.2) : AppColors.primaryLight.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow, color: isMe ? Colors.white : AppColors.primaryDark),
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(width: 10),
                  
                  // Waveform/Slider
                  Expanded(
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: isMe ? Colors.white.withOpacity(0.3) : Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: isPlaying ? 0.4 : 0.0,
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
                  
                  // Duration
                  Text(
                    duration,
                    style: GoogleFonts.poppins(color: isMe ? Colors.white : Colors.black87, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Text(time, style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomRecordingBar() {
    return Container(
      padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 40), // Extra bottom padding for safe area
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isRecording = true),
        onTapUp: (_) => setState(() => _isRecording = false),
        onTapCancel: () => setState(() => _isRecording = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: _isRecording ? 18 : 15),
          decoration: BoxDecoration(
            color: _isRecording ? Colors.redAccent : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(30),
            boxShadow: _isRecording ? [BoxShadow(color: Colors.redAccent.withOpacity(0.4), blurRadius: 15)] : [],
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_isRecording ? Icons.mic : Icons.mic_none, color: Colors.white, size: 28),
                const SizedBox(width: 10),
                Text(
                  _isRecording ? "Recording..." : "Hold to Record",
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}