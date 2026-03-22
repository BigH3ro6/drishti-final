import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';

class AboutDrishtiScreen extends StatelessWidget {
  const AboutDrishtiScreen({super.key});

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
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(30.0),
            child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                const Icon(Icons.visibility, size: 80, color: Colors.white),
                const SizedBox(height: 20),
                Text("Drishti", style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white)),
                Text("Version 1.0.0", style: GoogleFonts.poppins(color: Colors.white54)),
                const SizedBox(height: 40),
                Text(
                  "Drishti is an advanced assistance platform designed to empower the visually impaired through AI-driven navigation and real-time caregiver support.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, height: 1.5),
                ),
                const Spacer(),
                Text("© 2026 Drishti Tech", style: GoogleFonts.poppins(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}