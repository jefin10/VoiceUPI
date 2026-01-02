import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class RasaService {
  /// Send message to Rasa for casual conversation
  /// Returns the chatbot's response
  static Future<Map<String, dynamic>> sendMessage(String message) async {
    try {
      print('Sending message to Rasa: $message');

      final response = await http.post(
        Uri.parse(RASA_CHAT_URL),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender': 'user',
          'message': message,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> rasaResponses = jsonDecode(response.body);
        
        if (rasaResponses.isNotEmpty) {
          // Rasa returns array of responses, get the first text response
          final firstResponse = rasaResponses[0];
          final text = firstResponse['text'] ?? 'I\'m here to help!';
          
          print('Rasa response: $text');
          
          return {
            'status': 'success',
            'message': text,
            'action': 'chatbot',
            'source': 'rasa',
          };
        } else {
          return {
            'status': 'success',
            'message': 'I\'m here to help you with your UPI transactions!',
            'action': 'chatbot',
            'source': 'rasa',
          };
        }
      } else {
        print('Rasa error: ${response.statusCode} - ${response.body}');
        return {
          'status': 'error',
          'message': 'Sorry, I couldn\'t process that. Please try again.',
          'action': 'chatbot',
        };
      }
    } catch (e) {
      print('Rasa network error: $e');
      return {
        'status': 'error',
        'message': 'Network error. Please check your connection.',
        'action': 'chatbot',
      };
    }
  }

  /// Check if Rasa server is healthy
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$RASA_BASE_URL/'),
        headers: {'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Rasa health check failed: $e');
      return false;
    }
  }
}
