import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_container.dart';
import 'package:user_mobile/features/caregiver_mode/screens/map_tracking_screen.dart';
import 'package:user_mobile/features/caregiver_mode/screens/voice_chat_list_screen.dart';
import 'package:user_mobile/features/caregiver_mode/screens/emergency_alerts_screen.dart';

class CaregiverDashboardScreen extends StatefulWidget {
  const CaregiverDashboardScreen({super.key});

  @override
  State<CaregiverDashboardScreen> createState() =>
      _CaregiverDashboardScreenState();
}

class _CaregiverDashboardScreenState extends State<CaregiverDashboardScreen> {
  // Dummy data to simulate multiple connected users
  final List<Map<String, dynamic>> _connectedUsers = [
    {"name": "Kamal", "status": "Safe", "battery": "85%", "isOnline": true},
    {"name": "Nimali", "status": "Moving", "battery": "42%", "isOnline": true},
  ];

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
                            "Savindu!",
                            style: GoogleFonts.poppins(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white54, width: 2),
                        ),
                        child: const CircleAvatar(
                          radius: 24,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person, color: Colors.white),
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

                // Horizontal ListView for Multiple Users
                SizedBox(
                  height: 110, // Fixed height for the horizontal cards
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    itemCount: _connectedUsers.length,
                    itemBuilder: (context, index) {
                      final user = _connectedUsers[index];
                      return Padding(
                        padding: const EdgeInsets.only(right: 15.0),
                        child: _buildUserStatusCard(
                          name: user["name"],
                          status: user["status"],
                          battery: user["battery"],
                          isOnline: user["isOnline"],
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
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MapTrackingScreen(),
                            ),
                          );
                          debugPrint("Open Map");
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildFullWidthActionCard(
                        title: "Live Voice Messages",
                        subtitle: "Send and receive audio instantly",
                        icon: Icons.mic_none_outlined,
                        color: Colors.orangeAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const VoiceChatListScreen(),
                            ),
                          );
                          debugPrint("Open Voice Chat");
                        },
                      ),
                      const SizedBox(height: 15),
                      _buildFullWidthActionCard(
                        title: "Emergency Alerts",
                        subtitle: "View SOS history and incident logs",
                        icon: Icons.warning_amber_rounded,
                        color: Colors.redAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const EmergencyAlertsScreen(),
                            ),
                          );
                          debugPrint("Open Alerts");
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

  // New Helper: The User Status Card
  Widget _buildUserStatusCard({
    required String name,
    required String status,
    required String battery,
    required bool isOnline,
  }) {
    // Dynamic color based on status
    Color statusColor = status == "Safe"
        ? Colors.greenAccent
        : Colors.orangeAccent;

    return SizedBox(
      width: 260, // Width of each individual card
      child: GlassContainer(
        padding: 15,
        child: Row(
          children: [
            // Profile Pic with Online Indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  // We use the first letter of the name as a placeholder for the image
                  child: Text(
                    name[0],
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
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

            // Text Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    "Status: $status",
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                  Text(
                    "Battery: $battery",
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper Widget for the sleek Glass Cards
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
            // Icon Block
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 20),

            // Text Block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Arrow indicator to show it's clickable
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.white.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
