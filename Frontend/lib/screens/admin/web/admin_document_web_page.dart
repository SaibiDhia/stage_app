// lib/screens/admin/web/admin_document_web_page.dart
import 'dart:convert';
import 'dart:html' as html; // <— pour déclencher un téléchargement sur Web
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pfeproject/core/options_parcours.dart';

class AdminDocumentWebPage extends StatefulWidget {
  const AdminDocumentWebPage({super.key});
  @override
  State<AdminDocumentWebPage> createState() => _AdminDocumentWebPageState();
}

class _AdminDocumentWebPageState extends State<AdminDocumentWebPage> {
  // Filtres
  final _emailCtrl = TextEditingController();
  OptionParcours? _opt; // null = Tous
  String? _type; // null = Tous
  String? _statut; // null = Tous

  // Listes
  final _types = const [
    'Journal de Bord',
    'Bilan Version 1',
    'Bilan Version 2',
    'Bilan Version 3',
    'Rapport Version 1',
    'Rapport Version 2',
  ];
  final _statuts = const ['EN_ATTENTE', 'VALIDE', 'REJETE'];

  // Données
  List<DocumentRow> _rows = [];
  bool _loading = false;

  // Base url web (tu peux factoriser ailleurs si tu veux)
  static const _baseUrl = 'http://192.168.0.127:8081';

  @override
  void initState() {
    super.initState();
    _load(); // charge sans filtres
  }

  Future<String> _jwt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final jwt = await _jwt();

      final uri = Uri.parse('$_baseUrl/api/documents/all').replace(
        queryParameters: {
          if (_emailCtrl.text.trim().isNotEmpty)
            'email': _emailCtrl.text.trim(),
          if (_opt != null) 'option': _opt!.name,
          if (_type != null) 'type': _type,
          if (_statut != null) 'statut': _statut,
        },
      );

      final res =
          await http.get(uri, headers: {'Authorization': 'Bearer $jwt'});

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        _rows = data.map((j) => DocumentRow.fromJson(j)).toList();
      } else {
        _rows = [];
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur ${res.statusCode} : ${res.body}')),
          );
        }
      }
    } catch (e) {
      _rows = [];
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearFilters() {
    _emailCtrl.clear();
    _opt = null;
    _type = null;
    _statut = null;
    _load();
  }

  // ========= ACTIONS =========

  Future<void> _download(int id) async {
    try {
      final jwt = await _jwt();
      final uri = Uri.parse('$_baseUrl/api/documents/download/$id');

      final res =
          await http.get(uri, headers: {'Authorization': 'Bearer $jwt'});
      if (res.statusCode == 200) {
        // 1) Get filename from Content-Disposition when present
        final cd = res.headers['content-disposition'] ?? '';
        String filename = 'document_$id';
        final match = RegExp(r'filename="?([^"]+)"?').firstMatch(cd);
        if (match != null &&
            match.group(1) != null &&
            match.group(1)!.trim().isNotEmpty) {
          filename = match.group(1)!.trim();
        }

        // 2) Get MIME from server (falls back to octet-stream)
        final mime = res.headers['content-type'] ?? 'application/octet-stream';

        // 3) If server didn’t give a filename with extension, add a safe one by MIME
        if (!filename.contains('.')) {
          if (mime == 'application/pdf')
            filename += '.pdf';
          else if (mime.startsWith('image/'))
            filename += '.${mime.split('/').last}';
          else
            filename += '.bin';
        }

        // 4) Create Blob with the correct MIME
        final blob = html.Blob([res.bodyBytes], mime);
        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor = html.AnchorElement(href: url)
          ..download = filename
          ..style.display = 'none';
        html.document.body!.children.add(anchor);
        anchor.click();
        anchor.remove();
        html.Url.revokeObjectUrl(url);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Téléchargement échoué (${res.statusCode})')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur download: $e')),
        );
      }
    }
  }

  Future<void> _validate(int id) async {
    try {
      final jwt = await _jwt();
      final uri = Uri.parse('$_baseUrl/api/documents/$id/valider');
      final res =
          await http.put(uri, headers: {'Authorization': 'Bearer $jwt'});
      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Document validé.')));
        }
        _load();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur validation: ${res.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Future<void> _reject(int id) async {
    try {
      final jwt = await _jwt();
      final uri = Uri.parse('$_baseUrl/api/documents/$id/rejeter');
      final res =
          await http.put(uri, headers: {'Authorization': 'Bearer $jwt'});
      if (res.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Document rejeté.')));
        }
        _load();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur rejet: ${res.statusCode}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  // ========= UI =========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Validation des Documents')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  // Email
                  SizedBox(
                    width: 260,
                    child: TextField(
                      controller: _emailCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Recherche par email…',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                      ),
                      onSubmitted: (_) => _load(),
                    ),
                  ),

                  // Option/Parcours
                  SizedBox(
                    width: 220,
                    child: DropdownButtonFormField<OptionParcours?>(
                      decoration: const InputDecoration(
                        labelText: 'Option',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.school),
                      ),
                      isExpanded: true,
                      value: _opt,
                      items: <DropdownMenuItem<OptionParcours?>>[
                        const DropdownMenuItem<OptionParcours?>(
                          value: null,
                          child: Text('Tous'),
                        ),
                        ...OptionParcours.values.map(
                          (o) => DropdownMenuItem<OptionParcours?>(
                            value: o,
                            child: Text(kOptionLabels[o] ?? o.name),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _opt = v),
                    ),
                  ),

                  // Type
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String?>(
                      decoration: const InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description),
                      ),
                      isExpanded: true,
                      value: _type,
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Tous'),
                        ),
                        ..._types.map(
                          (t) => DropdownMenuItem<String?>(
                            value: t,
                            child: Text(t),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _type = v),
                    ),
                  ),

                  // Statut
                  SizedBox(
                    width: 180,
                    child: DropdownButtonFormField<String?>(
                      decoration: const InputDecoration(
                        labelText: 'Statut',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag),
                      ),
                      isExpanded: true,
                      value: _statut,
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('Tous'),
                        ),
                        ..._statuts.map(
                          (s) => DropdownMenuItem<String?>(
                            value: s,
                            child: Text(s),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _statut = v),
                    ),
                  ),

                  // Actions filtres
                  ElevatedButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.filter_alt),
                    label: const Text('Filtrer'),
                  ),
                  TextButton(
                    onPressed: _clearFilters,
                    child: const Text('Réinitialiser'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _rows.isEmpty
                    ? const Center(child: Text('Aucun document'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (_, i) => _DocumentTile(
                          row: _rows[i],
                          onDownload: () => _download(_rows[i].id),
                          onValidate: () => _validate(_rows[i].id),
                          onReject: () => _reject(_rows[i].id),
                        ),
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemCount: _rows.length,
                      ),
          ),
        ],
      ),
    );
  }
}

