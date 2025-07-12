import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class DepotPage extends StatefulWidget {
  final String documentType; // "Bilan", "Rapport", "Journal de Bord"

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
  String _currentType = '';
  int _currentVersion = 1;
  int _maxVersion = 1;

  // -------- LOGIQUE VERSION --------

  int getMaxVersion(String baseType) {
    switch (baseType) {
      case 'Bilan':
        return 1;
      case 'Rapport':
        return 2;
      case 'Journal de Bord':
        return 3;
      default:
        return 1;
    }
  }

  String _getVersionType(String baseType, int version) {
    if (baseType == 'Journal de Bord') {
      return 'Journal de Bord Version $version';
    }
    return '$baseType Version $version';
  }

  @override
  void initState() {
    super.initState();
    _maxVersion = getMaxVersion(widget.documentType);
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

  // -------- SELECTION DE FICHIER --------

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = File(result.files.single.path!);
        _uploadMessage = null;
      });
    }
  }

  // -------- RÉCUPÉRATION STATUTS + VERSION --------

  Future<void> _fetchStatut() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final token = prefs.getString('token');
      if (userId == null || token == null) {
        setState(() => _statut = '❌ Utilisateur non authentifié');
        return;
      }

      String baseType = widget.documentType;
      int maxVersion = getMaxVersion(baseType);

      // Va chercher le statut de chaque version (de 1 à maxVersion)
      for (int version = 1; version <= maxVersion; version++) {
        final docType = _getVersionType(baseType, version);
        final encodedType = Uri.encodeComponent(docType);
        final url =
            'http://10.0.2.2:8081/api/documents/statut?userId=$userId&type=$encodedType';

        final response = await http.get(Uri.parse(url), headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        });

        if (response.statusCode == 200) {
          final status = response.body.replaceAll('"', '').toUpperCase();

          // NON_DEPOSE ou REJETE : c'est la version à déposer !
          if (status == 'NON_DEPOSE' || status == 'REJETE') {
            setState(() {
              _currentVersion = version;
              _currentType = docType;
              _statut = status;
            });
            return;
          }
          // EN_ATTENTE : doit attendre la validation/rejet de cette version
          if (status == 'EN_ATTENTE') {
            setState(() {
              _currentVersion = version;
              _currentType = docType;
              _statut = status;
            });
            return;
          }
          // VALIDE : continue boucle (version suivante)
        } else {
          setState(() => _statut = 'Erreur ${response.statusCode}');
          return;
        }
      }

      // Si toutes les versions sont validées
      setState(() {
        _statut = 'TOUTES_VALIDEES';
        _currentVersion = maxVersion;
        _currentType = _getVersionType(baseType, maxVersion);
      });
    } catch (e) {
      setState(() => _statut = '❌ Erreur réseau');
    }
  }

  // -------- UPLOAD --------

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
      ..fields['type'] = _currentType
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

  // -------- UI --------

  @override
  Widget build(BuildContext context) {
    // Dépôt désactivé si EN_ATTENTE ou TOUTES_VALIDEES
    bool isDepotDisabled =
        _statut == 'EN_ATTENTE' || _statut == 'TOUTES_VALIDEES';

    // Messages personnalisés selon statut/version
    String infoMsg = '';
    if (_statut == 'NON_DEPOSE') {
      infoMsg = "Déposez la version $_currentVersion.";
    } else if (_statut == 'EN_ATTENTE') {
      infoMsg =
          "🕒 Ce document est en cours de validation. Vous ne pouvez pas le modifier pour le moment.";
    } else if (_statut == 'REJETE') {
      infoMsg =
          "❌ Le document a été rejeté. Vous pouvez déposer à nouveau cette version.";
    } else if (_statut == 'VALIDE' && _currentVersion < _maxVersion) {
      infoMsg =
          "✅ Version ${_currentVersion} validée. Veuillez déposer la version suivante.";
    } else if (_statut == 'TOUTES_VALIDEES') {
      infoMsg = "✅ Toutes les versions ont été validées pour ce document.";
    }

    return Scaffold(
      appBar: AppBar(title: Text('Déposer $_currentType')),
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
            if (infoMsg.isNotEmpty)
              _buildStatusBox(
                _statut == 'EN_ATTENTE'
                    ? Colors.amber[100]!
                    : _statut == 'REJETE'
                        ? Colors.red[100]!
                        : _statut == 'TOUTES_VALIDEES'
                            ? Colors.green[100]!
                            : Colors.blue[50]!,
                _statut == 'EN_ATTENTE'
                    ? Icons.hourglass_top
                    : _statut == 'REJETE'
                        ? Icons.cancel
                        : Icons.check_circle,
                _statut == 'EN_ATTENTE'
                    ? Colors.orange
                    : _statut == 'REJETE'
                        ? Colors.red
                        : Colors.green,
                infoMsg,
              ),
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
