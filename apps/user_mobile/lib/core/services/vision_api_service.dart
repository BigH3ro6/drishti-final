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
  Future<String?> describeSurroundings(String imagePath) async {
    try {
      // 1. Create a Multipart Request (File Upload) instead of JSON
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/api/vision/detect'),
      );

      // 2. Attach the raw image file to the request
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      // 3. Send it to your Flask Backend!
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final mlData = jsonResponse['data'];
        
        if (mlData != null) {
          // 1. Check if the AI returned the "detections" list
          if (mlData['detections'] != null && mlData['detections'] is List) {
            List<dynamic> detections = mlData['detections'];

            if (detections.isEmpty) {
              return "I analyzed the scene, but didn't detect any specific objects.";
            }

            // 2. Extract all the object names (e.g., "person", "car")
            List<String> objectsFound = [];
            for (var item in detections) {
              if (item['class'] != null) {
                objectsFound.add(item['class'].toString());
              }
            }

            // 3. Remove duplicates so it doesn't say "person, person, person"
            List<String> uniqueObjects = objectsFound.toSet().toList();

            // 4. Build a natural-sounding English sentence!
            if (uniqueObjects.isEmpty) {
              return "I couldn't identify the objects in this scene.";
            } else if (uniqueObjects.length == 1) {
              return "I see a ${uniqueObjects.first}.";
            } else if (uniqueObjects.length == 2) {
              return "I see a ${uniqueObjects[0]} and a ${uniqueObjects[1]}.";
            } else {
              String lastObject = uniqueObjects.removeLast();
              return "I see a ${uniqueObjects.join(', a ')}, and a $lastObject.";
            }
          }
          
          return "Scene analyzed, but I couldn't format the object list.";
        }
        return "I couldn't process the scene data.";
      } else {
        debugPrint("❌ Detection Error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Detection Exception: $e");
      return null;
    }
  }
  Future<String?> recognizeCurrency(String imagePath) async {
    try {
      // 1. Create a Multipart Request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/api/vision/detect-currency'),
      );

      // 2. Attach the raw image file
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));

      // 3. Send it to your Flask Backend
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        // 4. Parse the ML developer's JSON format
        if (jsonResponse['success'] == true) {
           return jsonResponse['currency'];
        } else {
           return "I couldn't recognize the currency.";
        }
      } else {
        debugPrint("❌ Currency Detection Error: ${response.statusCode} - ${response.body}");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Currency Detection Exception: $e");
      return null;
    }
  }
}