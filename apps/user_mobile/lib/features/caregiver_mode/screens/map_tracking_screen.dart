import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:user_mobile/core/app_colors.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:user_mobile/core/services/pairing_api_service.dart';
import 'package:geocoding/geocoding.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:user_mobile/features/caregiver_mode/add_place_screen.dart';

class MapTrackingScreen extends StatefulWidget {
  const MapTrackingScreen({super.key});

  @override
  // 1. Added SingleTickerProviderStateMixin to manage the Tab Animation smoothly
  State<MapTrackingScreen> createState() => _MapTrackingScreenState();
}

class _MapTrackingScreenState extends State<MapTrackingScreen> with SingleTickerProviderStateMixin {

 final PairingApiService _apiService = PairingApiService();
 List<Map<String, dynamic>> _savedPlaces = [];
  
  List<Map<String, dynamic>> _liveUsers = [];
  Set<Marker> _userMarkers = {};
  Set<Marker> _placeMarkers = {};
  Set<Circle> _placeCircles = {};
  bool _isLoading = true;
  GoogleMapController? _mapController;

  final CameraPosition _initialLocation = const CameraPosition(
    target: LatLng(6.9271, 79.8612), 
    zoom: 14.5,
  );

  final double _sheetInitialSize = 0.25; 
  
  // Added a dedicated TabController
  late TabController _tabController;  

@override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });

    // Add the API calls to fetch the data when the screen loads
    _fetchLiveLocations();
    _fetchSavedPlaces(); 
  }

 Future<void> _fetchLiveLocations() async {
    final linkedUsers = await _apiService.getLinkedUsers();
    
    List<Map<String, dynamic>> updatedUsersList = [];
    Set<Marker> newMarkers = {};

    for (var user in linkedUsers) {
      final locationData = await _apiService.getUserLocation(user['id']);
      
      if (locationData != null) {
        double lat = locationData['latitude'];
        double lng = locationData['longitude'];
        
        // --- 1. PARSE THE TIMESTAMP ---
        String formattedTime = "Recently";
        if (locationData['updated_at'] != null) {
          try {
            // Convert the Python UTC time to the user's local phone time
            DateTime time = HttpDate.parse(locationData['updated_at'].toString()).toLocal();            // Format it to look like "2:45 PM"
            String minute = time.minute.toString().padLeft(2, '0');
            String ampm = time.hour >= 12 ? 'PM' : 'AM';
            int hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
            formattedTime = "$hour:$minute $ampm";
          } catch (e) {
            debugPrint("❌ Time parse error: $e");
          }
        }

        // --- 2. REVERSE GEOCODING ---
        String humanReadableAddress = "Live Location";
        try {
          List<Placemark> placemarks = await placemarkFromCoordinates(lat, lng);
          if (placemarks.isNotEmpty) {
            Placemark place = placemarks[0];
            humanReadableAddress = "Near ${place.street}, ${place.locality}";
          }
        } catch (e) {}
        
        // --- 3. GENERATE THE CUSTOM PROFILE MARKER ---
        BitmapDescriptor profileMarker = await _createProfileMarker(user['profile_image_url']);

        updatedUsersList.add({
          "name": user['name'] ?? "Unknown",
          "location": "$humanReadableAddress\nLast seen at $formattedTime", 
          "battery": 100, 
          "steps": "Active",
          "dist": "Live",
          "lat": lat,
          "lng": lng,
          "profileImageUrl": user['profile_image_url'],
        });

        newMarkers.add(
          Marker(
            markerId: MarkerId(user['id']),
            position: LatLng(lat, lng),
            zIndexInt: 2,
            infoWindow: InfoWindow(
              title: user['name'] ?? "User",
              snippet: "Updated at $formattedTime", 
            ),
            icon: profileMarker, 
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _liveUsers = updatedUsersList;
        _userMarkers = newMarkers;
        _isLoading = false;
      });

      if (newMarkers.isNotEmpty && _mapController != null) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(newMarkers.first.position, 15.0),
        );
      }
    }
  }
  
  Future<void> _fetchSavedPlaces() async {
    final places = await _apiService.getSavedPlaces();
    
    Set<Marker> newPlaceMarkers = {};
    Set<Circle> newPlaceCircles = {};

    for (var place in places) {
      if (place['latitude'] != null && place['longitude'] != null) {
        LatLng position = LatLng(place['latitude'], place['longitude']);
        String placeId = place['id'] ?? place['name']; // Use Firestore ID if available

        // 1. Draw the small pin in the center
        newPlaceMarkers.add(
          Marker(
            markerId: MarkerId('marker_$placeId'),
            position: position,
            zIndexInt: 1,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            infoWindow: InfoWindow(
              title: place['name'] ?? "Saved Place",
              snippet: "Safe Zone (100m)",
            ),
          ),
        );

        // 2. Draw the translucent Geofence Circle around it
        newPlaceCircles.add(
          Circle(
            circleId: CircleId('circle_$placeId'),
            center: position,
            radius: 100, // The 100-meter safe zone radius!
            fillColor: AppColors.primaryLight.withOpacity(0.2), 
            strokeColor: AppColors.primaryDark, 
            strokeWidth: 2,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _savedPlaces = places;
        _placeMarkers = newPlaceMarkers;
        _placeCircles = newPlaceCircles;
      });
    }
  }
  Future<BitmapDescriptor> _createProfileMarker(String? imageUrl) async {
    const int size = 150; // Size of the map pin
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);

    // 1. Draw the circular background/border (Using your AppColors.primaryDark)
    final Paint borderPaint = Paint()
      ..color = const Color(0xFF2D1B6B) 
      ..isAntiAlias = true;
    canvas.drawCircle(const Offset(size / 2, size / 2), size / 2.0, borderPaint);

    // 2. Try to fetch and draw the user's profile picture
    if (imageUrl != null && imageUrl.isNotEmpty) {
      try {
        final http.Response response = await http.get(Uri.parse(imageUrl));
        final Uint8List bytes = response.bodyBytes;
        final ui.Codec codec = await ui.instantiateImageCodec(bytes, targetWidth: size - 16, targetHeight: size - 16);
        final ui.FrameInfo frameInfo = await codec.getNextFrame();
        final ui.Image image = frameInfo.image;

        // Clip the image to a circle so it fits inside the border
        final Path clipPath = Path()..addOval(Rect.fromLTWH(8, 8, size - 16.0, size - 16.0));
        canvas.clipPath(clipPath);
        
        // Draw the image onto the canvas
        canvas.drawImage(image, const Offset(8, 8), Paint());
      } catch (e) {
        debugPrint("❌ Failed to load profile image for marker: $e");
        // It will show the solid purple circle if the image fails!
      }
    }

    // 3. Convert the canvas drawing into a Google Maps Marker
    final ui.Image markerAsImage = await pictureRecorder.endRecording().toImage(size, size);
    final ByteData? byteData = await markerAsImage.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
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
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: GoogleMap(
              initialCameraPosition: _initialLocation,
              zoomControlsEnabled: false, 
              myLocationButtonEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
              },
              markers: _userMarkers.union(_placeMarkers),
              circles: _placeCircles,
            ),
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
              SliverAppBar(
                pinned: true,
                backgroundColor: Colors.white,
                elevation: 0,
                automaticallyImplyLeading: false,
                toolbarHeight: 0, 
                bottom: PreferredSize(
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
                          color: AppColors.primaryLight.withOpacity(0.1), 
                          borderRadius: BorderRadius.circular(30), 
                        ),
                        child: TabBar(
                          controller: _tabController,
                          dividerColor: Colors.transparent, 
                          dividerHeight: 0, 
                          indicatorSize: TabBarIndicatorSize.tab,
                          indicator: BoxDecoration(
                            color: AppColors.primaryLight.withOpacity(0.3), 
                            borderRadius: BorderRadius.circular(30), 
                          ),
                          tabs: const [
                            Tab(icon: Icon(Icons.people_alt, color: AppColors.primaryDark)),
                            Tab(icon: Icon(Icons.domain, color: AppColors.primaryDark)),
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
            final user = _liveUsers[index];
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                       CircleAvatar(
                          radius: 35, 
                          backgroundColor: AppColors.primaryDark, 
                          backgroundImage: user["profileImageUrl"] != null ? NetworkImage(user["profileImageUrl"]) : null,
                          child: user["profileImageUrl"] == null 
                            ? Text(user["name"][0].toUpperCase(), style: GoogleFonts.poppins(color: Colors.white, fontSize: 24))
                            : null,
                        ),
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
                          Row(children: [const Icon(Icons.directions_walk, size: 16, color: AppColors.primaryLight), const SizedBox(width: 5), Text(user["steps"], style: GoogleFonts.poppins(fontSize: 12))]),
                          Row(children: [const Icon(Icons.directions_car, size: 16, color: AppColors.primaryLight), const SizedBox(width: 5), Text(user["dist"], style: GoogleFonts.poppins(fontSize: 12))]),
                          Row(children: [const Icon(Icons.wifi, size: 16, color: Colors.green), const SizedBox(width: 5), Text("Connected • ${user["battery"]}%", style: GoogleFonts.poppins(fontSize: 12, color: Colors.green))]),
                        ],
                      ),
                    ),
                  ],
                ),
                if (index < _liveUsers.length - 1) Divider(color: Colors.grey[200], height: 30),
              ],
            );
          },
          childCount: _liveUsers.length,
        ),
      ),
    );
  }

