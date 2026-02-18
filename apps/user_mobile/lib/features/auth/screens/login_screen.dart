import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_button.dart';
import 'package:user_mobile/shared/glass_text_field.dart';
import 'package:user_mobile/features/auth/screens/signup_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // 1. Header
                Center(
                  child: Column(
                    children: [
                      Text(
                        "Welcome back to",
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          color: Colors.white70,
                        ),
                      ),
                      Text(
                        "Drishti",
                        style: GoogleFonts.poppins(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 50),

                // 2. Form Labels & Fields
                _buildLabel("Email"),
                const GlassTextField(
                  hintText: "Enter your email",
                  icon: Icons.email_outlined,
                ),

                const SizedBox(height: 20),

                _buildLabel("Password"),
                const GlassTextField(
                  hintText: "Enter your password",
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),

                // 3. Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      // TODO: Navigate to Reset Password Screen
                      debugPrint("Forgot Password Clicked");
                    },
                    child: Text(
                      "Forgot Password?",
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                // 4. Login Button
                GlassButton(
                  text: "Login",
                  isPrimary: true,
                  onPressed: () {
                    debugPrint("Login Clicked");
                    // TODO: Connect to Firebase Auth Login
                  },
                ),

                const SizedBox(height: 50),

                // 5. Create Account Link
                Center(
                  child: Column(
                    children: [
                      Text(
                        "Don't have an account?",
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: () {
                          // Navigate to Signup (Defaulting to Caregiver for now, 
                          // or you can send them back to Role Selection)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SignupScreen(userRole: "CAREGIVER")),
                          );
                        },
                        child: Text(
                          "Create one",
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 10, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.poppins(
          fontSize: 14,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}