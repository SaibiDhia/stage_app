import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final String role;

  const HomePage({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Page d'accueil")),
      body: Center(
        child: Text(
          'Bienvenue 🎉\nVotre rôle : $role',
          style: const TextStyle(fontSize: 20),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
