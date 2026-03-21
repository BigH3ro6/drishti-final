import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_container.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

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
        title: Text("Privacy & Security", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: GlassContainer(
              padding: 10,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildSecurityTile(Icons.lock_outline, "Change Password"),
                  const Divider(color: Colors.white10),
                  _buildSecurityTile(Icons.fingerprint, "Enable Biometric Login"),
                  const Divider(color: Colors.white10),
                  _buildSecurityTile(Icons.delete_forever_outlined, "Delete Account", color: Colors.redAccent),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityTile(IconData icon, String title, {Color color = Colors.white}) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: GoogleFonts.poppins(color: color, fontSize: 15)),
      trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
      onTap: () {},
    );
  }
}