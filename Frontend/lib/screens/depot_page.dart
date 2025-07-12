import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

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
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _fetchStatut();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchStatut();
    });
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

  Future<void> _fetchStatut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final token = prefs.getString('token');

      if (userId == null || token == null) {
        setState(() => _statut = '❌ Utilisateur non authentifié');
        return;
      }

      final encodedType = Uri.encodeComponent(widget.documentType);
      final url =
          'http://10.0.2.2:8081/api/documents/statut?userId=$userId&type=$encodedType';

      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        setState(() => _statut = response.body.replaceAll('"', ''));
      } else {
        setState(() => _statut = 'Erreur ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _statut = '❌ Erreur réseau');
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
    final token = prefs.getString('token');

    if (userId == null || token == null) {
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
      ..headers['Authorization'] = 'Bearer $token'
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
        _uploadMessage = '❌ Échec du dépôt (${response.statusCode})';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDepotDisabled = _statut == 'En attente' || _statut == 'Validé';

    return Scaffold(
      appBar: AppBar(title: Text('Déposer ${widget.documentType}')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Statut actuel : $_statut',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 16),
            if (_statut == 'En attente')
              _buildStatusBox(
                  Colors.amber[100]!,
                  Icons.hourglass_top,
                  Colors.orange,
                  "🕒 Ce document est en cours de validation. Vous ne pouvez pas le modifier pour le moment."),
            if (_statut == 'Validé')
              _buildStatusBox(
                  Colors.green[100]!,
                  Icons.check_circle,
                  Colors.green,
                  "✅ Ce document a été validé. Aucun autre dépôt n'est requis."),
            if (_statut == 'Rejeté')
              _buildStatusBox(Colors.red[100]!, Icons.cancel, Colors.red,
                  "❌ Le document a été rejeté. Vous pouvez déposer une nouvelle version."),
            ElevatedButton.icon(
              onPressed: isDepotDisabled ? null : _pickFile,
              icon: const Icon(Icons.attach_file),
              label: const Text('Sélectionner un fichier'),
            ),
            const SizedBox(height: 16),
            if (_selectedFile != null)
              Text(
                  'Fichier sélectionné : ${_selectedFile!.path.split('/').last}'),
            const SizedBox(height: 16),
            _isUploading
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: isDepotDisabled ? null : _uploadFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Déposer le document'),
                  ),
            if (_uploadMessage != null) ...[
              const SizedBox(height: 20),
              Text(_uploadMessage!,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBox(
      Color backgroundColor, IconData icon, Color iconColor, String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 10),
          Expanded(
              child:
                  Text(message, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}
