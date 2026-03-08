import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_container.dart';
import 'package:user_mobile/features/caregiver_mode/screens/map_tracking_screen.dart'; // 1. Imported Map Screen
import 'package:url_launcher/url_launcher.dart'; // 2. Imported URL Launcher

class EmergencyAlertsScreen extends StatefulWidget {
  const EmergencyAlertsScreen({super.key});

  @override
  State<EmergencyAlertsScreen> createState() => _EmergencyAlertsScreenState();
}

class _EmergencyAlertsScreenState extends State<EmergencyAlertsScreen> {
  // Dummy data simulating the database
  final Map<String, dynamic>? _activeAlert = {
    "name": "Kamal",
    "time": "Just now",
    "location": "Near De Mel Mawatha",
    "type": "SOS Button Pressed",
    "phone": "+94752761261", // 3. Added a simulated phone number
  };

  final List<Map<String, dynamic>> _alertHistory = [
    {
      "name": "Geetha",
      "date": "Yesterday",
      "time": "2:15 PM",
      "location": "Passing Nelum Pokuna",
      "type": "Fall Detected",
      "resolved": true,
    },
    {
      "name": "Kamal",
      "date": "Oct 12",
      "time": "9:00 AM",
      "location": "Perera's Home",
      "type": "SOS Button Pressed",
      "resolved": true,
    },
    {
      "name": "Rohan",
      "date": "Oct 10",
      "time": "6:45 PM",
      "location": "Near Majestic City",
      "type": "Battery Critical",
      "resolved": true,
    },
  ];

  // 4. Helper function to trigger the native phone dialer
  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      // If it fails (e.g., testing on a simulator that can't make calls), show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not launch dialer for $phoneNumber")),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Emergency Alerts",
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ACTIVE ALERT SECTION
              if (_activeAlert != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Text(
                    "ACTION REQUIRED",
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.redAccent,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildActiveAlertCard(_activeAlert),
                ),
                const SizedBox(height: 30),
              ],

              // ALERT HISTORY SECTION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  "Alert History",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _alertHistory.length,
                  itemBuilder: (context, index) {
                    final alert = _alertHistory[index];
                    return _buildHistoryCard(alert);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Highly visible RED card for active emergencies
  Widget _buildActiveAlertCard(Map<String, dynamic> alert) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.15),
        border: Border.all(color: Colors.redAccent, width: 2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.redAccent.withOpacity(0.2),
            blurRadius: 15,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${alert['name']} triggered an SOS!",
                      style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    Text(
                      alert['time'],
                      style: GoogleFonts.poppins(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              const Icon(Icons.location_on, color: Colors.white70, size: 16),
              const SizedBox(width: 5),
              Text(alert['location'], style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 20),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // 5. Navigate to the map tracking screen
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const MapTrackingScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.map),
                  label: Text("Track", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // 6. Launch the native dialer with the user's phone number!
                    if (alert['phone'] != null) {
                      _makePhoneCall(alert['phone']);
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.phone),
                  label: Text("Call", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  // Standard Glass container for resolved issues
  Widget _buildHistoryCard(Map<String, dynamic> alert) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GlassContainer(
        padding: 15,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 24),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(alert['type'], style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(alert['date'], style: GoogleFonts.poppins(fontSize: 11, color: Colors.white54)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("User: ${alert['name']}", style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white54, size: 12),
                      const SizedBox(width: 4),
                      Text(alert['time'], style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
                      const SizedBox(width: 10),
                      const Icon(Icons.location_on, color: Colors.white54, size: 12),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          alert['location'], 
                          style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}