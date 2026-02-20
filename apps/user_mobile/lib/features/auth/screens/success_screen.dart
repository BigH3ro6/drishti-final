import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_container.dart';
import 'package:user_mobile/features/blind_mode/screens/blind_dashboard_screen.dart';

class SuccessScreen extends StatefulWidget {
  final String userRole; // "BLIND" or "CAREGIVER"

  const SuccessScreen({super.key, required this.userRole});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}
class _SuccessScreenState extends State<SuccessScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate away automatically after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (widget.userRole == "BLIND") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BlindDashboardScreen()),
        );
      } else {
        // TODO: Navigate to Caregiver Setup/Dashboard
        debugPrint("Navigate to Caregiver flow");
      }
    });
  }
  @override
  Widget build(BuildContext context) {
    // Navigate away automatically after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      // TODO: Replace with navigation to the Main Dashboard
      debugPrint("Navigating to Dashboard...");
    });

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GlassContainer(
              padding: 40,
              child: Column(
                children: [
                  const Icon(
                    Icons.check_circle_outline, 
                    color: Colors.greenAccent, 
                    size: 80
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Account Created\nSuccessfully!",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
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