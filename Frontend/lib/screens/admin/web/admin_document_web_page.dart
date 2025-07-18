import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../helpers/download_helper_web.dart'
    if (dart.library.io) '../../../helpers/download_helper_stub.dart';

class AdminDocumentWebPage extends StatefulWidget {
  const AdminDocumentWebPage({super.key});

  @override
  State<AdminDocumentWebPage> createState() => _AdminDocumentWebPageState();
}

class _AdminDocumentWebPageState extends State<AdminDocumentWebPage> {
  List<dynamic> documents = [];
  List<dynamic> filteredDocs = [];
  bool isLoading = true;
  String? token;
  String searchQuery = "";
  String filterType = "Tous";
  String filterStatut = "Tous";

  List<String> get types => [
        "Tous",
        ...{
          for (var d in documents)
            d['type']?.toString().split(" Version")[0] ?? ""
        }.where((e) => e.isNotEmpty)
      ].toSet().toList();

  List<String> get statuts => [
        "Tous",
        ...documents
            .map((d) => d['statut']?.toString() ?? "")
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()
      ];

  @override
  void initState() {
    super.initState();
    _loadTokenAndFetchDocuments();
  }

  Future<void> _loadTokenAndFetchDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString('token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Token manquant.")),
      );
      return;
    }
    await _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    setState(() => isLoading = true);
    final response = await http.get(
      Uri.parse('http://192.168.0.127:8081/api/documents/all'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      documents = jsonDecode(response.body);
      _applyFilters();
      setState(() => isLoading = false);
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${response.statusCode}")),
      );
    }
  }

  void _applyFilters() {
    setState(() {
      filteredDocs = documents.where((doc) {
        final matchesSearch = searchQuery.isEmpty ||
            (doc['email'] ?? '').toLowerCase().contains(searchQuery);
        final matchesType = filterType == "Tous" ||
            (doc['type']?.toString().split(" Version")[0] ?? "") == filterType;
        final matchesStatut =
            filterStatut == "Tous" || doc['statut'] == filterStatut;
        return matchesSearch && matchesType && matchesStatut;
      }).toList();
    });
  }

  Future<void> _updateDocumentStatus(int id, String action) async {
    final response = await http.put(
      Uri.parse('http://192.168.0.127:8081/api/documents/$id/$action'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Document $action avec succès.")),
      );
      await _fetchDocuments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Échec du $action: ${response.statusCode}")),
      );
    }
  }

  Widget _buildFiltersBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
        alignment: WrapAlignment.start,
        runSpacing: 8,
        children: [
          SizedBox(
            width: 240,
            child: TextField(
              decoration: InputDecoration(
                  hintText: "Recherche par email...",
                  border: OutlineInputBorder(),
                  isDense: true,
                  prefixIcon: Icon(Icons.search)),
              onChanged: (val) {
                searchQuery = val.toLowerCase();
                _applyFilters();
              },
            ),
          ),
          const SizedBox(width: 20),
          DropdownButton<String>(
            value: filterType,
            items: types
                .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                .toList(),
            onChanged: (value) {
              filterType = value!;
              _applyFilters();
            },
            hint: const Text('Type'),
          ),
          const SizedBox(width: 20),
          DropdownButton<String>(
            value: filterStatut,
            items: statuts
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (value) {
              filterStatut = value!;
              _applyFilters();
            },
            hint: const Text('Statut'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Validation des Documents")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFiltersBar(),
                Expanded(
                  child: filteredDocs.isEmpty
                      ? Center(child: Text("Aucun document trouvé."))
                      : ListView.builder(
                          itemCount: filteredDocs.length,
                          itemBuilder: (context, index) {
                            final doc = filteredDocs[index];
                            final isActionable = doc['statut'] == "EN_ATTENTE";
                            return Card(
                                margin: const EdgeInsets.symmetric(
                                    vertical: 8, horizontal: 12),
                                child: ListTile(
                                  title: Text(
                                      doc['email'] ?? 'Email indisponible'),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text("Statut: ${doc['statut']}"),
                                      Text("Type: ${doc['type'] ?? ''}"),
                                      Text(
                                          "Déposé le: ${doc['dateDepot'] ?? ''}"),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Bouton télécharger
                                      IconButton(
                                        icon: const Icon(Icons.download),
                                        onPressed: kIsWeb
                                            ? () async {
                                                final url =
                                                    'http://192.168.0.127:8081/api/documents/download/${doc['id']}';

                                                try {
                                                  final response = await http
                                                      .get(Uri.parse(url),
                                                          headers: {
                                                        'Authorization':
                                                            'Bearer $token',
                                                      });
                                                  if (response.statusCode ==
                                                      200) {
                                                    String filename =
                                                        doc['nomFichier'] ??
                                                            "document.pdf";
                                                    downloadBytes(
                                                        response.bodyBytes,
                                                        filename);
                                                  } else {
                                                    ScaffoldMessenger.of(
                                                            context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                          content: Text(
                                                              "Erreur téléchargement: ${response.statusCode}")),
                                                    );
                                                  }
                                                } catch (e) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                        content: Text(
                                                            "Erreur réseau: $e")),
                                                  );
                                                }
                                              }
                                            : null,
                                        tooltip: "Télécharger",
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.check_circle,
                                            color: Colors.green),
                                        onPressed: isActionable
                                            ? () => _updateDocumentStatus(
                                                doc['id'], "valider")
                                            : null,
                                        tooltip: isActionable
                                            ? "Valider"
                                            : "Déjà traité",
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.cancel,
                                            color: Colors.red),
                                        onPressed: isActionable
                                            ? () => _updateDocumentStatus(
                                                doc['id'], "rejeter")
                                            : null,
                                        tooltip: isActionable
                                            ? "Rejeter"
                                            : "Déjà traité",
                                      ),
                                    ],
                                  ),
                                ));
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
