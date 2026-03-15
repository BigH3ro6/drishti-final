import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'dart:convert';

class WeatherApiService {
  static const String backendUrl = 'http://192.168.1.7:5000';

  Future<String> fetchCurrentWeather() async {
    try {
      // 1. Check if GPS is turned on and permitted
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return "Location services are disabled on your phone.";

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return "I need location permissions to check the weather.";
      }

      // 2. Grab the exact GPS coordinates
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );

      debugPrint("Location grabbed: ${position.latitude}, ${position.longitude}");

      // 3. Call your backend API endpoint
      final url = Uri.parse('$backendUrl/api/weather?lat=${position.latitude}&lng=${position.longitude}');
      final response = await http.get(url);

      // 4. Return the TTS string to the app
      if (response.statusCode == 200) {
        // 1. Convert the raw text string into a readable Dart Map
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        
        // Let's print the exact response so you can see it in your terminal!
        debugPrint("Backend Weather Response: $jsonResponse");

        // 2. Extract just the text sentence. 
        String spokenWeather = jsonResponse['message'] 
            ?? jsonResponse['weather'] 
            ?? jsonResponse['text'] 
            ?? jsonResponse['tts_string']
            ?? "The weather data arrived, but I couldn't read the exact format.";
        return spokenWeather; 
      } else {
        return "The weather server responded with an error.";
      }
    } catch (e) {
      debugPrint("Weather API Error: $e");
      return "I couldn't connect to the weather server right now.";
    }
  }
}