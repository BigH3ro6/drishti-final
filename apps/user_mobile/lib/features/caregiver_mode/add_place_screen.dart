import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:user_mobile/core/app_colors.dart';
import 'package:user_mobile/core/services/pairing_api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

class AddPlaceScreen extends StatefulWidget {
  const AddPlaceScreen({super.key});

  @override
  State<AddPlaceScreen> createState() => _AddPlaceScreenState();
}

class _AddPlaceScreenState extends State<AddPlaceScreen> {
  final PairingApiService _apiService = PairingApiService();
  
  // --- SAFELY GRABBING  API KEY ---
  final String _googleApiKey = dotenv.env['GOOGLE_MAPS_API_KEY'] ?? ''; 
  
  // Controllers
  final TextEditingController _searchController = TextEditingController(); 
  final FocusNode _searchFocusNode = FocusNode();
  final TextEditingController _nameController = TextEditingController();   
  GoogleMapController? _mapController;
  
  LatLng? _selectedLocation;
  bool _isSaving = false;
  bool _isSearching = false;

  // Autocomplete Variables
  Timer? _debounce;
  List<dynamic> _placeList = [];

  final CameraPosition _initialLocation = const CameraPosition(
    target: LatLng(6.9271, 79.8612), 
    zoom: 14.0,
  );

  @override
  void initState() {
    super.initState();
    // This tells the app to redraw the screen when the search bar is tapped!
    _searchFocusNode.addListener(() {
      setState(() {}); 
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  // 1. TRIGGERED EVERY TIME THE USER TYPES A LETTER
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    
    if (query.isEmpty) {
      setState(() => _placeList = []);
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      _getSuggestions(query);
    });
  }

  // 2. FETCH PREDICTIONS FROM GOOGLE
  Future<void> _getSuggestions(String query) async {
    if (_googleApiKey.isEmpty) {
      debugPrint("❌ Missing API Key in .env file!");
      return;
    }

    String url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$_googleApiKey&components=country:lk";
    
    try {
      var response = await http.get(Uri.parse(url));
      var data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        setState(() {
          _placeList = data['predictions'];
        });
      }
    } catch (e) {
      debugPrint("❌ Autocomplete error: $e");
    }
  }

  // 3. FETCH EXACT COORDINATES WHEN THEY TAP A SUGGESTION
  Future<void> _getPlaceDetails(String placeId, String description) async {
    FocusScope.of(context).unfocus(); 
    setState(() {
      _isSearching = true;
      _placeList = []; 
      _searchController.text = description; 
      _nameController.text = description.split(',')[0]; 
    });

    String url = "https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_googleApiKey";
    
    try {
      var response = await http.get(Uri.parse(url));
      var data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        double lat = data['result']['geometry']['location']['lat'];
        double lng = data['result']['geometry']['location']['lng'];
        LatLng newTarget = LatLng(lat, lng);

        setState(() {
          _selectedLocation = newTarget;
          _isSearching = false;
        });

        _mapController?.animateCamera(CameraUpdate.newLatLngZoom(newTarget, 17.0));
      }
    } catch (e) {
      setState(() => _isSearching = false);
      debugPrint("❌ Place details error: $e");
    }
  }

  void _onMapTapped(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _placeList = []; 
      FocusScope.of(context).unfocus(); 
    });
  }

  Future<void> _savePlace() async {
    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please search or tap the map to drop a pin first!"), backgroundColor: Colors.orange),
      );
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a custom name for this place."), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);

    bool success = await _apiService.addSavedPlace(
      _nameController.text.trim(),
      _selectedLocation!.latitude,
      _selectedLocation!.longitude,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Place saved successfully!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true); 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save place."), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. The Interactive Map
          GoogleMap(
            initialCameraPosition: _initialLocation,
            onMapCreated: (controller) => _mapController = controller,
            onTap: _onMapTapped,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: _selectedLocation == null ? {} : {
              Marker(
                markerId: const MarkerId('selected_place'),
                position: _selectedLocation!,
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
              )
            },
          ),

          // 2. SEARCH BAR & DROPDOWN
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      InkWell(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)]),
                          child: TextField(
                            controller: _searchController,
                            focusNode: _searchFocusNode,
                            onChanged: _onSearchChanged, 
                            decoration: InputDecoration(
                              hintText: "Search location...",
                              hintStyle: GoogleFonts.poppins(color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                              suffixIcon: _isSearching 
                                ? const Padding(padding: EdgeInsets.all(12.0), child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.search, color: AppColors.purpleDark),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_placeList.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8, left: 60), 
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _placeList.length,
                        separatorBuilder: (context, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          return ListTile(
                            leading: const Icon(Icons.location_on, color: AppColors.purpleLight),
                            title: Text(
                              _placeList[index]['description'],
                              style: GoogleFonts.poppins(fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            onTap: () {
                              _getPlaceDetails(
                                _placeList[index]['place_id'],
                                _placeList[index]['description'],
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 3. The Floating Save Container (Bottom)
          if (!_searchFocusNode.hasFocus && _placeList.isEmpty)
          Positioned(
            bottom: 30, left: 20, right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 15, spreadRadius: 2)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Save Safe Zone", style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.purpleDark)),
                  const SizedBox(height: 5),
                  Text("Give this location a custom name.", style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey[600])),
                  const SizedBox(height: 15),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: "e.g., Campus, Hospital, Supermarket",
                      hintStyle: GoogleFonts.poppins(color: Colors.grey),
                      prefixIcon: const Icon(Icons.bookmark, color: AppColors.purpleLight),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purpleDark,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      ),
                      onPressed: _isSaving ? null : _savePlace,
                      child: _isSaving
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text("Save Place", style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}