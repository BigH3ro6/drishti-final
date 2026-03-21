import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:user_mobile/core/constants/api_constants.dart';
import 'package:flutter/material.dart';

class VisionApiService {
  Future<String?> readTextFromImage(String imagePath) async {
    try {
      // 1. Convert the image file to a Base64 string
      final bytes = await File(imagePath).readAsBytes();
      final String base64Image = base64Encode(bytes);

      // 2. Send it to Python backend
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/api/vision/read-text'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'image': base64Image,
        }),
      );

      // 3. Parse the result!
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text']; 
      } else {
        debugPrint("❌ OCR Error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ OCR Exception: $e");
      return null;
    }
  }
}