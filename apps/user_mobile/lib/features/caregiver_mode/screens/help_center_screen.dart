import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_container.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

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
        title: Text("Help Center", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text("Frequently Asked Questions", style: GoogleFonts.poppins(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              _buildFaqTile("How to link a new user?"),
              _buildFaqTile("What to do in an emergency?"),
              _buildFaqTile("How to record a voice message?"),
              const SizedBox(height: 30),
              GlassContainer(
                padding: 20,
                child: Column(
                  children: [
                    const Icon(Icons.headset_mic_outlined, color: Colors.white, size: 40),
                    const SizedBox(height: 10),
                    Text("Still need help?", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text("Our support team is available 24/7", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: AppColors.primaryDark),
                      child: const Text("Contact Support"),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqTile(String question) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassContainer(
        padding: 5,
        child: ListTile(
          title: Text(question, style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
          trailing: const Icon(Icons.add, color: Colors.white54),
        ),
      ),
    );
  }
}