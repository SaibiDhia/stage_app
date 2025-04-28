// lib/services/auth_service.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
