// lib/services/api_service.dart
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'auth_service.dart';

class ApiService {
  static const String baseUrl = 'http://10.0.2.2:8081/api';

  static Future<http.Response?> post(
    BuildContext context,
    String endpoint,
    Map<String, dynamic> data,
  ) async {
    try {
      var response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (response.statusCode == 401) {
        await handleUnauthorized(context);
        return null;
      }

      return response;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur réseau: $e')),
      );
      return null;
    }
  }
}
