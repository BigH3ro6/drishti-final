import 'package:flutter/material.dart';

class AppColors {
  // The Deep Purple Gradient from your Figma
  static const Color purpleDark = Color(0xFF4A00E0);
  static const Color purpleLight = Color(0xFF8E2DE2);
  
  // Text Colors
  static const Color textWhite = Colors.white;
  static const Color textGray = Colors.white70;

  static const LinearGradient mainGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [purpleDark, purpleLight],
  );
}