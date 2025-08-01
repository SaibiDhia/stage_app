import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

class DepotPage extends StatefulWidget {
  final String documentType; // 'Bilan', 'Rapport', 'Journal de Bord'

  const DepotPage({super.key, required this.documentType});

  @override
  State<DepotPage> createState() => _DepotPageState();
}

class _DepotPageState extends State<DepotPage> {
  bool _conventionValidee = false;
  File? _selectedFile;
  bool _isUploading = false;
  String? _uploadMessage;
  String _statut = 'Chargement...';
  Timer? _refreshTimer;
  String _currentType = '';
  int _currentVersion = 1;
  int _maxVersion = 1;
  List<Map<String, dynamic>> _historique = [];

  @override
  void initState() {
    super.initState();
    _maxVersion = _getMaxVersion(widget.documentType);
    _checkConventionValidation();
    _fetchStatutAndHistorique();
    _startAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startAutoRefresh() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _fetchStatutAndHistorique();
    });
  }

  int _getMaxVersion(String baseType) {
    if (baseType.startsWith('Journal de Bord')) return 1;
    if (baseType.startsWith('Rapport')) return 2;
    if (baseType.startsWith('Bilan')) return 3;
    return 1;
  }

  String _getVersionedType(String baseType, int version) {
    if (baseType.contains('Version')) return baseType;
    if (baseType == 'Journal de Bord') return "Journal de Bord";
    return "$baseType Version $version";
  }

  Future<void> _checkConventionValidation() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('userId');
    final token = prefs.getString('token');

    if (userId == null || token == null) return;

    final url =
        Uri.parse('http://10.0.2.2:8081/api/convention/by-user/$userId');
    final response = await http.get(url, headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    });
    print("📡 Status code de la convention : ${response.statusCode}");

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(utf8.decode(response.bodyBytes));
      debugPrint("🧾 Réponse JSON complète : $data");

      if (data.isNotEmpty) {
        final convention = data[0];
        setState(() {
          _conventionValidee = convention['statut'] == 'SIGNEE_VALIDEE';
        });
        debugPrint("🔐 Statut de la convention: ${convention['statut']}");
      } else {
        debugPrint("📭 Pas de convention trouvée pour cet utilisateur");
        setState(() => _conventionValidee = false);
      }
    } else {
      debugPrint("❌ Erreur statut ${response.statusCode}");
      setState(() => _conventionValidee = false);
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

  Future<void> _fetchStatutAndHistorique() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');
      final token = prefs.getString('token');

      if (userId == null || token == null) {
        setState(() => _statut = '❌ Utilisateur non authentifié');
        return;
      }

      final histoUrl =
          'http://10.0.2.2:8081/api/documents/historique?userId=$userId&baseType=${widget.documentType}';
      final histoResp = await http.get(Uri.parse(histoUrl), headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (histoResp.statusCode == 200) {
        final List<dynamic> docs =
            json.decode(utf8.decode(histoResp.bodyBytes));
        setState(() {
          _historique = docs.map<Map<String, dynamic>>((doc) {
            return {
              'type': doc['type'],
              'dateDepot': doc['dateDepot'],
              'statut': doc['statut'],
            };
          }).toList();
        });
      }

      for (int version = 1; version <= _maxVersion; version++) {
        final docType = _getVersionedType(widget.documentType, version);
        final versionDocs =
            _historique.where((doc) => doc['type'] == docType).toList();

        if (versionDocs.isEmpty) {
          setState(() {
            _currentVersion = version;
            _currentType = docType;
            _statut = 'NON_DEPOSE';
          });
          return;
        }
        final lastDoc = versionDocs.last;
        final lastStatus = lastDoc['statut'].toUpperCase();

        if (lastStatus == 'EN_ATTENTE' || lastStatus == 'REJETE') {
          setState(() {
            _currentVersion = version;
            _currentType = docType;
            _statut = lastStatus;
          });
          return;
        }
      }

      setState(() {
        _statut = 'TOUTES_VALIDEES';
        _currentVersion = _maxVersion;
        _currentType = _getVersionedType(widget.documentType, _maxVersion);
      });
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
      _fetchStatutAndHistorique();
    } else {
      setState(() {
        _uploadMessage = '❌ Échec du dépôt (${response.statusCode})';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDepotDisabled = !_conventionValidee ||
        _statut == 'EN_ATTENTE' ||
        _statut == 'TOUTES_VALIDEES';

    return Scaffold(
      appBar: AppBar(
        title: Text('Déposer $_currentType'),
        leading: const BackButton(),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Text(
              'Statut actuel : $_statut',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            if (!_conventionValidee)
              _buildStatusBox(
                Colors.grey[200]!,
                Icons.lock_outline,
                Colors.grey,
                "🛑 Vous ne pouvez pas déposer de documents tant que votre convention signée n’est pas validée.",
              ),
            if (_statut == 'EN_ATTENTE')
              _buildStatusBox(
                Colors.amber[100]!,
                Icons.hourglass_top,
                Colors.orange,
                "🕒 Ce document est en cours de validation. Vous ne pouvez pas le modifier pour le moment.",
              ),
            if (_statut == 'REJETE')
              _buildStatusBox(
                Colors.red[100]!,
                Icons.cancel,
                Colors.red,
                "❌ Le document a été rejeté. Vous pouvez déposer à nouveau cette version.",
              ),
            if (_statut == 'TOUTES_VALIDEES')
              _buildStatusBox(
                Colors.green[100]!,
                Icons.check_circle,
                Colors.green,
                "✅ Toutes les versions ont été validées pour ce document.",
              ),
            if (_statut == 'NON_DEPOSE')
              _buildStatusBox(
                Colors.blue[50]!,
                Icons.info_outline,
                Colors.blue,
                "Déposez la version $_currentVersion.",
              ),
            ElevatedButton.icon(
              onPressed: isDepotDisabled ? null : _pickFile,
              icon: const Icon(Icons.attach_file),
              label: const Text('Sélectionner un fichier'),
            ),
            const SizedBox(height: 16),
            if (_selectedFile != null)
              Text(
                'Fichier sélectionné : ${_selectedFile!.path.split('/').last}',
              ),
            const SizedBox(height: 16),
            _isUploading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: isDepotDisabled ? null : _uploadFile,
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Déposer le document'),
                  ),
            if (_uploadMessage != null) ...[
              const SizedBox(height: 20),
              Text(
                _uploadMessage!,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
            const SizedBox(height: 32),
            const Text(
              "Historique des dépôts :",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._historique.map((doc) => _buildHistoriqueCard(doc)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBox(
    Color backgroundColor,
    IconData icon,
    Color iconColor,
    String message,
  ) {
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
          Expanded(child: Text(message)),
        ],
      ),
    );
  }

  Widget _buildHistoriqueCard(Map<String, dynamic> doc) {
    Color color;
    IconData icon;
    String status = doc['statut'].toString().toUpperCase();
    switch (status) {
      case 'VALIDE':
        color = Colors.green[100]!;
        icon = Icons.check_circle;
        break;
      case 'EN_ATTENTE':
        color = Colors.amber[100]!;
        icon = Icons.hourglass_top;
        break;
      case 'REJETE':
        color = Colors.red[100]!;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.grey[200]!;
        icon = Icons.insert_drive_file;
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.09),
              blurRadius: 3,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.black54, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc['type'] ?? '',
                  style: const TextStyle(
                      fontWeight: FontWeight.w500, fontSize: 15),
                ),
                if (doc['dateDepot'] != null)
                  Text("Déposé le ${doc['dateDepot']}",
                      style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            status,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: status == 'VALIDE'
                  ? Colors.green[900]
                  : status == 'EN_ATTENTE'
                      ? Colors.orange[800]
                      : status == 'REJETE'
                          ? Colors.red[900]
                          : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
