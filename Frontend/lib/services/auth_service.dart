// lib/services/auth_service.dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;

Future<void> handleUnauthorized(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();

  // Supprimer le token
  await prefs.remove('token');

  // Message optionnel
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Session expirée. Veuillez vous reconnecter.')),
  );

  // Redirection vers login
  Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
}

Future<void> registerFcmToken({
  required int userId,
  required String jwt,
}) async {
  // Request permission (Android/iOS). On web, skip the Platform call.
  if (!kIsWeb && Platform.isAndroid) {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  } else if (kIsWeb) {
    // Web: you can still call requestPermission safely if you want
    await FirebaseMessaging.instance.requestPermission();
  }

  final token = await FirebaseMessaging.instance.getToken();
  if (token == null) return;

  final baseUrl = kIsWeb ? 'http://192.168.0.127:8081' : 'http://10.0.2.2:8081';
  final resp = await http.post(
    Uri.parse('$baseUrl/api/users/$userId/fcm-token'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $jwt',
    },
    body: '{"token":"$token"}',
  );
  print('FCM token saved: ${resp.statusCode} ${resp.body}');
}
