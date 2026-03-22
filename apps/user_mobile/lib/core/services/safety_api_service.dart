import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:user_mobile/core/constants/api_constants.dart';
import 'package:flutter/material.dart';

class SafetyApiService {
  Future<bool> triggerSOS(double lat, double lng) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/safety/sos'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': user.uid,
          'latitude': lat,
          'longitude': lng,
        }),
      );

      if (response.statusCode == 201) {
        debugPrint("✅ SOS Triggered Successfully!");
        return true;
      }
      return false;
    } catch (e) {
      debugPrint("❌ SOS Trigger Failed: $e");
      return false;
    }
  }
}