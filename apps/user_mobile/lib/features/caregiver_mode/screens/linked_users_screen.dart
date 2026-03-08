import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_container.dart';

class LinkedUsersScreen extends StatelessWidget {
  const LinkedUsersScreen({super.key});

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
        title: Text("Linked Users", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildUserTile("Kamal", "Father"),
              _buildUserTile("Geetha", "Mother"),
              _buildUserTile("Rohan", "Brother"),
              const SizedBox(height: 30),
              GestureDetector(
                onTap: () {},
                child: GlassContainer(
                  padding: 15,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.add_circle_outline, color: Colors.white),
                      const SizedBox(width: 10),
                      Text("Link New User", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserTile(String name, String relation) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GlassContainer(
        padding: 15,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(backgroundColor: Colors.white24, child: Text(name[0], style: const TextStyle(color: Colors.white))),
          title: Text(name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(relation, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
          trailing: const Icon(Icons.settings, color: Colors.white54),
        ),
      ),
    );
  }
}