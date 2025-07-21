import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // kIsWeb
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pfeproject/screens/login_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  String? _selectedRole;
  final List<String> _roles = ['ETUDIANT', 'ADMIN'];

  bool _isLoading = false;

  Future<void> _register() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final name = _nameController.text.trim();

    if (email.isEmpty ||
        password.isEmpty ||
        name.isEmpty ||
        _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final baseUrl =
          kIsWeb ? 'http://192.168.0.127:8081' : 'http://10.0.2.2:8081';

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'fullName': name,
          'role': _selectedRole,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('✅ Inscription réussie. Connectez-vous.')),
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur ${response.statusCode} : ${response.body}'),
          ),
        );
      }
    } catch (e) {
      print("❌ Exception: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return kIsWeb ? _buildWebUI(context) : _buildMobileUI(context);
  }

  Widget _buildWebUI(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F8),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Container(
              width: 450,
              padding: const EdgeInsets.all(36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.app_registration,
                      size: 64, color: Colors.deepPurple),
                  const SizedBox(height: 20),
                  const Text("Créer un compte",
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  _buildFormFields(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileUI(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inscription")),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: _buildFormFields(),
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nom complet',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 18),
        TextField(
          controller: _passwordController,
          decoration: const InputDecoration(
            labelText: 'Mot de passe',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
          obscureText: true,
        ),
        const SizedBox(height: 18),
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Rôle',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.admin_panel_settings),
          ),
          value: _selectedRole,
          items: _roles
              .map((role) => DropdownMenuItem(
                    value: role,
                    child: Text(role == 'ETUDIANT' ? 'Étudiant' : 'Admin'),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedRole = value;
            });
          },
        ),
        const SizedBox(height: 30),
        _isLoading
            ? const CircularProgressIndicator()
            : SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _register,
                  child:
                      const Text("S'inscrire", style: TextStyle(fontSize: 17)),
                ),
              ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          },
          child: const Text("Déjà inscrit ? Connectez-vous"),
        ),
      ],
    );
  }
}
