import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlassTextField extends StatefulWidget {
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller;

  const GlassTextField({
    super.key,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.controller,
  });

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  // 1. This variable remembers if the text should be hidden right now
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    // 2. Set the initial state based on whether it's a password field
    _isObscured = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9), 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: widget.controller,
        // 3. We use our new variable here instead of the hardcoded one!
        obscureText: _isObscured, 
        style: GoogleFonts.poppins(color: Colors.black87),
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: GoogleFonts.poppins(color: Colors.grey),
          // Don't forget to use widget.icon since we are in a StatefulWidget now
          prefixIcon: Icon(widget.icon, color: Colors.deepPurple), 
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          // 4. Upgrade the plain Icon to a clickable IconButton
          suffixIcon: widget.isPassword
              ? IconButton(
                  icon: Icon(
                    // Flip the icon design based on the state
                    _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    // 5. When clicked, flip the switch and redraw the widget!
                    setState(() {
                      _isObscured = !_isObscured;
                    });
                  },
                )
              : null,
        ),
      ),
    );
  }
}