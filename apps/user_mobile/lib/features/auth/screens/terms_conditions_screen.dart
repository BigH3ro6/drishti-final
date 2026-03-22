import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_button.dart';
import 'package:user_mobile/shared/glass_container.dart';
import 'package:user_mobile/features/auth/screens/signup_screen.dart';

class TermsConditionsScreen extends StatelessWidget {
  final String userRole; // "BLIND" or "CAREGIVER"

  const TermsConditionsScreen({super.key, required this.userRole});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true, // Allows gradient to go behind the back button
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
        decoration: const BoxDecoration(
          gradient: AppColors.mainGradient,
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // 1. Title Header
                GlassContainer(
                  padding: 15,
                  child: Text(
                    "By using this app, you agree to these Terms and Conditions.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Scrollable Legal Text
                Expanded(
                  child: GlassContainer(
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        child: Text(
                          _getTermsText(), // Helper method for long text
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            height: 1.6, // Better readability
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // 3. I Agree Button
                GlassButton(
                  text: "I Agree",
                  isPrimary: true,
                  onPressed: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(
                     builder: (context) => SignupScreen(userRole: userRole),
                    ),
                    );
                    debugPrint("User accepted terms for role: $userRole");
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTermsText() {
    return """
1. Acceptance of Terms
This app is designed to support visually impaired users and their caregivers by providing accessibility-related services. By accessing or using Drishti, you agree to be bound by these Terms.

2. Privacy Policy
We respect your privacy. Your personal data is protected and will not be shared without your consent. We collect location data solely for the purpose of the Caregiver Tracking feature.

3. Accessibility Standards
We aim to meet WCAG 2.1 AA accessibility standards. However, we cannot guarantee that every screen is perfectly accessible on every device.

4. Limitation of Liability
The app is provided "as is". We are not responsible for any loss or damage resulting from its use. This app is an assistive tool and should not replace a white cane, guide dog, or human judgment in dangerous situations.

5. Caregiver Responsibilities
Caregivers must act in the user's best interests and respect user privacy at all times. Misuse of tracking data will result in account termination.

6. Updates
We may update these terms occasionally. Continued use of the app means you accept the updated terms.
""";
  }
}