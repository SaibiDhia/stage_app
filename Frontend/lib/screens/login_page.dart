import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pfeproject/screens/home_page.dart';
import 'package:pfeproject/screens/dashboard_student.dart';
import 'package:pfeproject/services/auth_service.dart'; // Pour handleUnauthorized

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('http://10.0.2.2:8081/api/auth/login');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': _emailController.text,
        'password': _passwordController.text,
      }),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      final role = data['role'];
      final userId = data['id'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('role', role);
      await prefs.setInt('userId', userId);

      if (role == 'ETUDIANT') {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const DashboardStudent()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomePage(role: role)),
        );
      }
    } else if (response.statusCode == 401) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Identifiants invalides.')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur serveur. Veuillez réessayer.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(labelText: 'Mot de passe'),
              obscureText: true,
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    child: const Text('Se connecter'),
                  ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/register');
              },
              child: const Text("Pas encore inscrit ? Créez un compte"),
            ),
          ],
        ),
      ),
    );
  }
}
