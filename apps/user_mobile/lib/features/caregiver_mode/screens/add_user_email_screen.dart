import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_button.dart';
import 'package:user_mobile/shared/glass_text_field.dart';
import 'package:user_mobile/features/caregiver_mode/screens/connection_success_screen.dart';

class AddUserEmailScreen extends StatefulWidget {
  final bool isGroup;

  const AddUserEmailScreen({super.key, required this.isGroup});

  @override
  State<AddUserEmailScreen> createState() => _AddUserEmailScreenState();
}

class _AddUserEmailScreenState extends State<AddUserEmailScreen> {
  // Store a list of controllers so we can dynamically add more fields
  final List<TextEditingController> _emailControllers = [
    TextEditingController(),
  ];

  void _addEmailField() {
    if (_emailControllers.length < 5) {
      setState(() {
        _emailControllers.add(TextEditingController());
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum of 5 emails allowed.")),
      );
    }
  }

  // NEW METHOD: Removes a specific email field and cleans up its memory
  void _removeEmailField(int index) {
    setState(() {
      _emailControllers[index].dispose(); // Important: Free up the memory
      _emailControllers.removeAt(index);
    });
  }

  @override
  void dispose() {
    for (var controller in _emailControllers) {
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
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Enter user${widget.isGroup ? 's' : ''} email",
                  style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "Enter the email of the person you support. We'll send a one-time code to them for verification.",
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),

                if (widget.isGroup) ...[
                  const SizedBox(height: 10),
                  Text(
                    "Min - 2 emails & Max - 5 emails",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amberAccent,
                    ),
                  ),
                ],

                const SizedBox(height: 30),

                // Render the dynamic list of TextFields
                Expanded(
                  child: ListView.builder(
                    itemCount: _emailControllers.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 15.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (widget.isGroup) ...[
                              Text(
                                "User 0${index + 1}",
                                style: GoogleFonts.poppins(color: Colors.white),
                              ),
                              const SizedBox(height: 5),
                            ],
                            // UPDATED: Wrapped the text field in a Row to fit the delete button
                            Row(
                              children: [
                                Expanded(
                                  child: GlassTextField(
                                    hintText: "Example@gmail.com",
                                    icon: Icons.email_outlined,
                                    controller: _emailControllers[index],
                                  ),
                                ),
                                // Show a red minus button ONLY for extra fields (index > 0)
                                if (widget.isGroup && index > 0)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.remove_circle_outline,
                                      color: Colors.redAccent,
                                      size: 28,
                                    ),
                                    onPressed: () => _removeEmailField(index),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // The "Add Another Email" button (Only shows in Group mode)
                if (widget.isGroup && _emailControllers.length < 5) ...[
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _addEmailField,
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                      ),
                      label: Text(
                        "Add Another Email",
                        style: GoogleFonts.poppins(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Submit Button
                GlassButton(
                  text: "Send Verification Code",
                  isPrimary: true,
                  onPressed: () {
                    debugPrint(
                      "Sending verification to: ${_emailControllers.map((c) => c.text).toList()}",
                    );
                    // TODO: Trigger Firebase email invites, then navigate to success screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const ConnectionSuccessScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
