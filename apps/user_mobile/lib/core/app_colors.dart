import 'package:flutter/material.dart';

class AppColors {
  // --- The Deep Sea Glass Theme (Optimized for White Text) ---
  
  // A deep, muted ocean blue
  static const Color primaryDark = Color(0xFF2C5E7A); 
  
  // A deep, muted seafoam green
  static const Color primaryLight = Color(0xFF3A7558); 
  
  // Text Colors (Kept crisp and white!)
  static const Color textWhite = Colors.white;
  static const Color textGray = Colors.white70;

  // The blended deep pastel gradient
  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primaryDark, primaryLight],
  );
}