import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pfeproject/screens/login_page.dart';

class HomePage extends StatelessWidget {
  final String role;

  const HomePage({Key? key, required this.role}) : super(key: key);

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Supprimer toutes les données sauvegardées
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
          builder: (context) => LoginPage()), // Retourne vers login
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Page d\'accueil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                _logout(context), // Appelle la fonction de déconnexion
          )
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Bienvenue 🎉', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 16),
            Text('Votre rôle : $role', style: const TextStyle(fontSize: 20)),
          ],
        ),
      ),
    );
  }
}
