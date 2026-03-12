import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_container.dart';

class BlindLinkedCaregiversScreen extends StatelessWidget {
  const BlindLinkedCaregiversScreen({super.key});

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
        title: Text("Linked Caregivers", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text("Primary Contacts", style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _buildCaregiverTile("Nadithi Perera", "Primary Caregiver", isPrimary: true),
              _buildCaregiverTile("Rohan Perera", "Secondary"),
              const SizedBox(height: 30),
              GlassContainer(
                padding: 15,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_scanner, color: Colors.white),
                    const SizedBox(width: 10),
                    Text("Show Linking QR Code", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCaregiverTile(String name, String role, {bool isPrimary = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GlassContainer(
        padding: 15,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const CircleAvatar(backgroundColor: Colors.white24, child: Icon(Icons.person, color: Colors.white)),
          title: Text(name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(role, style: GoogleFonts.poppins(color: isPrimary ? Colors.greenAccent : Colors.white70, fontSize: 12)),
          trailing: const Icon(Icons.more_vert, color: Colors.white54),
        ),
      ),
    );
  }
}