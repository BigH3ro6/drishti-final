import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_container.dart';
import 'package:user_mobile/core/services/pairing_api_service.dart';

class BlindLinkedCaregiversScreen extends StatefulWidget {
  const BlindLinkedCaregiversScreen({super.key});

  @override
  State<BlindLinkedCaregiversScreen> createState() => _BlindLinkedCaregiversScreenState();
}

class _BlindLinkedCaregiversScreenState extends State<BlindLinkedCaregiversScreen> {
  final PairingApiService _pairingService = PairingApiService();
  List<Map<String, dynamic>> _caregivers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCaregivers();
  }

  Future<void> _fetchCaregivers() async {
    final users = await _pairingService.getLinkedUsers();
    if (mounted) {
      setState(() {
        _caregivers = users;
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
        title: Text("Linked Caregivers", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
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
                    Text("Your Support Network", style: GoogleFonts.poppins(color: Colors.white70, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),

                    if (_caregivers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 40),
                        child: Text(
                          "No caregivers linked yet.",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.poppins(color: Colors.white70, fontSize: 16),
                        ),
                      ),

                    // Map the actual backend data to the UI
                    ..._caregivers.map((user) => _buildCaregiverTile(user)),

                    const SizedBox(height: 30),

                    // Generate Code Button (Replaced the old QR code logic)
                    GestureDetector(
                      onTap: _generateAndShowCode,
                      child: GlassContainer(
                        padding: 15,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.pin_outlined, color: Colors.white),
                            const SizedBox(width: 10),
                            Text("Generate Pairing Code", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
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

  Widget _buildCaregiverTile(Map<String, dynamic> user) {
    String name = user['name'] ?? "Unknown Caregiver";
    String profileImageUrl = user['profile_image_url'] ?? "";

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GlassContainer(
        padding: 15,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: Colors.white24,
            backgroundImage: profileImageUrl.isNotEmpty ? NetworkImage(profileImageUrl) : null,
            child: profileImageUrl.isEmpty 
                ? Text(name.isNotEmpty ? name[0].toUpperCase() : "?", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                : null,
          ),
          title: Text(name, style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          subtitle: Text("Caregiver", style: GoogleFonts.poppins(color: Colors.greenAccent, fontSize: 12)),
          trailing: IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white54),
            onPressed: () => _showCaregiverSettings(user),
          ),
        ),
      ),
    );
  }

  // Generates the code and shows it in a massive dialog for sighted helpers
  Future<void> _generateAndShowCode() async {
    // Show a loading snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Generating code..."), duration: Duration(seconds: 1)),
    );

    String? code = await _pairingService.generatePairingCode();

    if (code != null && mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: const Color(0xFF1A1A2E),
          title: Text("Pairing Code", style: GoogleFonts.poppins(color: Colors.white)),
          content: Text(
            code,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 40, letterSpacing: 8, fontWeight: FontWeight.bold, color: Colors.greenAccent),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Done", style: GoogleFonts.poppins(color: Colors.white70)),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to generate code."), backgroundColor: Colors.red),
      );
    }
  }

  // The Bottom Sheet to Unlink Caregivers
  void _showCaregiverSettings(Map<String, dynamic> user) {
    String name = user['name'] ?? "Unknown Caregiver";
    String profileImageUrl = user['profile_image_url'] ?? "";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
              
              const SizedBox(height: 30),
              
              ListTile(
                leading: const Icon(Icons.link_off, color: Colors.redAccent),
                title: Text("Remove Caregiver", style: GoogleFonts.poppins(color: Colors.redAccent)),
                onTap: () async {
                  Navigator.pop(context);
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Removing $name..."), duration: const Duration(seconds: 1)),
                  );

                  String targetUid = user['id'];
                  bool success = await _pairingService.unlinkUser(targetUid);

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Caregiver removed successfully."), backgroundColor: Colors.green),
                    );
                    setState(() {
                      _caregivers.removeWhere((u) => u['id'] == targetUid);
                    });
                  } else if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Failed to remove caregiver."), backgroundColor: Colors.red),
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