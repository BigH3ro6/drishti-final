import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_container.dart';
import 'package:user_mobile/features/caregiver_mode/screens/voice_messages_screen.dart';
import 'package:user_mobile/core/services/pairing_api_service.dart'; 

class VoiceChatListScreen extends StatefulWidget {
  const VoiceChatListScreen({super.key});

  @override
  State<VoiceChatListScreen> createState() => _VoiceChatListScreenState();
}

class _VoiceChatListScreenState extends State<VoiceChatListScreen> {
  final PairingApiService _pairingApi = PairingApiService();
  List<Map<String, dynamic>> _chatList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchRealChats();
  }

  Future<void> _fetchRealChats() async {
    // 1. Fetch the paired Blind Users from backend!
    final realList = await _pairingApi.getLinkedUsers();
    
    if (mounted) {
      setState(() {
        _chatList = realList;
        _isLoading = false;
      });
    }
  }

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
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : _chatList.isEmpty 
              ? Center(child: Text("No paired users yet.", style: GoogleFonts.poppins(color: Colors.white)))
              : ListView.builder(
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
    final name = chat["name"] ?? "Unknown";
    final chatId = chat["chatId"] ?? "";
    final targetId = chat["id"] ?? "";

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GestureDetector(
        onTap: () {
          // Navigate to the specific chat room and pass the  IDs!
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VoiceMessagesScreen(
                userName: name, 
                isOnline: true, 
                chatId: chatId,
                targetUserId: targetId, // <-- Pass the Blind User's ID
              ),
            ),
          );
        },
        child: GlassContainer(
          padding: 15,
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    child: Text(name[0], style: GoogleFonts.poppins(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text("Tap to open chat", style: GoogleFonts.poppins(fontSize: 13, color: Colors.white70)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}