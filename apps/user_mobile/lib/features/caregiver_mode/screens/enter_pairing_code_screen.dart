import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_button.dart';
import 'package:user_mobile/shared/glass_text_field.dart';
import 'package:user_mobile/features/caregiver_mode/screens/connection_success_screen.dart';
import 'package:user_mobile/core/services/pairing_api_service.dart';

class EnterPairingCodeScreen extends StatefulWidget {
  final bool isGroup;

  const EnterPairingCodeScreen({super.key, required this.isGroup});

  @override
  State<EnterPairingCodeScreen> createState() => _EnterPairingCodeScreenState();
}

class _EnterPairingCodeScreenState extends State<EnterPairingCodeScreen> {
  final List<TextEditingController> _codeControllers = [TextEditingController()];
  bool _isLoading = false;

  void _addCodeField() {
    if (_codeControllers.length < 5) {
      setState(() {
        _codeControllers.add(TextEditingController());
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum of 5 users allowed at once.")),
      );
    }
  }

  void _removeCodeField(int index) {
    setState(() {
      _codeControllers[index].dispose(); 
      _codeControllers.removeAt(index);
    });
  }

  Future<void> _submitCodes() async {
    // 1. Validate inputs
    bool hasEmpty = _codeControllers.any((c) => c.text.trim().isEmpty);
    if (hasEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all pairing codes."), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final pairingService = PairingApiService();
      bool allSuccess = true;

      // 2. Loop through every code typed in and send them to Python!
      for (var controller in _codeControllers) {
        String code = controller.text.trim();
        bool success = await pairingService.linkCaregiver(code);
        if (!success) {
          allSuccess = false;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Failed to link code: $code"), backgroundColor: Colors.red),
            );
          }
        }
      }

      // 3. If everything worked, go to your beautiful Success Screen!
      if (allSuccess && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const ConnectionSuccessScreen()),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    for (var controller in _codeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    widget.isGroup ? "Add new users" : "Add one new user",
                    style: GoogleFonts.poppins(fontSize: 16, color: Colors.white70),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Enter pairing code",
                  style: GoogleFonts.poppins(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                Text(
                  "Ask the visually impaired user to say 'Pair Caregiver' to generate a 6-digit secure code.",
                  style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
                ),

                if (widget.isGroup) ...[
                  const SizedBox(height: 10),
                  Text(
                    "Min - 2 users & Max - 5 users",
                    style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amberAccent),
                  ),
                ],

                const SizedBox(height: 30),

                Expanded(
                  child: ListView.builder(
                    itemCount: _codeControllers.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.isGroup) ...[
                              Text("User 0${index + 1}", style: GoogleFonts.poppins(color: Colors.white)),
                              const SizedBox(height: 5),
                            ],
                            Row(
                              children: [
                                Expanded(
                                  child: GlassTextField(
                                    hintText: "e.g. A7B9X2",
                                    icon: Icons.key_outlined,
                                    controller: _codeControllers[index],
                                  ),
                                ),
                                if (widget.isGroup && index > 0)
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 28),
                                    onPressed: () => _removeCodeField(index),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                if (widget.isGroup && _codeControllers.length < 5) ...[
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _addCodeField,
                      icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                      label: Text("Add Another Code", style: GoogleFonts.poppins(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                GlassButton(
                  text: _isLoading ? "Linking..." : "Link User",
                  isPrimary: true,
                  onPressed: _isLoading ? () {} : _submitCodes,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}