// ==== Modèle (aligne-toi sur ton DocumentDTO côté backend)
class DocumentRow {
  final int id;
  final String email;
  final String type;
  final String statut; // EN_ATTENTE | VALIDE | REJETE
  final String? dateDepot; // optionnel
  final String? option; // ex: ERP_BI

  DocumentRow({
    required this.id,
    required this.email,
    required this.type,
    required this.statut,
    this.dateDepot,
    this.option,
  });

  factory DocumentRow.fromJson(Map<String, dynamic> j) => DocumentRow(
        id: (j['id'] as num).toInt(),
        email: (j['email'] ?? '') as String,
        type: (j['type'] ?? '') as String,
        statut: (j['statut'] ?? '') as String,
        dateDepot: j['dateDepot']?.toString(),
        option: j['optionParcours']?.toString(),
      );
}

class _DocumentTile extends StatelessWidget {
  final DocumentRow row;
  final VoidCallback onDownload;
  final VoidCallback onValidate;
  final VoidCallback onReject;

  const _DocumentTile({
    required this.row,
    required this.onDownload,
    required this.onValidate,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final optLabel = row.option == null
        ? '—'
        : (kOptionLabels[OptionParcours.values.firstWhere(
              (e) => e.name == row.option,
              orElse: () => OptionParcours.ERP_BI, // fallback lisible
            )] ??
            row.option!);

    final canModerate = row.statut == 'EN_ATTENTE';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(row.email.isEmpty ? '—' : row.email),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${row.type}'),
            Text('Statut: ${row.statut}'),
            if (row.dateDepot != null) Text('Déposé le: ${row.dateDepot}'),
            Text('Option: $optLabel'),
          ],
        ),
        trailing: Wrap(
          spacing: 8,
          children: [
            Tooltip(
              message: 'Télécharger',
              child: IconButton(
                onPressed: onDownload,
                icon: const Icon(Icons.download_outlined),
              ),
            ),
            Tooltip(
              message: 'Valider',
              child: IconButton(
                onPressed: canModerate ? onValidate : null,
                icon: const Icon(Icons.check_circle),
                color: canModerate ? Colors.green : null,
              ),
            ),
            Tooltip(
              message: 'Rejeter',
              child: IconButton(
                onPressed: canModerate ? onReject : null,
                icon: const Icon(Icons.cancel),
                color: canModerate ? Colors.red : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
