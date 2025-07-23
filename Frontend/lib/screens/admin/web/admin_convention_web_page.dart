import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../helpers/download_helper_web.dart'
    if (dart.library.io) '../../../helpers/download_helper_stub.dart';
import '../../../helpers/upload_helper_web.dart'
    if (dart.library.io) '../../../helpers/upload_helper_stub.dart';

class AdminConventionWebPage extends StatefulWidget {
  const AdminConventionWebPage({super.key});

  @override
  State<AdminConventionWebPage> createState() => _AdminConventionWebPageState();
}

class _AdminConventionWebPageState extends State<AdminConventionWebPage> {
  List<dynamic> conventions = [];
  List<dynamic> filtered = [];
  String filterStatut = "TOUS";
  String searchEmail = "";
  String? token;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadTokenAndFetch();
  }

  Future<void> loadTokenAndFetch() async {
    final prefs = await SharedPreferences.getInstance();
    token = prefs.getString("token");
    if (token != null) await fetchConventions();
  }

  Future<void> fetchConventions() async {
    setState(() => isLoading = true);
    final response = await http.get(
      Uri.parse("http://192.168.0.127:8081/api/convention/all"),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      conventions = jsonDecode(response.body);
      applyFilters();
    }
    setState(() => isLoading = false);
  }

  void applyFilters() {
    setState(() {
      filtered = conventions.where((c) {
        final emailMatch =
            c['email'].toString().toLowerCase().contains(searchEmail);
        final statutMatch =
            filterStatut == "TOUS" || c['statut'] == filterStatut;
        return emailMatch && statutMatch;
      }).toList();
    });
  }

  Future<void> validerEtUploader(int id) async {
    // Valider la convention
    await http.put(
      Uri.parse("http://192.168.0.127:8081/api/convention/$id/valider"),
      headers: {'Authorization': 'Bearer $token'},
    );

    // Uploader le fichier PDF juste après validation
    if (kIsWeb) {
      await uploadAdminFile(
        id: id,
        token: "Bearer $token",
        onRefresh: fetchConventions,
      );
    }
  }

  Future<void> rejeterConvention(int id) async {
    await http.put(
      Uri.parse("http://192.168.0.127:8081/api/convention/$id/rejeter"),
      headers: {'Authorization': 'Bearer $token'},
    );
    await fetchConventions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Gestion des Conventions")),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      const Text("Rechercher par email:"),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          onChanged: (val) {
                            searchEmail = val.toLowerCase();
                            applyFilters();
                          },
                          decoration: const InputDecoration(
                              hintText: "ex: etudiant@email.com",
                              border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 20),
                      DropdownButton<String>(
                        value: filterStatut,
                        items: [
                          'TOUS',
                          ...conventions
                              .map((c) => c['statut'] as String)
                              .toSet()
                              .toList()
                        ]
                            .map((s) => DropdownMenuItem<String>(
                                  value: s,
                                  child: Text(s),
                                ))
                            .toList(),
                        onChanged: (val) {
                          filterStatut = val!;
                          applyFilters();
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: filtered.map((conv) {
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 12),
                        child: ListTile(
                          title:
                              Text(conv['entreprise'] ?? 'Entreprise inconnue'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Etudiant: ${conv['etudiantName'] ?? ''}"),
                              Text("Email: ${conv['email'] ?? ''}"),
                              Text("Date Début: ${conv['dateDebut'] ?? ''}"),
                              Text("Date Fin: ${conv['dateFin'] ?? ''}"),
                              Text("Statut: ${conv['statut'] ?? ''}"),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check,
                                    color: Colors.green),
                                onPressed: () => validerEtUploader(conv['id']),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.close, color: Colors.red),
                                onPressed: () => rejeterConvention(conv['id']),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                )
              ],
            ),
    );
  }
}
