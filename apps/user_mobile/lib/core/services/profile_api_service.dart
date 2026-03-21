import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:user_mobile/core/constants/api_constants.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileApiService {
  Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      // Get the secure token from Firebase Auth
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      
      final token = await user.getIdToken();

      // Call the Python /profile route
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', 
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  Future<bool> updateProfileDetails(String name, String phone, {String? medicalNotes}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      final token = await user.getIdToken();

      final response = await http.put(
        Uri.parse('${ApiConstants.baseUrl}/update-profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': name,
          'phone': phone,
          if (medicalNotes != null) 'medical_notes': medicalNotes,
        }),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<String?> uploadProfileImage(String imagePath) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      final token = await user.getIdToken();

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/upload-profile-image'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      var streamedResponse = await request.send();
      if (streamedResponse.statusCode == 200) {
        final responseData = await streamedResponse.stream.bytesToString();
        final json = jsonDecode(responseData);
        return json['profile_image_url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}