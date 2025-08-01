import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/enregistrer_fichier_universel.dart';

class DeposerConventionSigneePage extends StatefulWidget {
  const DeposerConventionSigneePage({super.key});

  @override
  State<DeposerConventionSigneePage> createState() =>
      _DeposerConventionSigneePageState();
}

class _DeposerConventionSigneePageState
    extends State<DeposerConventionSigneePage> {
  bool isUploading = false;
  bool isDownloading = false;
  String? message;
  int? conventionId;
  String? statut;
  PlatformFile? selectedFile;

  @override
  void initState() {
    super.initState();
    _fetchDerniereConvention();
  }

  Future<void> _fetchDerniereConvention() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    final response = await http.get(
      Uri.parse("http://10.0.2.2:8081/api/convention/ma-convention"),
      headers: {"Authorization": "Bearer $token"},
    );

    if (response.statusCode == 200 && response.body != "null") {
      final data = json.decode(response.body);
      setState(() {
        conventionId = data['id'];
        statut = data['statut'];
      });
    } else {
      setState(() {
        message = "Aucune convention trouvée.";
      });
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false, // ← important ici
    );
    if (result != null) {
      setState(() {
        selectedFile = result.files.first;
        message = "📄 Fichier sélectionné : ${selectedFile!.name}";
      });
    }
  }

  Future<void> _uploadConventionSignee() async {
    if (selectedFile == null) return;

    setState(() {
      isUploading = true;
      message = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (conventionId == null || token == null) {
      setState(() {
        isUploading = false;
        message = "❌ Impossible de récupérer la convention ou l'utilisateur.";
      });
      return;
    }
    print("TOKEN : $token");

    final uri = Uri.parse(
        'http://10.0.2.2:8081/api/convention/$conventionId/upload-signee');
    final request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $token'
      ..files.add(await http.MultipartFile.fromPath(
        'file',
        selectedFile!.path!,
        filename: selectedFile!.name,
      ));

    final response = await request.send();

    setState(() {
      isUploading = false;
    });

    if (response.statusCode == 200) {
      setState(() {
        message = '✅ Convention signée déposée.';
        statut = "SIGNEE_EN_ATTENTE_VALIDATION";
        selectedFile = null;
      });
      _fetchDerniereConvention();
    } else {
      setState(() {
        message = '❌ Échec du dépôt (${response.statusCode})';
      });
    }
  }

  Future<void> _downloadConventionAdmin() async {
    if (conventionId == null) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    setState(() => isDownloading = true);

    final response = await http.get(
      Uri.parse(
          'http://10.0.2.2:8081/api/convention/$conventionId/download-admin'),
      headers: {"Authorization": "Bearer $token"},
    );

    setState(() => isDownloading = false);

    if (response.statusCode == 200) {
      final bytes = response.bodyBytes;
      final saved = await enregistrerFichierUniversel(
        bytes: bytes,
        nomFichier: "convention_admin_$conventionId.pdf",
      );
      setState(() => message = saved != null && saved.isNotEmpty
          ? "✅ Fichier téléchargé dans : $saved"
          : "❌ Échec du téléchargement.");
    } else {
      setState(() => message = "⚠️ Fichier introuvable.");
    }
  }

  bool get peutUploader {
    return statut == "VALIDEE" || statut == "SIGNEE_REJETEE";
  }

  Widget _buildStatusBox(Color bg, IconData icon, Color iconColor, String msg) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
              child: Text(msg, style: const TextStyle(color: Colors.black87)))
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Convention Signée")),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("📄 Télécharger la convention validée"),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: isDownloading ? null : _downloadConventionAdmin,
              icon: const Icon(Icons.download),
              label: const Text("Télécharger"),
            ),
            const Divider(height: 30),
            const Text("📤 Déposer la convention signée"),
            const SizedBox(height: 10),
            if (statut == "SIGNEE_EN_ATTENTE_VALIDATION")
              _buildStatusBox(
                Colors.orange[100]!,
                Icons.hourglass_top,
                Colors.orange,
                "🕒 En attente de validation par l'administration.",
              ),
            if (statut == "SIGNEE_REJETEE")
              _buildStatusBox(
                Colors.red[100]!,
                Icons.cancel,
                Colors.red,
                "❌ Convention rejetée. Veuillez renvoyer.",
              ),
            if (statut == "SIGNEE_VALIDEE")
              _buildStatusBox(
                Colors.green[100]!,
                Icons.check_circle,
                Colors.green,
                "🎉 Convention signée validée ! Livrables accessibles.",
              ),
            ElevatedButton.icon(
              onPressed: !peutUploader || isUploading ? null : _pickFile,
              icon: const Icon(Icons.attach_file),
              label: const Text("Choisir un fichier"),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: !peutUploader || isUploading || selectedFile == null
                  ? null
                  : _uploadConventionSignee,
              icon: const Icon(Icons.upload_file),
              label: const Text("Confirmer l'envoi"),
            ),
            const SizedBox(height: 20),
            if (message != null)
              Text(message!, style: const TextStyle(color: Colors.green)),
            if (statut != null)
              Text("📌 Statut actuel : $statut",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
