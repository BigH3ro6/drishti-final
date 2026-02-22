import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_container.dart';
import 'package:user_mobile/shared/glass_bottom_nav_bar.dart';

class ConnectionSuccessScreen extends StatelessWidget {
  const ConnectionSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      // We use bottomNavigationBar property for the floating nav bar
      bottomNavigationBar: SafeArea(
        child: GlassBottomNavBar(
          selectedIndex: 0, // Default to Home
          onItemTapped: (index) {
            debugPrint("Navigating to tab $index");
            // TODO: Add actual tab navigation logic later
          },
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlassContainer(
              padding: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min, // Hug contents
                children: [
                  // Huge Checkmark
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.greenAccent, width: 4),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.greenAccent,
                      size: 60,
                      weight: 700,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "New User Connected\nSuccessfully!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
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
}