Widget _buildPlacesSliverList() {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      sliver: SliverList(
        delegate: SliverChildListDelegate([
          
          // 1. THE DYNAMIC PLACES LIST
          ..._savedPlaces.map((place) {
            return Column(
              children: [
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.primaryLight, 
                    child: Icon(Icons.location_on, color: Colors.white, size: 20)
                  ),
                  title: Text(place['name'] ?? "Saved Place", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Text("Geofence Active", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey)),
                  trailing: IconButton(
                    icon: Icon(
                      place['alerts_enabled'] == true ? Icons.notifications_active : Icons.notifications_off, 
                      color: place['alerts_enabled'] == true ? AppColors.primaryDark : Colors.grey,
                      size: 20
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Alerts toggled for ${place['name']}")),
                      );
                    },
                  ),
                  onTap: () {
                    // Fly the map camera to this saved place when tapped!
                    if (_mapController != null && place['latitude'] != null && place['longitude'] != null) {
                      _mapController!.animateCamera(
                        CameraUpdate.newLatLngZoom(LatLng(place['latitude'], place['longitude']), 16.0)
                      );
                    }
                  },
                ),
                Divider(color: Colors.grey[200], height: 20),
              ],
            );
          }).toList(), 

          // 2. THE "ADD NEW PLACE" BUTTON
          ListTile(
            leading: const CircleAvatar(backgroundColor: Colors.grey, child: Icon(Icons.add, color: Colors.white)),
            title: Text("Add a new Place", style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            onTap: () async {
              final didAddPlace = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddPlaceScreen()),
              );
              
              if (didAddPlace == true) {
                _fetchSavedPlaces(); // Refresh the list automatically!
              }
            },
          ),
          const SizedBox(height: 30), 
        ]),
      ),
    );
  }
}
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