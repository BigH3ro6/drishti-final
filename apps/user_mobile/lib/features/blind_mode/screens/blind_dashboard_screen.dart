import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for HapticFeedback
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/features/blind_mode/screens/blind_profile_screen.dart';

class BlindDashboardScreen extends StatelessWidget {
  const BlindDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // A pure black background ensures the highest possible contrast
      backgroundColor: Colors.black, 

      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false, // Prevents a back button from showing up
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white38, size: 32),
            tooltip: 'Helper Settings', // Helps screen readers ignore it or read it correctly
            onPressed: () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => const BlindProfileScreen()),
              );
            },
          ),
          const SizedBox(width: 10), // Gives it a little breathing room from the edge
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. VOICE ASSISTANT BUTTON (Top Third)
            Expanded(
              child: _buildMassiveButton(
                context: context,
                title: "Voice Assistant",
                subtitle: "Tap to ask a question",
                icon: Icons.mic_rounded,
                backgroundColor: const Color(0xFFFACC15), // High contrast Yellow
                textColor: Colors.black,
                semanticsLabel: "Voice Assistant. Double tap to speak to the AI.",
                onTap: () {
                  // Heavy vibration for physical confirmation
                  HapticFeedback.heavyImpact();
                  debugPrint("Voice Assistant Tapped");
                },
              ),
            ),

            // 2. SEND MESSAGE BUTTON (Middle Third)
            Expanded(
              child: _buildMassiveButton(
                context: context,
                title: "Send Message",
                subtitle: "Tap to record audio",
                icon: Icons.record_voice_over_rounded,
                backgroundColor: const Color(0xFF9333EA), // Deep Purple
                textColor: Colors.white,
                semanticsLabel: "Send Message to Caregiver. Double tap to start recording.",
                onTap: () {
                  HapticFeedback.heavyImpact();
                  debugPrint("Send Message Tapped");
                },
              ),
            ),

            // 3. SOS EMERGENCY BUTTON (Bottom Third)
            Expanded(
              child: _buildMassiveButton(
                context: context,
                title: "SOS",
                subtitle: "Hold to alert caregiver",
                icon: Icons.warning_rounded,
                backgroundColor: const Color(0xFFDC2626), // Emergency Red
                textColor: Colors.white,
                semanticsLabel: "SOS Emergency. Long press to alert your caregivers.",
                onTap: () {
                  // If they just tap it, vibrate lightly and maybe trigger a voice warning
                  HapticFeedback.lightImpact();
                  debugPrint("Warn user to hold the button for SOS");
                },
                onLongPress: () {
                  // Aggressive vibration for actual SOS trigger
                  HapticFeedback.vibrate(); 
                  debugPrint("SOS TRIGGERED!");
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- ACCESSIBILITY UI HELPER ---

  Widget _buildMassiveButton({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    required String semanticsLabel,
  }) {
    // Semantics tells the phone's built-in screen reader how to read this widget aloud
    return Semantics(
      label: semanticsLabel,
      button: true,
      child: Material(
        color: backgroundColor,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          splashColor: textColor.withOpacity(0.3),
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              // Adds a subtle internal border to separate the massive blocks visually
              border: Border(
                bottom: BorderSide(color: Colors.black.withOpacity(0.3), width: 4),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 80, color: textColor),
                const SizedBox(height: 15),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 36, // Massive font size
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}