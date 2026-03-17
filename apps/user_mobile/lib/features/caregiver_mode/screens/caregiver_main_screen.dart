import 'package:flutter/material.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/shared/glass_bottom_nav_bar.dart';

// Import your screens!
import 'package:user_mobile/features/caregiver_mode/screens/caregiver_dashboard_screen.dart';
import 'package:user_mobile/features/caregiver_mode/screens/caregiver_profile_screen.dart';
import 'package:user_mobile/features/caregiver_mode/screens/caregiver_notifications_screen.dart';

class CaregiverMainScreen extends StatefulWidget {
  const CaregiverMainScreen({super.key});

  @override
  State<CaregiverMainScreen> createState() => _CaregiverMainScreenState();
}

class _CaregiverMainScreenState extends State<CaregiverMainScreen> {
  int _currentIndex = 0;

  // This list holds the actual screens for each tab!
  final List<Widget> _screens = [
    const CaregiverDashboardScreen(),
    
    // Placeholder for Tab 2 (e.g., Connections/Map)
    const Center(child: Text("Connections Page Coming Soon", style: TextStyle(color: Colors.white))), 
    
    // Placeholder for Tab 3 (e.g., Notifications)
    const CaregiverNotificationsScreen(), 
    
    const CaregiverProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Lets the gradient flow under the nav bar
      backgroundColor: AppColors.purpleDark,
      // 1. The Body switches based on the current index
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      // 2. The single Navigation Bar that controls everything
      bottomNavigationBar: SafeArea(
        child: GlassBottomNavBar(
          selectedIndex: _currentIndex,
          onItemTapped: (index) {
            setState(() {
              _currentIndex = index; // Updates the screen!
            });
          },
        ),
      ),
    );
  }
}