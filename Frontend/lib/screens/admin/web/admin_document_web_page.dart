import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminDocumentWebPage extends StatefulWidget {
  const AdminDocumentWebPage({super.key});

  @override
  State<AdminDocumentWebPage> createState() => _AdminDocumentWebPageState();
}

class _AdminDocumentWebPageState extends State<AdminDocumentWebPage> {
  List<dynamic> documents = [];
  bool isLoading = true;
  String? token;

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
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    final response = await http.get(
      Uri.parse('http://192.168.0.127:8081/api/documents/all'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        documents = jsonDecode(response.body);
        isLoading = false;
      });
    } else {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${response.statusCode}")),
      );
    }
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
      _fetchDocuments(); // refresh the list
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Échec du $action: ${response.statusCode}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Validation des Documents")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: documents.length,
              itemBuilder: (context, index) {
                final doc = documents[index];
                return Card(
                  margin:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  child: ListTile(
                    title: Text(doc['nomFichier'] ?? 'Nom indisponible'),
                    subtitle: Text("Statut: ${doc['statut']}"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check_circle,
                              color: Colors.green),
                          onPressed: () =>
                              _updateDocumentStatus(doc['id'], "valider"),
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () =>
                              _updateDocumentStatus(doc['id'], "rejeter"),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
