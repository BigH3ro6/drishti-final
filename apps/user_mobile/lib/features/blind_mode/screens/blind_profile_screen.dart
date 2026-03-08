import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/features/blind_mode/screens/blind_dashboard_screen.dart';
import 'package:user_mobile/features/blind_mode/screens/blind_personal_info_screen.dart';
import 'package:user_mobile/features/blind_mode/screens/blind_linked_caregivers_screen.dart';
import 'package:user_mobile/features/blind_mode/screens/smart_glasses_settings_screen.dart';
import 'package:user_mobile/features/blind_mode/screens/accessibility_prefs_screen.dart';
import 'package:user_mobile/shared/glass_container.dart';

class BlindProfileScreen extends StatelessWidget {
  const BlindProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("User Settings", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              children: [
                // Avatar Area
                const CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                const SizedBox(height: 15),
                Text("Kamal Perera", style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                Text("App Setup Mode", style: GoogleFonts.poppins(fontSize: 14, color: Colors.orangeAccent, fontWeight: FontWeight.w500)),
                const SizedBox(height: 30),

                // Settings List
                GlassContainer(
                  padding: 10,
                  child: Column(
                    children: [
                      _buildSettingsTile(Icons.person_outline, "Personal Information",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BlindPersonalInfoScreen())),
                      ),
                      _buildDivider(),
                      _buildSettingsTile(Icons.link, "Linked Caregivers", badgeCount: "2",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const BlindLinkedCaregiversScreen())),
                      ),
                      _buildDivider(),
                      _buildSettingsTile(Icons.bluetooth_connected, "Smart Glasses Settings", badgeCount: "Connected",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SmartGlassesSettingsScreen())),
                      ),
                      _buildDivider(),
                      _buildSettingsTile(Icons.accessibility_new, "Accessibility Preferences",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AccessibilityPrefsScreen())),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Handover Button (Takes them to the VI Dashboard)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context, 
                      MaterialPageRoute(builder: (context) => const BlindDashboardScreen()),
                    );
                  },
                  icon: const Icon(Icons.visibility),
                  label: Text("Start Assistant Mode", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFACC15), // High contrast yellow
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 15),
                
                // Log Out
                TextButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: Text("Log Out", style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, {String? badgeCount, required Future<dynamic> Function() onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeCount != null)
            Text(badgeCount, style: GoogleFonts.poppins(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.0),
      child: Divider(color: Colors.white10, height: 1),
    );
  }
}