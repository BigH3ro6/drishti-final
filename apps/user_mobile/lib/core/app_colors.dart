import 'package:flutter/material.dart';

class AppColors {
  // --- The Deep Sea Glass Theme (Optimized for White Text) ---
  
  // A deep, muted ocean blue
  static const Color primaryDark = Color.fromARGB(255, 2, 177, 174); 
  
  // A deep, muted seafoam green
  static const Color primaryLight = Color.fromARGB(255, 4, 45, 25); 
  
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