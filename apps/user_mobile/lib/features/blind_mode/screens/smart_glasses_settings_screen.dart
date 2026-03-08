import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_container.dart';

class SmartGlassesSettingsScreen extends StatelessWidget {
  const SmartGlassesSettingsScreen({super.key});

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
        title: Text("Smart Glasses", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                GlassContainer(
                  padding: 30,
                  child: Column(
                    children: [
                      const Icon(Icons.bluetooth_connected, color: Colors.greenAccent, size: 60),
                      const SizedBox(height: 15),
                      Text("Drishti Vision V1", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 5),
                      Text("Battery: 85%", style: GoogleFonts.poppins(color: Colors.white70)),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                _buildActionTile(Icons.camera_alt_outlined, "Calibrate Camera"),
                const SizedBox(height: 15),
                _buildActionTile(Icons.system_update_alt, "Check for Firmware Updates"),
                const SizedBox(height: 15),
                _buildActionTile(Icons.bluetooth_disabled, "Disconnect Glasses", color: Colors.redAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionTile(IconData icon, String title, {Color color = Colors.white}) {
    return GlassContainer(
      padding: 5,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: GoogleFonts.poppins(color: color, fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.arrow_forward_ios, color: color.withOpacity(0.5), size: 16),
      ),
    );
  }
}