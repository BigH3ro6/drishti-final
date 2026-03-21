import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:user_mobile/core/constants/api_constants.dart';

class VoiceApiService {
  // 1. Fetch chat history
  Future<List<Map<String, dynamic>>> getVoiceMessages(String chatId) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/voice/messages?chat_id=$chatId');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['messages']);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // 2. Upload the recorded audio file
  Future<bool> sendVoiceMessage({
    required String audioFilePath,
    required String senderId,
    required String receiverId,
    required String chatId,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/api/voice/upload'),
      );

      // Attach the required text fields from your utility_routes.py
      request.fields['sender_id'] = senderId;
      request.fields['receiver_id'] = receiverId;
      request.fields['chat_id'] = chatId;

      // Attach the audio file
      request.files.add(await http.MultipartFile.fromPath('audio', audioFilePath));

      var streamedResponse = await request.send();
      return streamedResponse.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
  // 3. Delete a message from the server
  Future<bool> deleteVoiceMessage(String messageId) async {
    try {
      final url = Uri.parse('${ApiConstants.baseUrl}/api/voice/messages/$messageId');
      final response = await http.delete(url);

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
