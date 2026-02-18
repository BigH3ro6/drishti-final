import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';

class GlassButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isPrimary; // True for "Visually Impaired" (Bigger/Bolder)

  const GlassButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: isPrimary ? 65 : 55, // Primary button is slightly taller
      decoration: BoxDecoration(
        // The "Glass" Effect
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(30),
          onTap: onPressed,
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: isPrimary ? 20 : 18,
                fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                color: AppColors.textWhite,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}