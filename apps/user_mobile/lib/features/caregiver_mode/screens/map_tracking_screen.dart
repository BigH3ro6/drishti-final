import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';

class MapTrackingScreen extends StatefulWidget {
  const MapTrackingScreen({super.key});

  @override
  // 1. Added SingleTickerProviderStateMixin to manage the Tab Animation smoothly
  State<MapTrackingScreen> createState() => _MapTrackingScreenState();
}

class _MapTrackingScreenState extends State<MapTrackingScreen> with SingleTickerProviderStateMixin {
  // Dummy data
  final List<Map<String, dynamic>> _users = [
    {"name": "Kamal", "location": "Near De Mel mawatha\nSince 1.30 p.m", "battery": 100, "steps": "1,250 Steps", "dist": "5.2 km"},
    {"name": "Geetha", "location": "Passing Nelum Pokuna\nUpdate now", "battery": 85, "steps": "0 Steps", "dist": "3 km"},
    {"name": "Rohan", "location": "Near Majestic City\nSince 2.55 p.m", "battery": 55, "steps": "3250 Steps", "dist": "8 km"},
  ];

  final List<String> _places = [
    "Perera's home",
    "Boswel Place",
    "Colombo Fort Station",
    "City Hospital",
    "Keells",
  ];

  final double _sheetInitialSize = 0.25; 
  
  // 2. Added a dedicated TabController
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Listen to tab taps and refresh the UI to show the correct list
    _tabController.addListener(() {
      setState(() {}); 
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          // BACKGROUND MAP
          Container(
            color: const Color(0xFFE8EAF6),
            width: double.infinity,
            height: double.infinity,
            child: CustomPaint(painter: GridPainter()),
          ),

          // TOP APP BAR
          Positioned(top: 50, left: 20, right: 20, child: _buildTopBar()),

          // FLOATING BUTTONS
          Positioned(
            bottom: (screenHeight * _sheetInitialSize) + 20, 
            left: 20,
            child: Column(
              children: [
                _buildFloatingButton(Icons.phone, Colors.lightBlueAccent),
                const SizedBox(height: 15),
                _buildFloatingButton(Icons.add_location_alt_outlined, Colors.redAccent),
              ],
            ),
          ),
          Positioned(
            bottom: (screenHeight * _sheetInitialSize) + 20, 
            right: 20,
            child: _buildFloatingButton(Icons.warning_amber_rounded, Colors.red, isHuge: true),
          ),

          // DRAGGABLE BOTTOM SHEET
          _buildDraggableBottomSheet(),
        ],
      ),
    );
  }

  // --- UI HELPER METHODS ---

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87), onPressed: () => Navigator.pop(context)),
          Text("Live Tracking", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
          IconButton(icon: const Icon(Icons.mic, color: Colors.black87), onPressed: () {}),
        ],
      ),
    );
  }

  Widget _buildFloatingButton(IconData icon, Color color, {bool isHuge = false}) {
    return Container(
      width: isHuge ? 70 : 50,
      height: isHuge ? 70 : 50,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Icon(icon, color: color, size: isHuge ? 35 : 25),
    );
  }

  // 3. THE NEW CUSTOM SCROLL VIEW FIX
Widget _buildDraggableBottomSheet() {
    return DraggableScrollableSheet(
      initialChildSize: _sheetInitialSize,
      minChildSize: 0.15,     
      maxChildSize: 0.85,     
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
            boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15, spreadRadius: 5)],
          ),
          child: CustomScrollView(
            controller: scrollController, 
            slivers: [
              // --- HERE IS THE SLIVER APP BAR ---
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                automaticallyImplyLeading: false,
                toolbarHeight: 0, 
                bottom: PreferredSize(
                  // INCREASED HEIGHT TO 90 to fix the overflow error!
                  preferredSize: const Size.fromHeight(90), 
                  child: Column(
                    children: [
                      // Little drag handle pill
                      Container(
                        margin: const EdgeInsets.only(top: 10, bottom: 15),
                        width: 50,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey[300], 
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      // Tab Bar
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 40),
                        decoration: BoxDecoration(
                          color: AppColors.purpleLight.withOpacity(0.1), 
                          borderRadius: BorderRadius.circular(30), 
                        ),
                        child: TabBar(
                          controller: _tabController,
                          dividerColor: Colors.transparent, 
                          dividerHeight: 0, // THIS KILLS THE UGLY LINE!
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: AppColors.purpleLight.withOpacity(0.3), 
                            borderRadius: BorderRadius.circular(30), 
                          ),
                          tabs: const [
                            Tab(icon: Icon(Icons.people_alt, color: AppColors.purpleDark)),
                            Tab(icon: Icon(Icons.domain, color: AppColors.purpleDark)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10), 
                    ],
                  ),
                ),
              ),
              // --- END OF SLIVER APP BAR ---

              // Swap the list out dynamically based on the clicked tab!
              if (_tabController.index == 0) _buildUsersSliverList(),
              if (_tabController.index == 1) _buildPlacesSliverList(),
            ],
          ),
        );
      },
    );
  }
  // 4. Converted Lists to Slivers
  Widget _buildUsersSliverList() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final user = _users[index];
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(radius: 35, backgroundColor: AppColors.purpleDark, child: Text(user["name"][0], style: GoogleFonts.poppins(color: Colors.white, fontSize: 24))),
                        Positioned(bottom: 0, right: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white, width: 2)), child: const Icon(Icons.battery_charging_full, size: 10, color: Colors.white)))
                      ],
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user["name"], style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(user["location"], style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                          const SizedBox(height: 10),
                          Row(children: [const Icon(Icons.directions_walk, size: 16, color: AppColors.purpleLight), const SizedBox(width: 5), Text(user["steps"], style: GoogleFonts.poppins(fontSize: 12))]),
                          Row(children: [const Icon(Icons.directions_car, size: 16, color: AppColors.purpleLight), const SizedBox(width: 5), Text(user["dist"], style: GoogleFonts.poppins(fontSize: 12))]),
                          Row(children: [const Icon(Icons.wifi, size: 16, color: Colors.green), const SizedBox(width: 5), Text("Connected • ${user["battery"]}%", style: GoogleFonts.poppins(fontSize: 12, color: Colors.green))]),
                        ],
                      ),
                    ),
                  ],
                ),
                if (index < _users.length - 1) Divider(color: Colors.grey[200], height: 30),
              ],
            );
          },
          childCount: _users.length,
        ),
      ),
    );
  }

  Widget _buildPlacesSliverList() {
    return SliverPadding(
      padding: const EdgeInsets.all(20),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            if (index == 0) {
              return Column(
                children: [
                  ListTile(leading: const CircleAvatar(backgroundColor: AppColors.purpleLight, child: Icon(Icons.add, color: Colors.white)), title: Text("Add a new Place", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)), onTap: () {}),
                  Divider(color: Colors.grey[200], height: 20),
                ],
              );
            }
            final placeIndex = index - 1;
            return Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.location_on, color: AppColors.purpleLight),
                  title: Text(_places[placeIndex], style: GoogleFonts.poppins()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.close, color: Colors.grey, size: 20), onPressed: () {}),
                      const Icon(Icons.notifications_active, color: AppColors.purpleLight, size: 20),
                    ],
                  ),
                ),
                if (placeIndex < _places.length - 1) Divider(color: Colors.grey[200], height: 20),
              ],
            );
          },
          childCount: _places.length + 1,
        ),
      ),
    );
  }
}

// Ensure this is outside the main class bracket!
class GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..strokeWidth = 2.0;
    for (double i = 0; i < size.width; i += 20) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }
    for (double i = 0; i < size.height; i += 20) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}