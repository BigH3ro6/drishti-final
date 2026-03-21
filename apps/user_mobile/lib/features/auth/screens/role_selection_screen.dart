import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_button.dart';
import 'package:user_mobile/features/auth/screens/terms_conditions_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient, // Your Purple Background
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),

                // 1. Logo Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1), // Glow effect behind logo
                  ),
                  child: Image.asset(
                    'assets/images/drishti_logo.png',
                    height: 120,
                  ),
                ),
                const SizedBox(height: 20),
                
                // 2. App Name
                Text(
                  "Drishti",
                  style: GoogleFonts.poppins(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Vision Beyond Sight", // Tagline (Optional but looks good)
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white70,
                    letterSpacing: 1.2,
                  ),
                ),

                const Spacer(flex: 3),

                // 3. Prompt Text
                Text(
                  "Choose your Role",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 30),

                // 4. Buttons
                GlassButton(
                  text: "Caregiver",
                  onPressed: () {
                    Navigator.push(
                    context,
                      MaterialPageRoute(
                        builder: (context) => const TermsConditionsScreen(userRole: "CAREGIVER"),
                      ),
                    );
                    debugPrint("Caregiver Selected");
                  },
                ),
                const SizedBox(height: 20),
                GlassButton(
                  text: "Visually Impaired",
                  isPrimary: true, // Make this one stand out more
                  onPressed: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(
                    builder: (context) => const TermsConditionsScreen(userRole: "BLIND"),
                    ),
                    );
                    // TODO: Play audio confirmation "Blind Mode Selected"
                    debugPrint("Blind Mode Selected");
                  },
                ),

                const Spacer(flex: 1),
                
                // 5. Legal Text
                Text(
                  "By continuing, you agree to our Terms of Service\nand Privacy Policy.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white54,
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}