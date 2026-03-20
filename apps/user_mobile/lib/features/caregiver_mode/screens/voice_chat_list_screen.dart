import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_container.dart';
import 'package:user_mobile/features/caregiver_mode/screens/voice_messages_screen.dart';

class VoiceChatListScreen extends StatelessWidget {
  const VoiceChatListScreen({super.key});

  // Dummy list of users with their last message status
  final List<Map<String, dynamic>> _chatList = const [
    {
      "name": "Kamal",
      "lastMessage": "▶ Voice Message • 0:12",
      "time": "10:30 AM",
      "isOnline": true,
      "unread": 2,
    },
    {
      "name": "Geetha",
      "lastMessage": "▶ Voice Message • 0:08",
      "time": "Yesterday",
      "isOnline": true,
      "unread": 0,
    },
    {
      "name": "Rohan",
      "lastMessage": "▶ Voice Message • 0:24",
      "time": "Monday",
      "isOnline": false,
      "unread": 0,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Messages",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: _chatList.length,
            itemBuilder: (context, index) {
              final chat = _chatList[index];
              return _buildChatTile(context, chat);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, Map<String, dynamic> chat) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        onTap: () {
          // Navigate to the specific chat room!
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VoiceMessagesScreen(userName: chat["name"], isOnline: chat["isOnline"]),
            ),
          );
        },
        child: GlassContainer(
          padding: 15,
          child: Row(
            children: [
              // Avatar with online indicator
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(chat["name"][0], style: GoogleFonts.poppins(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  if (chat["isOnline"])
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, border: Border.all(color: AppColors.primaryDark, width: 2)),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 15),
              
              // Name and Last Message
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      chat["name"],
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      chat["lastMessage"],
                      style: GoogleFonts.poppins(fontSize: 13, color: chat["unread"] > 0 ? Colors.white : Colors.white70, fontWeight: chat["unread"] > 0 ? FontWeight.bold : FontWeight.normal),
                    ),
                  ],
                ),
              ),
              
              // Time and Unread Badge
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(chat["time"], style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
                  const SizedBox(height: 8),
                  if (chat["unread"] > 0)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                      child: Text(chat["unread"].toString(), style: GoogleFonts.poppins(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}