import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_container.dart';
import 'package:user_mobile/core/services/pairing_api_service.dart';
import 'package:user_mobile/features/caregiver_mode/screens/add_user_type_screen.dart';

class LinkedUsersScreen extends StatefulWidget {
  const LinkedUsersScreen({super.key});

  @override
  State<LinkedUsersScreen> createState() => _LinkedUsersScreenState();
}

class _LinkedUsersScreenState extends State<LinkedUsersScreen> {
  final PairingApiService _pairingService = PairingApiService();
  List<Map<String, dynamic>> _linkedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  // Calls the Python backend to get the real list
  Future<void> _fetchUsers() async {
    final users = await _pairingService.getLinkedUsers();
    if (mounted) {
      setState(() {
        _linkedUsers = users;
        _isLoading = false;
      });
    }
  }

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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.white))
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // 1. Show a message if they have no links yet
                    if (_linkedUsers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          "No users linked yet.\nTap below to connect!",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
                        ),
                      ),

                    // 2. Dynamically build the list from the database!
                    ..._linkedUsers.map((user) => _buildUserTile(user)),

                    const SizedBox(height: 30),

                    // 3. Link New User Button (Wired up!)
                    GestureDetector(
                      onTap: () async {
                        // Navigate to the pairing screen, and refresh the list when we come back!
                        await Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AddUserTypeScreen()),
                        );
                        _fetchUsers(); 
                      },
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

  // The visual tile builder
// The upgraded visual tile builder
  Widget _buildUserTile(Map<String, dynamic> user) {
    String name = user['name'] ?? "Unknown User";
    String role = user['role'] == "BLIND" ? "Visually Impaired" : "Caregiver";
    String profileImageUrl = user['profile_image_url'] ?? "";

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GlassContainer(
        padding: 15,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: Colors.white24,
            // 1. If we have a URL, show the image from the internet!
            backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
            // 2. If we don't have a URL, show the initial letter instead
            child: profileImageUrl.isEmpty 
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                : null,
          ),
          title: Text(name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text(role, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
          trailing: IconButton(
            icon: const Icon(Icons.settings, color: Colors.white54),
            // 3. Wire up the gear icon to open the settings menu!
            onPressed: () => _showUserSettings(user),
          ),
        ),
      ),
    );
  }
  void _showUserSettings(Map<String, dynamic> user) {
    String name = user['name'] ?? "Unknown User";
    String role = user['role'] == "BLIND" ? "Visually Impaired" : "Caregiver";
    String profileImageUrl = user['profile_image_url'] ?? "";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Let the glass effect shine through
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E), // A dark background to match your gradient
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Large Profile Picture
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.white24,
                backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
                child: profileImageUrl.isEmpty 
                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold))
                    : null,
              ),
              const SizedBox(height: 15),
              Text(name, style: GoogleFonts.poppins(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              Text(role, style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70)),
              
              const SizedBox(height: 30),
              
              // Action Buttons
              ListTile(
                leading: const Icon(Icons.location_on, color: Colors.white),
                title: Text("View Live Location", style: GoogleFonts.poppins(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigate to Maps Screen
                },
              ),
              ListTile(
                leading: const Icon(Icons.link_off, color: Colors.redAccent),
                title: Text("Unlink User", style: GoogleFonts.poppins(color: Colors.redAccent)),
                onTap: () async {
                  // 1. Close the bottom menu immediately
                  Navigator.pop(context);
                  
                  // 2. Show a quick loading message
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Unlinking ${user['name']}..."), duration: const Duration(seconds: 1)),
                  );

                  // 3. Call the backend to delete the link!
                  String targetUid = user['uid']; // We get this from the API dictionary!
                  bool success = await _pairingService.unlinkUser(targetUid);

                  if (success && mounted) {
                    // 4. Show success message
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("User unlinked successfully."), backgroundColor: Colors.green),
                    );
                    
                    // 5. INSTANT UI UPDATE: Remove them from the local list immediately!
                    setState(() {
                      _linkedUsers.removeWhere((u) => u['uid'] == targetUid);
                    });
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Failed to unlink user."), backgroundColor: Colors.red),
                    );
                  }
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }
}