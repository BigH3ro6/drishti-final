import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:user_mobile/core/services/pairing_api_service.dart';

class LiveLocationService {
  Timer? _timer;
  final PairingApiService _apiService = PairingApiService();

  // Call this when the visually impaired user logs in or opens their dashboard
  Future<void> startTracking() async {
    // 1. Check if GPS is turned on
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      debugPrint("❌ Location services are disabled.");
      return;
    }

    // 2. Ask the user for permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint("❌ Location permissions are denied.");
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      debugPrint("❌ Location permissions are permanently denied.");
      return;
    }

    debugPrint("✅ GPS Permissions granted. Starting live tracking...");

    // 3. Send the first location update immediately
    _sendLocationToBackend();

    // 4. Start a repeating timer to send updates every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _sendLocationToBackend();
    });
  }

  Future<void> _sendLocationToBackend() async {
    try {
      // Grab the GPS coordinates
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      // Shoot them to the Python backend!
      await _apiService.updateLocation(position.latitude, position.longitude);
      
    } catch (e) {
      debugPrint("❌ Error grabbing location: $e");
    }
  }

  // Call this if the user logs out
  void stopTracking() {
    _timer?.cancel();
    _timer = null;
    debugPrint("🛑 Stopped live location tracking.");
  }
}