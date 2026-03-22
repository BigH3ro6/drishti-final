import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_container.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:user_mobile/core/services/profile_api_service.dart';
import 'package:intl_phone_field/intl_phone_field.dart';


class BlindPersonalInfoScreen extends StatefulWidget {
  const BlindPersonalInfoScreen({super.key});

  @override
  State<BlindPersonalInfoScreen> createState() => _BlindPersonalInfoScreenState();
}

class _BlindPersonalInfoScreenState extends State<BlindPersonalInfoScreen> {
  final ProfileApiService _profileApi = ProfileApiService();
  
  bool _isLoading = true;
  String _name = "Loading...";
  String _phone = "Not provided";
  String _medicalNotes = "None provided";

  @override
  void initState() {
    super.initState();
    _fetchRealData();
  }

  Future<void> _fetchRealData() async {
    final profileData = await _profileApi.getUserProfile();
    final user = FirebaseAuth.instance.currentUser;
    
    if (mounted) {
      setState(() {
        if (profileData != null) {
          _name = profileData['name'] ?? "Unknown User";
          _phone = profileData['phone'] ?? user?.phoneNumber ?? "Not provided";
          _medicalNotes = profileData['medical_notes'] ?? "None provided";
        }
        _isLoading = false;
      });
    }
  }

  void _showEditDialog() {
    TextEditingController nameController = TextEditingController(text: _name);
    TextEditingController notesController = TextEditingController(text: _medicalNotes == "None provided" ? "" : _medicalNotes);
    String updatedPhone = _phone == "Not provided" ? "" : _phone;
    
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1B4B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("Edit Profile", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Full Name",
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                  ),
                  validator: (value) => value != null && value.isEmpty ? "Name cannot be empty" : null,
                ),
                const SizedBox(height: 25),
                
                IntlPhoneField(
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                    counterStyle: const TextStyle(color: Colors.white54),
                  ),
                  style: const TextStyle(color: Colors.white),
                  dropdownTextStyle: const TextStyle(color: Colors.white),
                  dropdownIcon: const Icon(Icons.arrow_drop_down, color: Colors.white70),
                  initialCountryCode: 'LK',
                  onChanged: (phone) {
                    updatedPhone = phone.completeNumber;
                  },
                ),
                const SizedBox(height: 10),
                
                TextFormField(
                  controller: notesController,
                  maxLines: 2,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: "Medical Notes (Optional)",
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white.withOpacity(0.3))),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: GoogleFonts.poppins(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryLight),
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context);
                setState(() => _isLoading = true);

                bool success = await _profileApi.updateProfileDetails(
                  nameController.text, 
                  updatedPhone,
                  medicalNotes: notesController.text,
                );
                
                if (success) {
                  _fetchRealData(); 
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile Updated!"), backgroundColor: Colors.green));
                } else {
                  setState(() => _isLoading = false);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update profile"), backgroundColor: Colors.red));
                }
              }
            },
            child: Text("Save", style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
        title: Text("Personal Info", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _buildField("Full Name", _name),
                    const SizedBox(height: 20),
                    _buildField("Phone Number", _phone),
                    const SizedBox(height: 20),
                    _buildField("Medical Notes", _medicalNotes),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: _showEditDialog,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryDark,
                        minimumSize: const Size(double.infinity, 55),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                      child: Text("Edit Information", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
        ),
      ),
    );
  }

  Widget _buildField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.poppins(color: Colors.white70, fontSize: 14)),
        const SizedBox(height: 8),
        GlassContainer(
          padding: 15,
          child: Row(
            children: [
              Expanded(child: Text(value, style: GoogleFonts.poppins(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500))),
            ],
          ),
        ),
      ],
    );
  }
}