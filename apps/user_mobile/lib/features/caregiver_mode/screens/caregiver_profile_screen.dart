import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/features/caregiver_mode/screens/about_drishti_screen.dart';
import 'package:user_mobile/features/caregiver_mode/screens/caregiver_notifications_screen.dart';
import 'package:user_mobile/features/caregiver_mode/screens/help_center_screen.dart';
import 'package:user_mobile/features/caregiver_mode/screens/linked_users_screen.dart';
import 'package:user_mobile/features/caregiver_mode/screens/personal_info_screen.dart';
import 'package:user_mobile/features/caregiver_mode/screens/privacy_security_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:user_mobile/features/auth/screens/role_selection_screen.dart';
import 'package:user_mobile/shared/glass_container.dart';
import 'package:user_mobile/features/caregiver_mode/screens/membership_screen.dart';
import 'package:user_mobile/core/services/profile_api_service.dart';
import 'package:image_picker/image_picker.dart';

class CaregiverProfileScreen extends StatefulWidget {
  const CaregiverProfileScreen({super.key});

  @override
  State<CaregiverProfileScreen> createState() => _CaregiverProfileScreenState();
}

class _CaregiverProfileScreenState extends State<CaregiverProfileScreen> {
  final ProfileApiService _profileApi = ProfileApiService();
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
        _userName = data['name'] ?? "Caregiver";
        _profileImageUrl = data['profile_image_url'];
      });
    }
  }
 Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    
    // 1. Kill the blue squiggly warning with an early return!
    if (!mounted) return; 

    if (image != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Uploading profile picture..."))
      );
      
      final String? newUrl = await _profileApi.uploadProfileImage(image.path);
      
      // 2. Another check after the second 'await'
      if (!mounted) return; 

      if (newUrl != null) {
        setState(() {
          _profileImageUrl = newUrl;
        });
        
        // 3. The bracket fix! backgroundColor is now a property of SnackBar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile picture updated!"), 
            backgroundColor: Colors.green, 
          ),
        );
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
        title: Text(
          "My Profile",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
                // 1. Profile Header (Avatar & Name)
                _buildProfileHeader(),
                const SizedBox(height: 30),

                // 2. Main Settings Group
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Account Settings",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GlassContainer(
                  padding: 10,
                  child: Column(
                    children: [
                      // Membership Tile (Navigates to the Membership Screen)
                      _buildSettingsTile(
                        Icons.star_border_rounded, 
                        "Membership Plan", 
                        badgeCount: "Free",
                        onTap: () {
                          Navigator.push(
                            context, 
                            MaterialPageRoute(builder: (context) => const MembershipScreen()),
                          );
                        }
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        Icons.person_outline, 
                        "Personal Information",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PersonalInfoScreen())),
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        Icons.group_outlined, 
                        "Linked Users", 
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LinkedUsersScreen())),
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        Icons.notifications_none, 
                        "Notifications",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const CaregiverNotificationsScreen())),
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        Icons.privacy_tip_outlined, 
                        "Privacy & Security",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PrivacySecurityScreen())),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 3. Support & About Group
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Support",
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                GlassContainer(
                  padding: 10,
                  child: Column(
                    children: [
                      _buildSettingsTile(
                        Icons.help_outline, 
                        "Help Center",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const HelpCenterScreen())),
                      ),
                      _buildDivider(),
                      _buildSettingsTile(
                        Icons.info_outline, 
                        "About Drishti",
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AboutDrishtiScreen())),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),

                // 4. Log Out Button
                GestureDetector(
                  onTap: () async {
                    // Show the confirmation pop-up first!
                    showDialog(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        return AlertDialog(
                          backgroundColor: const Color(0xFF1E1B4B), // Dark purple to match theme
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          title: Text("Log Out", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
                          content: Text("Are you sure you want to log out of Drishti?", style: GoogleFonts.poppins(color: Colors.white70)),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(dialogContext), // Close the pop-up
                              child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.w600)),
                            ),
                            TextButton(
                              onPressed: () async {
                                Navigator.pop(dialogContext); // Close the pop-up first

                                // 1. Show the loading circle
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.redAccent)),
                                );

                                // 2. Sign out of Firebase
                                await FirebaseAuth.instance.signOut();

                                // 3. Destroy history and jump to the Start screen
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
                  child: GlassContainer(
                    padding: 15,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.logout, color: Colors.redAccent),
                        const SizedBox(width: 10),
                        Text(
                          "Log Out",
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- UI HELPER METHODS ---

  Widget _buildProfileHeader() {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickAndUploadImage, // Tap to upload!
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
                  // Show the real image if it exists!
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
        const SizedBox(height: 15),
        Text(
          _userName,
          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          "Primary Caregiver",
          style: GoogleFonts.poppins(fontSize: 14, color: Colors.greenAccent, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(IconData icon, String title, {String? badgeCount, VoidCallback? onTap}) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: Colors.white),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badgeCount != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                badgeCount,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 10),
          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
        ],
      ),
      onTap: onTap ?? () {
        debugPrint("$title tapped");
      }, 
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15.0),
      child: Divider(
        color: Colors.white.withOpacity(0.1),
        height: 1,
      ),
    );
  }
}