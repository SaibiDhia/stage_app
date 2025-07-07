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

  @override
  void initState() {
    super.initState();
    _fetchDocuments();
  }

  Future<void> _fetchDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Token manquant.")),
      );
      return;
    }

    final response = await http.get(
      Uri.parse('http://192.168.1.105:8081/api/documents/all'),
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
      setState(() {
        isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur: ${response.statusCode}")),
      );
    }
  }

  Future<void> _updateStatus(int docId, String action) async {
    final url = 'http://192.168.1.105:8081/api/documents/$docId/$action';
    final response = await http.put(Uri.parse(url));
    if (response.statusCode == 200) {
      _fetchDocuments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des Documents (Web Admin)')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Utilisateur')),
                  DataColumn(label: Text('Statut')),
                  DataColumn(label: Text('Action')),
                ],
                rows: documents.map((doc) {
                  return DataRow(cells: [
                    DataCell(Text(doc['id'].toString())),
                    DataCell(Text(doc['type'])),
                    DataCell(Text(doc['utilisateur']['email'] ?? 'Inconnu')),
                    DataCell(Text(doc['statut'] ?? '')),
                    DataCell(Row(
                      children: [
                        ElevatedButton(
                          onPressed: () => _updateStatus(doc['id'], 'valider'),
                          child: const Text('Valider'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () => _updateStatus(doc['id'], 'rejeter'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text('Rejeter'),
                        ),
                      ],
                    )),
                  ]);
                }).toList(),
              ),
            ),
    );
  }
}
