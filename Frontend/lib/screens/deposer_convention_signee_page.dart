import 'dart:html' as html; // pour download Web (optionnel)
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeposerConventionSigneePage extends StatefulWidget {
  const DeposerConventionSigneePage({super.key});

  @override
  State<DeposerConventionSigneePage> createState() => _DeposerConventionSigneePageState();
}

class _DeposerConventionSigneePageState extends State<DeposerConventionSigneePage> {
  bool isUploading = false;
  bool isDownloading = false;
  String? statut;
  String? message;

  @override
  void initState() {
    super.initState();
    _fetchStatutConvention();
  }

  Future<void> _fetchStatutConvention() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("userId");
    final token = prefs.getString("token");

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8081/api/convention/by-user/$userId'),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200) {
      final convention = response.body; // à adapter selon structure
      setState(() {
        statut = convention.contains("SIGNEE") ? "Validée" : "En attente";
      });
    }
  }

  Future<void> _uploadConventionSignee() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("userId");
    final token = prefs.getString("token");

    final result = await FilePicker.platform.pickFiles();
    if (result == null) return;

    final file = result.files.first;
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://10.0.2.2:8081/api/convention/$userId/upload-signee'),
    );

    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        file.bytes!,
        filename: file.name,
      ),
    );

    setState(() => isUploading = true);

    final response = await request.send();
    setState(() => isUploading = false);

    if (response.statusCode == 200) {
      setState(() => message = "✅ Convention signée déposée !");
    } else {
      setState(() => message = "❌ Erreur : dépôt échoué.");
    }
  }

  Future<void> _downloadConventionAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt("userId");
    final token = prefs.getString("token");

    setState(() => isDownloading = true);

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8081/api/convention/$userId/download-admin'),
      headers: {"Authorization": "Bearer $token"},
    );

    setState(() => isDownloading = false);

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;

      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..target = 'blank'
        ..download = "convention_admin.pdf"
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      setState(() => message = "⚠️ Aucun fichier trouvé");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Convention Signée")),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          children: [
            const Text("1️⃣ Télécharger la convention validée par l'admin"),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: isDownloading ? null : _downloadConventionAdmin,
              icon: const Icon(Icons.download),
              label: const Text("Télécharger la convention"),
            ),
            const Divider(height: 30),
            const Text("2️⃣ Uploader la version signée"),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: isUploading ? null : _uploadConventionSignee,
              icon: const Icon(Icons.upload_file),
              label: const Text("Déposer Convention Signée"),
            ),
            const SizedBox(height: 20),
            if (message != null) Text(message!, style: const TextStyle(color: Colors.green)),
            const SizedBox(height: 20),
            if (statut != null)
              Text("Statut actuel : $statut", style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
