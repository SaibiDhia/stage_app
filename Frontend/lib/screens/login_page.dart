import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; // pour kIsWeb
import 'package:http/http.dart' as http;
import 'package:pfeproject/screens/admin/web/admin_document_web_page.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pfeproject/screens/home_page.dart';
import 'package:pfeproject/screens/admin/admin_document_page.dart';
import 'package:pfeproject/screens/dashboard_student.dart';

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
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs.')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final String baseUrl =
          kIsWeb ? 'http://192.168.0.127:8081' : 'http://10.0.2.2:8081';

      final Uri url = Uri.parse('$baseUrl/api/auth/login');
      print('🔁 Sending request to: $url');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      print('✅ Status Code: ${response.statusCode}');
      print('✅ Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final token = data['token'];
        final role = data['role'];
        final userId = data['id'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('role', role);
        await prefs.setInt('userId', userId);

        // Navigation selon rôle
        if (role == 'ETUDIANT') {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const DashboardStudent()),
          );
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => kIsWeb
                  ? const AdminDocumentWebPage()
                  : const AdminDocumentPage(),
            ),
          );
        }
        print('📦 Données sauvegardées :');
        print('Token : $token');
        print('Role : $role');
        print('UserId : $userId');

        final checkPrefs = await SharedPreferences.getInstance();
        print('🔍 Check SharedPreferences après sauvegarde :');
        print('token = ${checkPrefs.getString('token')}');
        print('userId = ${checkPrefs.getInt('userId')}');
      } else if (response.statusCode == 401) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Identifiants invalides.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Erreur ${response.statusCode} : ${response.body}')),
        );
      }
    } catch (e) {
      print('❌ Exception: $e');
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
    super.dispose();
  }

  // --------------- PARTIE UI ---------------

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return _buildWebLogin(context);
    } else {
      return _buildMobileLogin(context);
    }
  }

  Widget _buildWebLogin(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F8),
      body: Center(
        child: SingleChildScrollView(
          child: Card(
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            child: Container(
              width: 410,
              padding: const EdgeInsets.all(36),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_circle,
                      size: 64, color: Colors.indigo),
                  const SizedBox(height: 18),
                  const Text("Connexion",
                      style:
                          TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Mot de passe',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    autofillHints: const [AutofillHints.password],
                  ),
                  const SizedBox(height: 30),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              backgroundColor:
                                  const Color.fromARGB(255, 255, 255, 255),
                            ),
                            onPressed: _login,
                            child: const Text('Se connecter',
                                style: TextStyle(fontSize: 17)),
                          ),
                        ),
                  const SizedBox(height: 18),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/register');
                    },
                    child: const Text(
                      "Pas encore inscrit ? Créez un compte",
                      style: TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLogin(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_circle,
                    size: 55, color: Colors.indigo),
                const SizedBox(height: 12),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
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
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _login,
                          child: const Text('Se connecter'),
                        ),
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
        ),
      ),
    );
  }
}
