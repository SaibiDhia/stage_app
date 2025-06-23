import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AdminDocumentPage extends StatefulWidget {
  const AdminDocumentPage({super.key});

  @override
  State<AdminDocumentPage> createState() => _AdminDocumentPageState();
}

class _AdminDocumentPageState extends State<AdminDocumentPage> {
  List<dynamic> documents = [];

  @override
  void initState() {
    super.initState();
    fetchDocuments();
  }

  Future<void> fetchDocuments() async {
    final response =
        await http.get(Uri.parse('http://10.0.2.2:8081/api/documents/all'));
    if (response.statusCode == 200) {
      setState(() {
        documents = jsonDecode(response.body);
      });
    }
  }

  Future<void> updateStatus(int id, String action) async {
    final response = await http.put(
      Uri.parse('http://10.0.2.2:8081/api/documents/$id/$action'),
    );
    if (response.statusCode == 200) {
      fetchDocuments();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : ${response.body}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Validation des documents')),
      body: ListView.builder(
        itemCount: documents.length,
        itemBuilder: (context, index) {
          final doc = documents[index];
          return Card(
            margin: const EdgeInsets.all(10),
            child: ListTile(
              title: Text('${doc['type']} - ${doc['nomFichier']}'),
              subtitle: Text(
                  'Statut : ${doc['statut']}\nÉtudiant ID : ${doc['utilisateur']['id']}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.check, color: Colors.green),
                    onPressed: () => updateStatus(doc['id'], 'valider'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => updateStatus(doc['id'], 'rejeter'),
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
