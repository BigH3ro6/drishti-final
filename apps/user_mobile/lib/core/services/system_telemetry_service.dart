import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SystemTelemetryService {
  final Battery _battery = Battery();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Timer? _telemetryTimer;

  // Starts the background loop when the dashboard opens
  void startTelemetry() {
    // 1. Run immediately once on startup
    _pushTelemetryData();
    
    // 2. Then run automatically every 3 minutes
    _telemetryTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      _pushTelemetryData();
    });
  }

  // Stops the loop when the app closes
  void stopTelemetry() {
    _telemetryTimer?.cancel();
    _setOfflineStatus(); 
  }

  Future<void> _pushTelemetryData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // 1. Get current Battery Level ONLY (Leave GPS to LiveLocationService!)
      final batteryLevel = await _battery.batteryLevel;

      // 2. Prepare the data payload
      Map<String, dynamic> telemetryData = {
        "battery_level": batteryLevel,
        "is_online": true,
        "last_active": FieldValue.serverTimestamp(),
      };

      // 3. Smart Status Logic
      if (batteryLevel <= 15) {
        telemetryData["status"] = "Low Battery";
      } else {
        telemetryData["status"] = "Safe"; 
      }

      // 4. Push directly to Firestore!
      await _firestore.collection('users').doc(user.uid).update(telemetryData);
      debugPrint("🔋 Battery telemetry pushed successfully!");

    } catch (e) {
      debugPrint("Error pushing telemetry: $e");
    }
  }

  // Marks the user as offline if they close the app
  Future<void> _setOfflineStatus() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          "is_online": false,
          "status": "Offline",
          "last_active": FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("Error setting offline: $e");
    }
  }
}