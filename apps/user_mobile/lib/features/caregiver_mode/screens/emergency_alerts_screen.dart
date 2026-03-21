import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_container.dart';
import 'package:user_mobile/features/caregiver_mode/screens/map_tracking_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:user_mobile/core/services/pairing_api_service.dart';
import 'package:intl/intl.dart';

class EmergencyAlertsScreen extends StatefulWidget {
  const EmergencyAlertsScreen({super.key});

  @override
  State<EmergencyAlertsScreen> createState() => _EmergencyAlertsScreenState();
}

class _EmergencyAlertsScreenState extends State<EmergencyAlertsScreen> {
  final PairingApiService _pairingApi = PairingApiService();
  List<Map<String, dynamic>> _connectedUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLinkedUsers();
  }

  Future<void> _fetchLinkedUsers() async {
    final users = await _pairingApi.getLinkedUsers();
    if (mounted) {
      setState(() {
        _connectedUsers = users;
        _isLoading = false;
      });
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not launch dialer for $phoneNumber")),
        );
      }
    }
  }

  // --- NEW: Reset the alert! ---
  Future<void> _markAsResolved(String incidentId, String targetUserId) async {
    try {
      // 1. Mark the incident as handled
      await FirebaseFirestore.instance.collection('incidents').doc(incidentId).update({'resolved': true});
      // 2. Reset the Visually Impaired user's status back to Safe!
      await FirebaseFirestore.instance.collection('users').doc(targetUserId).update({'status': 'Safe'});
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Emergency marked as resolved!"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      debugPrint("Error resolving: $e");
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
          child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : StreamBuilder<QuerySnapshot>(
                // Listen to the incidents collection live!
                stream: FirebaseFirestore.instance.collection('incidents').orderBy('timestamp', descending: true).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: Colors.white));
                  }

                  // 1. Get the IDs of the users this Caregiver is linked to
                  final linkedUserIds = _connectedUsers.map((u) => u['id']).toList();

                  // 2. Filter incidents so we only see ones belonging to OUR linked users
                  final allMyIncidents = snapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return linkedUserIds.contains(data['user_id']);
                  }).toList();

                  // 3. Separate them into Active vs History
                  final activeIncidents = allMyIncidents.where((doc) => (doc.data() as Map<String, dynamic>)['resolved'] == false).toList();
                  final historyIncidents = allMyIncidents.where((doc) => (doc.data() as Map<String, dynamic>)['resolved'] == true).toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ACTIVE ALERT SECTION
                      if (activeIncidents.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                          child: Text(
                            "ACTION REQUIRED",
                            style: GoogleFonts.poppins(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.redAccent, letterSpacing: 1.5),
                          ),
                        ),
                        // Show a card for every active emergency
                        ...activeIncidents.map((doc) => Padding(
                          padding: const EdgeInsets.only(bottom: 15, left: 24, right: 24),
                          child: _buildActiveAlertCard(doc.id, doc.data() as Map<String, dynamic>),
                        )),
                      ],

                      // ALERT HISTORY SECTION
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                        child: Text(
                          "Alert History",
                          style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                      Expanded(
                        child: historyIncidents.isEmpty 
                          ? Center(child: Text("No past emergencies.", style: GoogleFonts.poppins(color: Colors.white70)))
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 24),
                              itemCount: historyIncidents.length,
                              itemBuilder: (context, index) {
                                final doc = historyIncidents[index];
                                return _buildHistoryCard(doc.data() as Map<String, dynamic>);
                              },
                            ),
                      ),
                    ],
                  );
                },
              ),
        ),
      ),
    );
  }

  // --- UI HELPER: The Red Active Card ---
  Widget _buildActiveAlertCard(String incidentId, Map<String, dynamic> alert) {
    // Match the alert's user_id to our local _connectedUsers list to get their name and phone
    final user = _connectedUsers.firstWhere((u) => u['id'] == alert['user_id'], orElse: () => {});
    final name = user['name'] ?? "Unknown User";
    final phone = user['phone'];
    
    // Format the Firestore timestamp
    DateTime time = (alert['timestamp'] as Timestamp).toDate();
    String formattedTime = DateFormat('h:mm a').format(time);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.15),
        border: Border.all(color: Colors.redAccent, width: 2),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.redAccent.withOpacity(0.2), blurRadius: 15, spreadRadius: 2)],
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
                    Text("$name triggered an SOS!", style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(formattedTime, style: GoogleFonts.poppins(fontSize: 12, color: Colors.redAccent, fontWeight: FontWeight.bold)),
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
              Text("Location sent to Map Tracker", style: GoogleFonts.poppins(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 20),
          
          // --- Action Buttons ---
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const MapTrackingScreen()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent, foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                  ),
                  icon: const Icon(Icons.map),
                  label: Text("Track", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                ),
              ),
              if (phone != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _makePhoneCall(phone),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.white), foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    icon: const Icon(Icons.phone),
                    label: Text("Call", style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  ),
                ),
              ]
            ],
          ),
          const SizedBox(height: 10),
          // Resolve Button
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => _markAsResolved(incidentId, alert['user_id']),
              child: Text("Mark as Resolved", style: GoogleFonts.poppins(color: Colors.white70, decoration: TextDecoration.underline)),
            ),
          )
        ],
      ),
    );
  }

  // --- UI HELPER: The History Card ---
  Widget _buildHistoryCard(Map<String, dynamic> alert) {
    final user = _connectedUsers.firstWhere((u) => u['id'] == alert['user_id'], orElse: () => {});
    final name = user['name'] ?? "Unknown User";
    
    DateTime time = (alert['timestamp'] as Timestamp).toDate();
    String formattedTime = DateFormat('h:mm a').format(time);
    String formattedDate = DateFormat('MMM d').format(time);

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
                      Text("SOS Alert", style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                      Text(formattedDate, style: GoogleFonts.poppins(fontSize: 11, color: Colors.white54)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text("User: $name", style: GoogleFonts.poppins(fontSize: 12, color: Colors.white70)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white54, size: 12),
                      const SizedBox(width: 4),
                      Text(formattedTime, style: GoogleFonts.poppins(color: Colors.white54, fontSize: 11)),
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