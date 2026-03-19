import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:user_mobile/core/constants/api_constants.dart';

class PairingApiService {

  Future<String?> generatePairingCode() async {
    try {
      // 1. Get the logged-in user and their security badge
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final token = await user.getIdToken();
      final url = Uri.parse('${ApiConstants.baseUrl}/generate-code');

      debugPrint("🔄 Requesting pairing code from backend...");

      // 2. Knock on the backend's door
      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      // 3. Read the code from the response
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final String code = data['pairing_code'];
        debugPrint("✅ Pairing code generated: $code");
        return code;
      } else {
        debugPrint("❌ Failed to generate code: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Network error generating code: $e");
      return null;
    }
  }
  Future<bool> linkCaregiver(String code) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final token = await user.getIdToken();
      final url = Uri.parse('${ApiConstants.baseUrl}/link-caregiver');

      debugPrint("🔄 Sending pairing code: $code");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({"code": code.toUpperCase()}), 
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Successfully linked caregiver to patient!");
        return true;
      } else {
        debugPrint("❌ Failed to link: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Network error linking caregiver: $e");
      return false;
    }
  }
  Future<List<Map<String, dynamic>>> getLinkedUsers() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final token = await user.getIdToken();
      final url = Uri.parse('${ApiConstants.baseUrl}/linked-users');

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Convert the JSON list into a Dart List of Maps
        return List<Map<String, dynamic>>.from(data['linked_users']);
      } else {
        debugPrint("❌ Failed to fetch users: ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ Network error fetching users: $e");
      return [];
    }
  }
  Future<bool> unlinkUser(String targetUid) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final token = await user.getIdToken();
      final url = Uri.parse('${ApiConstants.baseUrl}/unlink-user');

      debugPrint("🔄 Requesting to unlink user: $targetUid");

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({"target_uid": targetUid}),
      );

      if (response.statusCode == 200) {
        debugPrint("✅ Successfully unlinked user!");
        return true;
      } else {
        debugPrint("❌ Failed to unlink: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Network error unlinking user: $e");
      return false;
    }
  }
  Future<Map<String, dynamic>?> getUserLocation(String targetUid) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      final token = await user.getIdToken();
      // Uses the ApiConstants we set up earlier!
      final url = Uri.parse('${ApiConstants.baseUrl}/get-location/$targetUid');

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['location']; // Returns {latitude: X, longitude: Y, updated_at: Z}
      } else {
        debugPrint("❌ Failed to fetch location: ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Network error fetching location: $e");
      return null;
    }
  }

  Future<bool> updateLocation(double lat, double lng) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final token = await user.getIdToken();
      final url = Uri.parse('${ApiConstants.baseUrl}/update-location');

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "latitude": lat,
          "longitude": lng,
        }),
      );

      if (response.statusCode == 200) {
        debugPrint("📍 Location successfully updated in backend!");
        return true;
      } else {
        debugPrint("❌ Failed to update location: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Network error updating location: $e");
      return false;
    }
  }
  // --- TO SAVE A NEW GEOFENCE PLACE ---
  Future<bool> addSavedPlace(String name, double lat, double lng) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;

      final token = await user.getIdToken();
      final url = Uri.parse('${ApiConstants.baseUrl}/add-saved-place');

      final response = await http.post(
        url,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode({
          "name": name,
          "latitude": lat,
          "longitude": lng,
        }),
      );

      if (response.statusCode == 201) {
        debugPrint("✅ Place saved successfully!");
        return true;
      } else {
        debugPrint("❌ Failed to save place: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("❌ Network error saving place: $e");
      return false;
    }
  }
  Future<List<Map<String, dynamic>>> getSavedPlaces() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return [];

      final token = await user.getIdToken();
      final url = Uri.parse('${ApiConstants.baseUrl}/get-saved-places');

      final response = await http.get(
        url,
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Convert the JSON list into a Dart List of Maps
        return List<Map<String, dynamic>>.from(data['places']);
      } else {
        debugPrint("❌ Failed to fetch places: ${response.body}");
        return [];
      }
    } catch (e) {
      debugPrint("❌ Network error fetching places: $e");
      return [];
    }
  }
}