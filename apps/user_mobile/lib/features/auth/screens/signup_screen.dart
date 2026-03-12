import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/features/auth/screens/login_screen.dart';
import 'package:user_mobile/shared/glass_button.dart';
import 'package:user_mobile/shared/glass_text_field.dart';
import 'package:user_mobile/features/auth/screens/success_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SignupScreen extends StatefulWidget {
  final String userRole; // "BLIND" or "CAREGIVER"

  const SignupScreen({super.key, required this.userRole});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

 Future<void> _signUpUser() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // --- 1.Check if any fields are empty ---
    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in all fields."), 
          backgroundColor: Colors.orange, 
        ),
      );
      return; 
    }

    // --- 2.Password Complexity Validation ---
    // At least 1 letter, at least 1 number, and 8+ characters total.
    final passwordRegex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d).{8,}$');
    if (!passwordRegex.hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password must be at least 8 characters with 1 letter and 1 number."),
          backgroundColor: Colors.orange,
        ),
      );
      return; 
    }

    // 3. Start loading state 
    setState(() {
      _isLoading = true;
    });

    try {
      // 4. Create the user in Firebase
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: email,       
            password: password, 
          );

      // 5. Update the user's Firebase profile with their Name
      await userCredential.user?.updateDisplayName(name);

      // --- 6.Send the Verification Email! ---
      await userCredential.user?.sendEmailVerification();
      if (mounted) {
        // Show a success message telling them to check their email
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account created! Please check your email to verify your account."),
            backgroundColor: Colors.green,
          ),
        );
      }

      // 7. If successful, navigate to SuccessScreen!
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SuccessScreen(userRole: widget.userRole),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      // 8. Handle Firebase-specific errors
      String errorMessage = 'An error occurred. Please try again.';
      if (e.code == 'email-already-in-use') {
        errorMessage = 'An account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is badly formatted.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      // 9. Stop loading state
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Trigger the NEW Google Authentication flow using the Singleton instance
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance
          .authenticate();

      // 2. Obtain the auth details (Synchronous now! Do not use 'await' here)
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // 3. Create a new Firebase credential using ONLY the idToken
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);

      // 5. Save the user's role locally for Auto-Login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRole', widget.userRole);

      // 6. Navigate to your Success Screen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SuccessScreen(userRole: widget.userRole),
          ),
        );
      }
    } on GoogleSignInException catch (e) {
      // The API throws an exception if the user closes the pop-up
      if (e.code == GoogleSignInExceptionCode.canceled) {
        setState(() => _isLoading = false);
        return;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Google Sign-In failed: ${e.description}'),
            backgroundColor: Colors.red,
          ),
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
        height: double.infinity, // Ensures full screen coverage
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
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
                    const Icon(
                      Icons.directions_walk,
                      color: Colors.white,
                      size: 40,
                    ),
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
                GlassTextField(
                  controller: _nameController,
                  hintText: "Enter your name",
                  icon: Icons.person_outline,
                ),
                const SizedBox(height: 15),
                GlassTextField(
                  controller: _emailController,
                  hintText: "Enter your email",
                  icon: Icons.email_outlined,
                ),
                const SizedBox(height: 15),
                GlassTextField(
                  controller: _passwordController,
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
                  text: _isLoading ? "Creating Account..." : "Create Account",
                  isPrimary: true,
                  onPressed: _isLoading ? () {} : _signUpUser,
                ),

                const SizedBox(height: 20),

                // 5. Divider "OR"
                Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.white30)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        "Or",
                        style: GoogleFonts.poppins(color: Colors.white70),
                      ),
                    ),
                    const Expanded(child: Divider(color: Colors.white30)),
                  ],
                ),

                const SizedBox(height: 20),

                // 6. Google Sign Up Button
                _buildSocialButton(
                  text: _isLoading ? "Connecting..." : "Sign up with Google",
                  onTap: _isLoading ? () {} : _signInWithGoogle,
                ),

                const SizedBox(height: 30),

                // 7. Login Link
                Center(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              LoginScreen(userRole: widget.userRole),
                        ),
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

  Widget _buildSocialButton({
    required String text,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white, // 1. Solid white background
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          // 2. A tiny shadow makes the white button pop off the gradient background
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 3. The official Google Logo
            Image.asset(
              'assets/images/google_logo.png',
              height: 24, 
              width: 24,
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors
                    .black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
