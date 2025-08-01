import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_file/open_file.dart';
import '../helpers/enregistrer_fichier_universel.dart';

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
          });
        } else {
          setState(() => statut = null);
        }
      } else {
        setState(() => statut = null);
      }
    } else {
      setState(() => statut = 'ERREUR');
    }

    setState(() => isLoading = false);
  }

  Future<void> _telechargerDocument(int conventionId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url =
        'http://10.0.2.2:8081/api/convention/$conventionId/download-admin';

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final bytes = response.bodyBytes;

        final chemin = await enregistrerFichierUniversel(
          bytes: bytes,
          nomFichier: 'convention_admin_$conventionId.pdf',
        );

        await OpenFile.open(chemin);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Convention téléchargée.")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Erreur lors du téléchargement.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur lors du téléchargement.")),
      );
    }
  }

  Future<void> _soumettre() async {
    if (statut == 'EN_ATTENTE' ||
        statut == 'SIGNEE_EN_ATTENTE_VALIDATION' ||
        statut == 'SIGNEE_VALIDEE') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Vous ne pouvez pas soumettre une nouvelle demande pour le moment.')),
      );
      return;
    }

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
            if (statut == 'SIGNEE_VALIDEE') {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified, color: Colors.green, size: 60),
                    SizedBox(height: 16),
                    Text(
                      "🎉 Votre convention signée a été validée !",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
              );
            }

            if (statut == 'EN_ATTENTE' ||
                statut == 'SIGNEE_EN_ATTENTE_VALIDATION') {
              return const Center(
                child: Text(
                  "⏳ Votre demande est en cours de traitement.",
                  style: TextStyle(fontSize: 16),
                ),
              );
            }

            return SingleChildScrollView(
              child: Column(
                children: [
                  if (statut == 'REJETEE' || statut == 'SIGNEE_REJETEE')
                    const Text(
                        "❌ Votre demande a été rejetée. Vous pouvez en soumettre une nouvelle."),
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
