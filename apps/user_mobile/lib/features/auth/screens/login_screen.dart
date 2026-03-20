import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_button.dart';
import 'package:user_mobile/shared/glass_text_field.dart';
import 'package:user_mobile/features/auth/screens/reset_password_screen.dart';
import 'package:user_mobile/features/auth/screens/role_selection_screen.dart';
import 'package:user_mobile/features/caregiver_mode/screens/caregiver_main_screen.dart';
import 'package:user_mobile/features/blind_mode/screens/blind_dashboard_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginScreen extends StatefulWidget {
  final String userRole;

  const LoginScreen({super.key, required this.userRole});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
  Future<void> _loginUser() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // 1.Check if fields are empty before talking to Firebase
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill in both your email and password."), 
          backgroundColor: Colors.orange,
        ),
      );
      return; 
    }

    // 2. Start loading state
    setState(() {
      _isLoading = true;
    });

    try {
      // 3. Talk to Firebase
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRole', widget.userRole);
      
      if (mounted) {
        if (widget.userRole == "CAREGIVER") {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const CaregiverMainScreen()),
            (route) => false, 
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const BlindDashboardScreen()),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      // 4. Handle errors 
      String errorMessage = 'An error occurred. Please try again.';
      if (e.code == 'invalid-credential' || e.code == 'user-not-found' || e.code == 'wrong-password') {
        errorMessage = 'Incorrect email or password.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'The email address is badly formatted.';
      } else if (e.code == 'too-many-requests') {
        errorMessage = 'Too many attempts. Please try again later.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } finally {
      // 5. Stop loading state
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
      // 1. Trigger the Google Authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();

      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      // 2. Obtain the auth details 
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      // 3. Create a new Firebase credential 
      final OAuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase
      await FirebaseAuth.instance.signInWithCredential(credential);

      // 5. Save the user's role locally for Auto-Login
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userRole', widget.userRole);

      // 6. Navigate directly to the Dashboard!
      if (mounted) {
        if (widget.userRole == "CAREGIVER") {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const CaregiverMainScreen()),
            (route) => false,
          );
        } else {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const BlindDashboardScreen()),
            (route) => false,
          );
        }
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        setState(() => _isLoading = false);
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Google Sign-In failed: ${e.description ?? "Unknown error"}'), backgroundColor: Colors.red),
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
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
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
                GlassTextField(
                  controller: _emailController,
                  hintText: "Enter your email",
                  icon: Icons.email_outlined,
                ),

                const SizedBox(height: 20),

                _buildLabel("Password"),
                
                GlassTextField(
                  controller: _passwordController,
                  hintText: "Enter your password",
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),

                // 3. Forgot Password Link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ResetPasswordScreen(),
                        ),
                      );
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
                  text: _isLoading ? "Logging in..." : "Login",
                  isPrimary: true,
                  onPressed: _isLoading ? () {} : _loginUser,
                ),

                const SizedBox(height: 50),
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

                // 6. Google Sign In Button
                _buildSocialButton(
                  text: _isLoading ? "Connecting..." : "Sign in with Google",
                  onTap: _isLoading ? () {} : _signInWithGoogle,
                ),
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
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const RoleSelectionScreen(),
                            ),
                            (route) => false, // Clears the back history
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

Widget _buildSocialButton({required String text, required VoidCallback onTap}) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
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
                color: Colors.black87,
              ),
            ),
          ],
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
