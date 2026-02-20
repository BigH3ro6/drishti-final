import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_button.dart';
import 'package:user_mobile/shared/glass_text_field.dart';
import 'package:user_mobile/shared/glass_container.dart';

class ResetPasswordScreen extends StatelessWidget {
  const ResetPasswordScreen({super.key});

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
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GlassContainer(
                  padding: 30,
                  child: Column(
                    children: [
                      // 1. Title
                      Text(
                        "Reset Your Password",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 2. Instructions
                      Text(
                        "Enter the email connected with your account and we will send you a recovery code.",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),

                      // 3. Email Input
                      const GlassTextField(
                        hintText: "Enter your email",
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 30),

                      // 4. Submit Button
                      GlassButton(
                        text: "Send Recovery Code",
                        isPrimary: true,
                        onPressed: () {
                          // TODO: Trigger Firebase Password Reset
                          debugPrint("Send Recovery Code Clicked");
                        },
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
}