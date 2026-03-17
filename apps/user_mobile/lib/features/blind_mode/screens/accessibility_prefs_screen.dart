import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_container.dart';

class AccessibilityPrefsScreen extends StatefulWidget {
  const AccessibilityPrefsScreen({super.key});

  @override
  State<AccessibilityPrefsScreen> createState() => _AccessibilityPrefsScreenState();
}

class _AccessibilityPrefsScreenState extends State<AccessibilityPrefsScreen> {
  double _voiceSpeed = 1.0;
  String _hapticStrength = "Heavy";
  bool _readScreenNames = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text("Accessibility", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              Text("Voice Assistant Settings", style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GlassContainer(
                padding: 20,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Voice Speed (${_voiceSpeed.toStringAsFixed(1)}x)", style: GoogleFonts.poppins(color: Colors.white)),
                    Slider(
                      value: _voiceSpeed,
                      min: 0.5,
                      max: 2.0,
                      divisions: 6,
                      activeColor: const Color(0xFFFACC15),
                      inactiveColor: Colors.white24,
                      onChanged: (val) => setState(() => _voiceSpeed = val),
                    ),
                    const Divider(color: Colors.white10),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text("Announce Screen Names", style: GoogleFonts.poppins(color: Colors.white, fontSize: 14)),
                      activeColor: const Color(0xFFFACC15),
                      value: _readScreenNames,
                      onChanged: (val) => setState(() => _readScreenNames = val),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              Text("Tactile Settings", style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              GlassContainer(
                padding: 10,
                child: Column(
                  children: [
                    _buildRadioTile("Light"),
                    _buildRadioTile("Medium"),
                    _buildRadioTile("Heavy"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRadioTile(String title) {
    return RadioListTile<String>(
      title: Text(title, style: GoogleFonts.poppins(color: Colors.white)),
      value: title,
      groupValue: _hapticStrength,
      activeColor: const Color(0xFFFACC15),
      onChanged: (val) {
        setState(() {
          _hapticStrength = val!;
        });
      },
    );
  }
}