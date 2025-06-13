import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class DepotPage extends StatefulWidget {
  final String documentType;

  const DepotPage({super.key, required this.documentType});

  @override
  State<DepotPage> createState() => _DepotPageState();
}

class _DepotPageState extends State<DepotPage> {
  File? _selectedFile;
  bool _isUploading = false;
  String? _uploadMessage;
  String _statut = 'Chargement...';

  @override
  void initState() {
    super.initState();
    _fetchStatut();
  }

  Future<void> _fetchStatut() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    if (userId == null) {
      setState(() => _statut = 'Utilisateur non authentifié');
      return;
    }

    final uri = Uri.parse(
      'http://10.0.2.2:8081/api/documents/statut?userId=$userId&type=${Uri.encodeComponent(widget.documentType)}',
    );

    print(
        '🔎 STATUT URL: http://10.0.2.2:8081/api/documents/statut?userId=$userId&type=${widget.documentType}');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      setState(() => _statut = response.body.replaceAll('"', ''));
    } else {
      setState(() => _statut = 'Erreur lors du chargement du statut');
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _uploadMessage = null;
      });
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');

    if (userId == null) {
      setState(() {
        _isUploading = false;
        _uploadMessage = '❌ Utilisateur non authentifié';
      });
      return;
    }

    final uri = Uri.parse('http://10.0.2.2:8081/api/documents/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['type'] = widget.documentType
      ..fields['userId'] = userId.toString()
      ..files
          .add(await http.MultipartFile.fromPath('file', _selectedFile!.path));

    final response = await request.send();

    setState(() {
      _isUploading = false;
    });

    if (response.statusCode == 200) {
      setState(() {
        _uploadMessage = '✅ Document déposé avec succès';
        _selectedFile = null;
      });
      _fetchStatut();
    } else {
      setState(() {
        _uploadMessage = '❌ Échec du dépôt';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Déposer ${widget.documentType}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Statut : $_statut',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.attach_file),
              label: const Text('Sélectionner un fichier'),
            ),
            const SizedBox(height: 16),
            if (_selectedFile != null)
              Text('Fichier : ${_selectedFile!.path.split('/').last}'),
            const SizedBox(height: 16),
            _isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _uploadFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Déposer le document'),
                  ),
            if (_uploadMessage != null) ...[
              const SizedBox(height: 20),
              Text(_uploadMessage!, style: const TextStyle(fontSize: 16)),
            ]
          ],
        ),
      ),
    );
  }
}
