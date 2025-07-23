import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../helpers/enregistrer_fichier_universel.dart';

import '../../../helpers/download_helper_web.dart'
    if (dart.library.io) '../../../helpers/download_helper_stub.dart';

class DemandeConventionPage extends StatefulWidget {
  const DemandeConventionPage({super.key});

  @override
  State<DemandeConventionPage> createState() => _DemandeConventionPageState();
}

class _DemandeConventionPageState extends State<DemandeConventionPage> {
  final TextEditingController entrepriseController = TextEditingController();
  final TextEditingController adresseController = TextEditingController();
  final TextEditingController representantController = TextEditingController();
  final TextEditingController emailEntrepriseController =
      TextEditingController();
  final TextEditingController optionController = TextEditingController();
  final TextEditingController domaineController = TextEditingController();

  DateTime? dateDebut;
  DateTime? dateFin;

  bool isLoading = true;
  String? statut;
  String? documentUrl;
  int? conventionId;

  @override
  void initState() {
    super.initState();
    _verifierStatut();
  }

  Future<void> _verifierStatut() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final res = await http.get(
      Uri.parse('http://10.0.2.2:8081/api/convention/ma-convention'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (res.statusCode == 200) {
      final body = res.body.trim();
      if (body.isNotEmpty && body != 'null') {
        final data = jsonDecode(body);

        if (data is Map && data.containsKey('statut')) {
          setState(() {
            statut = data['statut'];
            conventionId = data['id'];
            if (statut == 'VALIDEE') {
              documentUrl =
                  'http://192.168.0.127:8081/api/convention/${data['id']}/download-admin';
            }
          });
        } else {
          // Réponse inattendue, on considère qu’il n’y a pas de convention
          setState(() => statut = null);
        }
      } else {
        // L’API retourne null ou vide : aucune convention
        setState(() => statut = null);
      }
    } else {
      // Erreur réseau → on bloque quand même toute nouvelle demande
      setState(() => statut = 'ERREUR');
    }

    setState(() => isLoading = false);
  }

  Future<void> _telechargerDocument(int conventionId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url =
        'http://192.168.0.127:8081/api/convention/$conventionId/download-admin';
    print("📥 Tentative de téléchargement depuis : $url");

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      print("📦 Code réponse : ${response.statusCode}");

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        // Utilise le helper universel
        final chemin = await enregistrerFichierUniversel(
          bytes: bytes,
          nomFichier: 'convention_admin_$conventionId.pdf',
        );
        print("✅ Fichier enregistré à : $chemin");

        await OpenFile.open(chemin);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("✅ Convention téléchargée avec succès.")),
        );
      } else {
        print("❌ Erreur de téléchargement : ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors du téléchargement.")),
        );
      }
    } catch (e) {
      print("🔥 Exception lors du téléchargement : $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors du téléchargement.")),
      );
    }
  }

  Future<void> _soumettre() async {
    // ⛔ Blocage si une demande est déjà en attente ou validée
    if (statut == 'EN_ATTENTE' || statut == 'VALIDEE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Vous ne pouvez pas soumettre une nouvelle demande pour le moment.')),
      );
      return;
    }

    // ✅ Vérification des champs
    if (entrepriseController.text.isEmpty ||
        adresseController.text.isEmpty ||
        representantController.text.isEmpty ||
        emailEntrepriseController.text.isEmpty ||
        optionController.text.isEmpty ||
        domaineController.text.isEmpty ||
        dateDebut == null ||
        dateFin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs.')),
      );
      return;
    }

    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final url = Uri.parse('http://10.0.2.2:8081/api/convention/demander');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'entreprise': entrepriseController.text,
          'adresse': adresseController.text,
          'representant': representantController.text,
          'emailEntreprise': emailEntrepriseController.text,
          'option': optionController.text,
          'domaine': domaineController.text,
          'dateDebut': dateDebut!.toIso8601String(),
          'dateFin': dateFin!.toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Demande envoyée avec succès')),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Erreur ${response.statusCode} : ${response.body}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur réseau : $e')),
      );
    }

    setState(() => isLoading = false);
  }

  Future<void> _selectDate({required bool isDebut}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 1),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked != null) {
      setState(() {
        if (isDebut) {
          dateDebut = picked;
        } else {
          dateFin = picked;
        }
      });
    }
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Demander Convention')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Builder(
          builder: (_) {
            if (statut == 'EN_ATTENTE') {
              return const Center(
                child: Text("Votre demande est en cours de traitement."),
              );
            }

            if (statut == 'VALIDEE') {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                      "✅ Votre demande a été validée. Vous pouvez télécharger la convention validée :"),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _telechargerDocument(conventionId!),
                    child: const Text("Télécharger la convention"),
                  ),
                  const SizedBox(height: 20),
                  const Text("Déposer votre convention signée."),
                ],
              );
            }

            // Si REJETEE ou pas de demande du tout
            return SingleChildScrollView(
              child: Column(
                children: [
                  if (statut == 'REJETEE')
                    const Text(
                        "❌ Votre demande a été rejetée. Veuillez soumettre une nouvelle demande."),
                  _buildTextField(entrepriseController, 'Nom de l\'entreprise'),
                  _buildTextField(adresseController, 'Adresse'),
                  _buildTextField(representantController, 'Représentant'),
                  _buildTextField(
                      emailEntrepriseController, 'Email de l\'entreprise'),
                  _buildTextField(optionController, 'Option'),
                  _buildTextField(domaineController, 'Domaine'),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      const Text('Date début : '),
                      Text(dateDebut != null
                          ? '${dateDebut!.day}/${dateDebut!.month}/${dateDebut!.year}'
                          : 'Non sélectionnée'),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => _selectDate(isDebut: true),
                        child: const Text('Choisir'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Date fin : '),
                      Text(dateFin != null
                          ? '${dateFin!.day}/${dateFin!.month}/${dateFin!.year}'
                          : 'Non sélectionnée'),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => _selectDate(isDebut: false),
                        child: const Text('Choisir'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _soumettre,
                      child: const Text('Envoyer la demande'),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
