import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class PushNotificationService {
  // Generates an access token using the service account JSON
  static Future<String> _getAccessToken() async {
    final jsonString = await rootBundle.loadString('assets/service-account.json');
    final accountCredentials = ServiceAccountCredentials.fromJson(jsonString);
    final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
    final client = await clientViaServiceAccount(accountCredentials, scopes);
    return client.credentials.accessToken.data;
  }

  // Sends the push notification to a specific FCM token
  static Future<void> sendNotification({
    required String receiverFcmToken,
    required String title,
    required String body,
    required String chatId,
    required String senderId,
  }) async {
    // TODO: Replace with your actual Firebase Project ID
    const String projectId = "my-chat-app-one-way";
    final String endpoint = "https://fcm.googleapis.com/v1/projects/$projectId/messages:send";

    try {
      final token = await _getAccessToken();
      
      final Map<String, dynamic> message = {
        "message": {
          "token": receiverFcmToken,
          "notification": {
            "title": title,
            "body": body,
          },
          "data": {
            "click_action": "FLUTTER_NOTIFICATION_CLICK",
            "chatId": chatId,
            "senderId": senderId,
            "chatName": title,
          }
        }
      };

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print("Notification Sent Successfully!");
      } else {
        print("Failed to send notification: ${response.body}");
      }
    } catch (e) {
      print("Error sending push notification: $e");
    }
  }
}