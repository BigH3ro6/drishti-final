import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_container.dart';
import 'package:user_mobile/features/blind_mode/screens/blind_profile_screen.dart'; // We will build this next

enum ConnectState { idle, connecting, success, failed }

class GlassesConnectionScreen extends StatefulWidget {
  const GlassesConnectionScreen({super.key});

  @override
  State<GlassesConnectionScreen> createState() => _GlassesConnectionScreenState();
}

class _GlassesConnectionScreenState extends State<GlassesConnectionScreen> {
  ConnectState _currentState = ConnectState.idle;

  void _simulateConnection() async {
    setState(() => _currentState = ConnectState.connecting);
    
    // Simulating a 3-second bluetooth pairing process
    await Future.delayed(const Duration(seconds: 3));
    
    // For now, we'll force a success. You can change this logic later!
    setState(() => _currentState = ConnectState.success);
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
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GlassContainer(
                  padding: 15,
                  child: Text(
                    "Connect Your Glasses",
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Spacer(),

                // Dynamic Center Area based on State
                _buildCenterContent(),

                const Spacer(),

                // Bottom Text / Skip Button
                if (_currentState == ConnectState.idle || _currentState == ConnectState.failed) ...[
                  Text(
                    "Press the button above to pair\nyour smart glasses with the app",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      // Skip pairing and go straight to Profile or Dashboard
                      Navigator.pushReplacement(
                        context, 
                        MaterialPageRoute(builder: (context) => const BlindProfileScreen()),
                      );
                    },
                    child: Text(
                      "Skip for now",
                      style: GoogleFonts.poppins(
                        color: Colors.white54,
                        decoration: TextDecoration.underline,
                        decorationColor: Colors.white54,
                      ),
                    ),
                  ),
                ] else if (_currentState == ConnectState.success) ...[
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context, 
                        MaterialPageRoute(builder: (context) => const BlindProfileScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.purpleDark,
                      minimumSize: const Size(double.infinity, 55),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text("Continue", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCenterContent() {
    switch (_currentState) {
      case ConnectState.idle:
      case ConnectState.failed:
        return GestureDetector(
          onTap: _simulateConnection,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.purpleLight.withOpacity(0.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFACC15).withOpacity(0.6), // Glowing Yellow
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
              border: Border.all(color: Colors.white54, width: 2),
            ),
            alignment: Alignment.center,
            child: Text(
              _currentState == ConnectState.failed ? "Retry" : "Connect",
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        );
      case ConnectState.connecting:
        return const CircularProgressIndicator(color: Color(0xFFFACC15));
      case ConnectState.success:
        return GlassContainer(
          padding: 40,
          child: Column(
            children: [
              const Icon(Icons.check_circle, color: Colors.greenAccent, size: 80),
              const SizedBox(height: 20),
              Text(
                "Glasses Connected\nSuccessfully!",
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        );
    }
  }
}