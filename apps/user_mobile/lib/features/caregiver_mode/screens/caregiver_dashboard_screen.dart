import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_container.dart';
import 'package:user_mobile/features/caregiver_mode/screens/map_tracking_screen.dart';
import 'package:user_mobile/features/caregiver_mode/screens/voice_chat_list_screen.dart';
import 'package:user_mobile/features/caregiver_mode/screens/emergency_alerts_screen.dart';
import 'package:user_mobile/features/caregiver_mode/screens/caregiver_profile_screen.dart'; // <-- Added for navigation!

// --- API IMPORTS ---
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:user_mobile/core/services/pairing_api_service.dart';
import 'package:user_mobile/core/services/profile_api_service.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  final PairingApiService _pairingApi = PairingApiService();
  final ProfileApiService _profileApi = ProfileApiService();
  
  List<Map<String, dynamic>> _connectedUsers = [];
  String _caregiverFirstName = "Loading...";
  String? _profileImageUrl; // <-- Added to hold the image URL
  bool _isLoadingUsers = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    // 1. Get Caregiver's own name and profile picture
    final profileData = await _profileApi.getUserProfile();
    if (profileData != null && mounted) {
      setState(() {
        String fullName = profileData['name'] ?? "Caregiver";
        _caregiverFirstName = fullName.split(" ")[0]; 
        _profileImageUrl = profileData['profile_image_url']; // <-- Grab the image!
      });
    }

    // 2. Get the actual linked Visually Impaired users from Python
    final users = await _pairingApi.getLinkedUsers();
    if (mounted) {
      setState(() {
        _connectedUsers = users;
        _isLoadingUsers = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Area (Profile & Greeting)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Good Morning,",
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.white70,
                            ),
                          ),
                          Text(
                            _caregiverFirstName,
                            style: GoogleFonts.poppins(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      // --- THE CLICKABLE AVATAR ---
                      GestureDetector(
                        onTap: () {
                          // Navigate to the profile screen when tapped!
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const CaregiverProfileScreen()),
                          );
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white54, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white24,
                            // Show the Cloudinary image if it exists, otherwise show the first letter
                            backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
                            child: _profileImageUrl == null 
                              ? Text(
                                  _caregiverFirstName == "Loading..." ? "?" : _caregiverFirstName[0].toUpperCase(),
                                  style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
                                )
                              : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 2. Overview (Horizontally Scrolling User Cards)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    "Overview",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // Horizontal ListView for Multiple Users (Live Stream)
                SizedBox(
                  height: 110,
                  child: _isLoadingUsers 
                    ? const Center(child: CircularProgressIndicator(color: Colors.white))
                    : _connectedUsers.isEmpty 
                      ? Center(child: Text("No users linked yet.", style: GoogleFonts.poppins(color: Colors.white70)))
                      : ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          itemCount: _connectedUsers.length,
                          itemBuilder: (context, index) {
                            final user = _connectedUsers[index];
                            final userId = user["id"]; 
                            final fallbackName = user["name"] ?? "Unknown";

                            return Padding(
                              padding: const EdgeInsets.only(right: 15.0),
                              child: StreamBuilder<DocumentSnapshot>(
                                stream: FirebaseFirestore.instance.collection('users').doc(userId).snapshots(),
                                builder: (context, snapshot) {
                                  
                                  String currentStatus = "Fetching...";
                                  String currentBattery = "--%";
                                  bool isOnline = false;
                                  String? imageUrl;

                                  if (snapshot.hasData && snapshot.data!.exists) {
                                    final data = snapshot.data!.data() as Map<String, dynamic>?;
                                    
                                    if (data != null) {
                                      currentStatus = data['status'] ?? "Safe";
                                      if (data['battery_level'] != null) {
                                        currentBattery = "${data['battery_level']}%";
                                      } else {
                                        currentBattery = "Unknown";
                                      }
                                      isOnline = data['is_online'] ?? true;
                                      imageUrl = data['profile_image_url'];
                                    }
                                  }
                                  imageUrl ??= user['profile_image_url'];

                                  return _buildUserStatusCard(
                                    name: fallbackName,
                                    status: currentStatus, 
                                    battery: currentBattery, 
                                    isOnline: isOnline, 
                                    profileImageUrl: imageUrl,
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),

                const SizedBox(height: 30),

                // 3. Action Grid
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    "Quick Actions",
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      _buildFullWidthActionCard(
                        title: "Live Location",
                        subtitle: "Track real-time movements on the map",
                        icon: Icons.map_outlined,
                        color: Colors.blueAccent,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const MapTrackingScreen()));
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildFullWidthActionCard(
                        title: "Live Voice Messages",
                        subtitle: "Send and receive audio instantly",
                        icon: Icons.mic_none_outlined,
                        color: Colors.orangeAccent,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const VoiceChatListScreen()));
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildFullWidthActionCard(
                        title: "Emergency Alerts",
                        subtitle: "View SOS history and incident logs",
                        icon: Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const EmergencyAlertsScreen()));
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper: The User Status Card
  Widget _buildUserStatusCard({
    required String name,
    required String status,
    required String battery,
    required bool isOnline,
    String? profileImageUrl,
  }) {
    Color statusColor = status == "Safe" ? Colors.greenAccent : Colors.orangeAccent;

    return SizedBox(
      width: 260, 
      child: GlassContainer(
        padding: 15,
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  // 1. Show the image if it exists!
                  backgroundImage: profileImageUrl != null ? NetworkImage(profileImageUrl!) : null,
                  // 2. Only show the text letter if there is NO image
                  child: profileImageUrl == null 
                      ? Text(
                          name.isNotEmpty ? name[0].toUpperCase() : "?",
                          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: isOnline ? Colors.greenAccent : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primaryDark, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text("Status: $status", style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600, color: statusColor)),
                  Text("Battery: $battery", style: GoogleFonts.poppins(fontSize: 11, color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget for Action Cards
  Widget _buildFullWidthActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: 20,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.white.withOpacity(0.3), size: 16),
          ],
        ),
      ),
    );
  }
}