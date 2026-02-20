import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/features/auth/screens/login_screen.dart';
import 'package:user_mobile/shared/glass_button.dart';
import 'package:user_mobile/shared/glass_text_field.dart';

class SignupScreen extends StatelessWidget {
  final String userRole; // "BLIND" or "CAREGIVER"

  const SignupScreen({super.key, required this.userRole});

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
      body: Container(
        width: double.infinity,
        height: double.infinity, // Ensures full screen coverage
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            // Handles keyboard popping up
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                
                // 1. Header with Icon
                Row(
                  children: [
                    const Icon(Icons.directions_walk, color: Colors.white, size: 40),
                    const SizedBox(width: 10),
                    Text(
                      "Get Started",
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                Text(
                  "by creating a free account.",
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                
                const SizedBox(height: 40),

                // 2. Form Fields
                const GlassTextField(
                  hintText: "Enter your name",
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 15),
                const GlassTextField(
                  hintText: "Enter your email",
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 15),
                const GlassTextField(
                  hintText: "Enter your password",
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),

                const SizedBox(height: 15),
                
                // 3. Password Requirement Text
                Text(
                  "Use 8+ characters with at least one letter and one number.",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.white60,
                  ),
                ),

                const SizedBox(height: 30),

                // 4. Create Account Button
                GlassButton(
                  text: "Create Account",
                  isPrimary: true,
                  onPressed: () {
                    debugPrint("Creating account for $userRole");
                    // TODO: Connect to Firebase Auth
                  },
                ),

                const SizedBox(height: 20),

                // 5. Divider "OR"
                Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.white30)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text("Or", style: GoogleFonts.poppins(color: Colors.white70)),
                    ),
                    const Expanded(child: Divider(color: Colors.white30)),
                  ],
                ),

                const SizedBox(height: 20),

                // 6. Google Sign Up Button
                _buildSocialButton(
                  text: "Sign up with Google",
                  icon: Icons.g_mobiledata, // Using built-in icon for now
                  onTap: () {
                    debugPrint("Google Sign Up Clicked");
                  },
                ),

                const SizedBox(height: 30),

                // 7. Login Link
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) =>LoginScreen(userRole: userRole)),
                       );
                       debugPrint("Navigate to Login");
                       // Navigate to Login Screen
                    },
                    child: RichText(
                      text: TextSpan(
                        text: "Already have an account? ",
                        style: GoogleFonts.poppins(color: Colors.white70),
                        children: [
                          TextSpan(
                            text: "Sign In",
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper widget specifically for the Google button style
  Widget _buildSocialButton({required String text, required IconData icon, required VoidCallback onTap}) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Note: For a real app, use an SVG asset for the Google G logo
            Icon(icon, color: Colors.white, size: 30), 
            const SizedBox(width: 10),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}