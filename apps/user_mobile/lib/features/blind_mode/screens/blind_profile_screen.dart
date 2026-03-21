import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/features/blind_mode/screens/blind_dashboard_screen.dart';
import 'package:user_mobile/features/blind_mode/screens/blind_personal_info_screen.dart';
import 'package:user_mobile/features/blind_mode/screens/blind_linked_caregivers_screen.dart';
import 'package:user_mobile/features/blind_mode/screens/smart_glasses_settings_screen.dart';
import 'package:user_mobile/features/blind_mode/screens/accessibility_prefs_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:user_mobile/features/auth/screens/role_selection_screen.dart';
import 'package:user_mobile/shared/glass_container.dart';
import 'package:image_picker/image_picker.dart';
import 'package:user_mobile/core/services/profile_api_service.dart';
import 'package:flutter_tts/flutter_tts.dart'; 

class BlindProfileScreen extends StatefulWidget {
  const BlindProfileScreen({super.key});

  @override
  State<BlindProfileScreen> createState() => _BlindProfileScreenState();
}

class _BlindProfileScreenState extends State<BlindProfileScreen> {
  final ProfileApiService _profileApi = ProfileApiService();
  final FlutterTts _tts = FlutterTts();
  String _userName = "Loading...";
  String? _profileImageUrl;
  
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await _profileApi.getUserProfile();
    if (mounted && data != null) {
      setState(() {
        _userName = data['name'] ?? "User";
        _profileImageUrl = data['profile_image_url']; // Fetch the existing image!
      });
    }
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    
    if (!mounted) return;

    if (image != null) {
      // 1. Spoken and visual feedback
      _tts.speak("Uploading profile picture. Please wait.");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Uploading profile picture..."))
      );
      
      // 2. Send to Python -> Cloudinary -> Firestore
      final String? newUrl = await _profileApi.uploadProfileImage(image.path);
      
      if (!mounted) return;

      if (newUrl != null) {
        setState(() {
          _profileImageUrl = newUrl;
        });
        
        // 3. Success feedback!
        _tts.speak("Profile picture updated successfully.");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile picture updated!"), 
            backgroundColor: Colors.green,
          ),
        );
      } else {
        _tts.speak("Failed to upload picture.");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text("User Settings", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              children: [
                // Avatar Area with Upload Functionality
                GestureDetector(
                  onTap: _pickAndUploadImage,
                  child: Semantics(
                    label: "Double tap to upload a new profile picture",
                    button: true,
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white54, width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 50,
                            backgroundColor: Colors.white24,
                            backgroundImage: _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
                            child: _profileImageUrl == null 
                                ? Text(
                                    _userName == "Loading..." ? "?" : _userName[0].toUpperCase(),
                                    style: GoogleFonts.poppins(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)
                                  )
                                : null,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: AppColors.primaryLight, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                // Dynamic User Name
                Text(_userName, style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                Text("App Setup Mode", style: GoogleFonts.poppins(fontSize: 14, color: Colors.orangeAccent, fontWeight: FontWeight.w500)),
                const SizedBox(height: 30),

                // Settings List
                GlassContainer(
                  padding: 10,
                  child: Column(
                    children: [
                      _buildSettingsTile(Icons.person_outline, "Personal Information",
                        onTap: () async => Navigator.push(context, MaterialPageRoute(builder: (context) => const BlindPersonalInfoScreen())),
                      ),
                      _buildDivider(),
                      _buildSettingsTile(Icons.link, "Linked Caregivers",
                        onTap: () async => Navigator.push(context, MaterialPageRoute(builder: (context) => const BlindLinkedCaregiversScreen())),
                      ),
                      _buildDivider(),
                      _buildSettingsTile(Icons.bluetooth_connected, "Smart Glasses Settings", badgeCount: "Connected",
                        onTap: () async => Navigator.push(context, MaterialPageRoute(builder: (context) => const SmartGlassesSettingsScreen())),
                      ),
                      _buildDivider(),
                      _buildSettingsTile(Icons.accessibility_new, "Accessibility Preferences",
                        onTap: () async => Navigator.push(context, MaterialPageRoute(builder: (context) => const AccessibilityPrefsScreen())),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // Handover Button 
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context, 
                      MaterialPageRoute(builder: (context) => const BlindDashboardScreen()),
                    );
                  },
                  icon: const Icon(Icons.visibility),
                  label: Text("Start Assistant Mode", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFACC15), 
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 60),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  ),
                ),
                const SizedBox(height: 15),
                
                // Log Out
                TextButton.icon(
                  onPressed: () async {
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          backgroundColor: const Color(0xFF1E1B4B), 
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Text("Log Out", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                          content: Text("Are you sure you want to log out of Drishti?", style: GoogleFonts.poppins(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext), 
                              child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600)),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(dialogContext); 

                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
                                );

                                await FirebaseAuth.instance.signOut();

                                if (context.mounted) {
                                  Navigator.pushAndRemoveUntil(
                                    context,
                                    MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                                    (route) => false,
                                  );
                                }
                              },
                              child: Text("Log Out", style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  icon: const Icon(Icons.logout, color: Colors.redAccent),
                  label: Text("Log Out", style: GoogleFonts.poppins(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, {String? badgeCount, required Future<dynamic> Function() onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: GoogleFonts.poppins(color: Colors.white, fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeCount != null)
            Text(badgeCount, style: GoogleFonts.poppins(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(width: 10),
          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        ],
      ),
      onTap: onTap,
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 15.0),
      child: Divider(color: Colors.white10, height: 1),
    );
  }
}