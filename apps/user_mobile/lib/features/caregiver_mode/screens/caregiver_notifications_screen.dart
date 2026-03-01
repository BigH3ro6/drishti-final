import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_container.dart';

class CaregiverNotificationsScreen extends StatefulWidget {
  const CaregiverNotificationsScreen({super.key});

  @override
  State<CaregiverNotificationsScreen> createState() => _CaregiverNotificationsScreenState();
}

class _CaregiverNotificationsScreenState extends State<CaregiverNotificationsScreen> {
  // Dummy notification data
  final List<Map<String, dynamic>> _notifications = [
    {
      "title": "Low Battery Alert",
      "body": "Kamal's device battery is down to 15%. Please remind him to charge it.",
      "time": "10 mins ago",
      "type": "warning", // info, success, warning
      "isRead": false,
    },
    {
      "title": "Safe Arrival",
      "body": "Geetha has safely arrived at Colombo Fort Station.",
      "time": "2 hours ago",
      "type": "success",
      "isRead": false,
    },
    {
      "title": "Route Deviation",
      "body": "Rohan has taken a different route than usual towards Majestic City.",
      "time": "5 hours ago",
      "type": "info",
      "isRead": true,
    },
    {
      "title": "System Update",
      "body": "A new version of Drishti is available with improved voice commands.",
      "time": "Yesterday",
      "type": "info",
      "isRead": true,
    },
    {
      "title": "Daily Summary",
      "body": "Kamal walked 1,250 steps today. View full activity report.",
      "time": "Yesterday",
      "type": "success",
      "isRead": true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: true, 
        title: Text(
          "Notifications",
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              // TODO: Mark all as read logic
              setState(() {
                for (var note in _notifications) {
                  note['isRead'] = true;
                }
              });
            },
            child: Text(
              "Mark all read",
              style: GoogleFonts.poppins(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.mainGradient),
        child: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            itemCount: _notifications.length,
            itemBuilder: (context, index) {
              final note = _notifications[index];
              return _buildNotificationTile(note);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationTile(Map<String, dynamic> note) {
    // Determine colors and icons based on the notification type
    Color iconColor;
    IconData iconData;

    switch (note['type']) {
      case 'warning':
        iconColor = Colors.orangeAccent;
        iconData = Icons.battery_alert_rounded;
        break;
      case 'success':
        iconColor = Colors.greenAccent;
        iconData = Icons.check_circle_outline;
        break;
      case 'info':
      default:
        iconColor = Colors.blueAccent;
        iconData = Icons.info_outline;
        break;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: GlassContainer(
        padding: 15,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon Container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: iconColor, size: 24),
            ),
            const SizedBox(width: 15),

            // Text Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        note['title'],
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: note['isRead'] ? FontWeight.w600 : FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      // Unread Indicator Dot
                      if (!note['isRead'])
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    note['body'],
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: note['isRead'] ? Colors.white70 : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    note['time'],
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.white54,
                    ),
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