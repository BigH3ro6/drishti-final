import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_button.dart';
import 'package:user_mobile/shared/glass_text_field.dart';
import 'package:user_mobile/shared/glass_container.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // 1. Controller to read the email text
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // 2. The Firebase Reset Password Function
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();

    // Check if the field is empty
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter your email address."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Tell Firebase to send the recovery email
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

      if (mounted) {
        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Password reset link sent! Check your email."),
            backgroundColor: Colors.green, 
          ),
        );
        // Pop the screen to go back to the Login page automatically
        Navigator.pop(context); 
      }
    } on FirebaseAuthException catch (e) {
      // Handle formatting errors
      String errorMessage = 'An error occurred. Please try again.';
      if (e.code == 'invalid-email') {
        errorMessage = 'The email address is badly formatted.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
                      GlassTextField(
                        controller: _emailController, 
                        hintText: "Enter your email",
                        icon: Icons.email_outlined,
                      ),
                      const SizedBox(height: 30),

                      // 4. Submit Button 
                      GlassButton(
                        text: _isLoading ? "Sending..." : "Send Recovery Code",
                        isPrimary: true,
                        onPressed: _isLoading ? () {} : _resetPassword,
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