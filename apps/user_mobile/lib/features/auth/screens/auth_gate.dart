import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:user_mobile/core/app_colors.dart';

import 'package:user_mobile/features/auth/screens/role_selection_screen.dart';
import 'package:user_mobile/features/caregiver_mode/screens/caregiver_main_screen.dart';
import 'package:user_mobile/features/blind_mode/screens/blind_dashboard_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    // 1. Check if Firebase has a logged-in user
    User? user = FirebaseAuth.instance.currentUser;
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    if (user == null) {
      // 2. Nobody is logged in, go to Role Selection (or Login)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
      );
    } else {
      // 3. User IS logged in! read the local memory to find their role
      final prefs = await SharedPreferences.getInstance();
      String? role = prefs.getString('userRole');

      // 4. Route them to the correct dashboard!
      if (role == "CAREGIVER") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CaregiverMainScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BlindDashboardScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // This is the "Splash Screen" they see for a split second while we check
    return const Scaffold(
      backgroundColor: AppColors.purpleDark, 
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}