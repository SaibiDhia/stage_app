// lib/screens/register_page.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:pfeproject/screens/login_page.dart';
import 'package:pfeproject/core/options_parcours.dart'; // <-- enum + labels

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // --- contrôleurs
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // --- états UI
  bool _isLoading = false;

  // --- rôles (avec ENCADRANT comme demandé)
  final List<String> _roles = ['ETUDIANT', 'ENCADRANT', 'ADMIN'];
  String? _selectedRole = 'ETUDIANT';

  // --- option/parcours (enum partagé avec le backend)
  OptionParcours? _selectedOption;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ========== API ==========
  Future<void> _register() async {
    final fullName = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // validations de base
    if (fullName.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        _selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez remplir tous les champs.")),
      );
      return;
    }

    // Si rôle ≠ ADMIN, on impose une option
    if (_selectedRole != 'ADMIN' && _selectedOption == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez choisir une option/parcours.")),
      );
      return;
    }

    // payload vers le backend (les noms doivent correspondre à RegisterRequest côté Spring)
    final body = <String, dynamic>{
      'fullName': fullName,
      'email': email,
      'password': password,
      'role': _selectedRole, // "ETUDIANT" | "ENCADRANT" | "ADMIN"
      if (_selectedOption != null)
        'optionParcours': _selectedOption!
            .name, // <-- mapping enum dart -> enum java (ex: ERP_BI)
    };

    setState(() => _isLoading = true);
    try {
      final baseUrl =
          kIsWeb ? 'http://192.168.0.127:8081' : 'http://10.0.2.2:8081';
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (res.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Inscription réussie")),
        );
        if (!mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ ${res.statusCode} : ${res.body}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Erreur: $e")),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ========== UI ==========
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
        // Nom
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: 'Nom complet',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
        ),
        const SizedBox(height: 18),

        // Email
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

        // Password
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

        // Rôle
        DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            labelText: 'Rôle',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.admin_panel_settings),
          ),
          value: _selectedRole,
          items: _roles
              .map((r) => DropdownMenuItem(
                    value: r,
                    child: Text(
                      r == 'ETUDIANT'
                          ? 'Étudiant'
                          : (r == 'ENCADRANT' ? 'Encadrant' : 'Admin'),
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            setState(() {
              _selectedRole = v;
              // si ADMIN, on efface l’option (colonne peut rester null côté backend)
              if (_selectedRole == 'ADMIN') {
                _selectedOption = null;
              }
            });
          },
        ),
        const SizedBox(height: 18),

        // Option/Parcours (masquée pour ADMIN)
        if (_selectedRole != 'ADMIN')
          DropdownButtonFormField<OptionParcours>(
            decoration: const InputDecoration(
              labelText: 'Option / Parcours',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.school),
            ),
            value: _selectedOption,
            items: OptionParcours.values
                .map(
                  (opt) => DropdownMenuItem<OptionParcours>(
                    value: opt,
                    child: Text(kOptionLabels[opt] ?? opt.name),
                  ),
                )
                .toList(),
            onChanged: (opt) => setState(() => _selectedOption = opt),
          ),

        const SizedBox(height: 30),

        // CTA
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
