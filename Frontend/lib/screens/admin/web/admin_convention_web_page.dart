// lib/screens/admin/web/admin_convention_web_page.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pfeproject/core/options_parcours.dart';

class AdminConventionWebPage extends StatefulWidget {
  const AdminConventionWebPage({super.key});
  @override
  State<AdminConventionWebPage> createState() => _AdminConventionWebPageState();
}

class _AdminConventionWebPageState extends State<AdminConventionWebPage> {
  final _emailCtrl = TextEditingController();

  // Filtres
  OptionParcours? _opt; // null = Tous
  static const String _sentinelTous = 'TOUS';
  String _statut = _sentinelTous;

  final _statuts = const <String>[
    'EN_ATTENTE',
    'VALIDEE',
    'REJETEE',
    'SIGNEE_EN_ATTENTE_VALIDATION',
    'SIGNEE_VALIDEE',
    'SIGNEE_REJETEE',
  ];

  // Données
  List<ConventionRow> _rows = [];
  bool _loading = false;

  // ---- CONFIG ----
  static const String _baseUrl = 'http://192.168.0.127:8081';

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ======= Helpers Dropdown =======
  List<DropdownMenuItem<OptionParcours?>> _buildOptionItems() {
    final items = OptionParcours.values
        .map<DropdownMenuItem<OptionParcours?>>(
          (o) => DropdownMenuItem<OptionParcours?>(
            value: o,
            child: Text(kOptionLabels[o] ?? o.name),
          ),
        )
        .toList(growable: true);
    items.insert(
      0,
      const DropdownMenuItem<OptionParcours?>(
        value: null,
        child: Text('Tous'),
      ),
    );
    return items;
  }

  List<DropdownMenuItem<String>> _buildStatutItems() {
    final items = _statuts
        .map<DropdownMenuItem<String>>(
          (s) => DropdownMenuItem<String>(value: s, child: Text(s)),
        )
        .toList(growable: true);
    items.insert(
      0,
      const DropdownMenuItem<String>(value: _sentinelTous, child: Text('Tous')),
    );
    return items;
  }

  // ======= API =======
  Future<String> _jwt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token') ?? '';
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final jwt = await _jwt();

      final qp = <String, String>{};
      final email = _emailCtrl.text.trim();
      if (email.isNotEmpty) qp['email'] = email;
      if (_opt != null) qp['option'] = _opt!.name;
      if (_statut != _sentinelTous) qp['statut'] = _statut;

      final uri = Uri.parse('$_baseUrl/api/convention/all')
          .replace(queryParameters: qp.isEmpty ? null : qp);

      if (kDebugMode) debugPrint('[Convention] GET $uri');

      final res =
          await http.get(uri, headers: {'Authorization': 'Bearer $jwt'});
      if (res.statusCode == 200) {
        final raw = jsonDecode(res.body);
        if (raw is! List) throw StateError('Réponse inattendue');
        _rows = raw
            .map<ConventionRow>(
                (j) => ConventionRow.fromJson(j as Map<String, dynamic>))
            .toList();
      } else {
        _rows = [];
        _toast('Erreur ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      _rows = [];
      _toast('Erreur: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _actionPut(String path) async {
    try {
      final jwt = await _jwt();
      final uri = Uri.parse('$_baseUrl$path');
      final res = await http.put(uri, headers: {
        'Authorization': 'Bearer $jwt',
      });
      if (res.statusCode == 200) {
        _toast('Action effectuée');
        _load();
      } else {
        _toast('Erreur ${res.statusCode}: ${res.body}');
      }
    } catch (e) {
      _toast('Erreur: $e');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _clear() {
    _emailCtrl.clear();
    _opt = null;
    _statut = _sentinelTous;
    _load();
  }

  // ======= UI =======
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gestion des Conventions')),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
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
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<OptionParcours?>(
                    isExpanded: true,
                    value: _opt,
                    items: _buildOptionItems(),
                    onChanged: (v) => setState(() => _opt = v),
                    decoration: const InputDecoration(
                      labelText: 'Option',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.school),
                    ),
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: _statut,
                    items: _buildStatutItems(),
                    onChanged: (v) =>
                        setState(() => _statut = v ?? _sentinelTous),
                    decoration: const InputDecoration(
                      labelText: 'Statut',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.flag),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.filter_alt),
                  label: const Text('Filtrer'),
                ),
                TextButton(
                    onPressed: _clear, child: const Text('Réinitialiser')),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _rows.isEmpty
                    ? const Center(child: Text('Aucune convention'))
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (_, i) => _ConventionTile(
                          row: _rows[i],
                          onValider: () => _actionPut(
                              '/api/convention/${_rows[i].id}/valider'),
                          onRejeter: () => _actionPut(
                              '/api/convention/${_rows[i].id}/rejeter'),
                          onValiderSignee: () => _actionPut(
                              '/api/convention/${_rows[i].id}/valider-signee'),
                          onRejeterSignee: () => _actionPut(
                              '/api/convention/${_rows[i].id}/rejeter-signee'),
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

// ======= Modèle aligné avec ton DTO (prévoir champs optionnels) =======
class ConventionRow {
  final int id;
  final String email;
  final String statut;

  final String? optionParcours;
  final String? entreprise;
  final String? representant;
  final String? adresse;
  final String? domaine;
  final String? emailEntreprise;

  final String? dateDebut; // strings pour affichage simple
  final String? dateFin;

  final String? cheminConventionAdmin;
  final String? cheminConventionSignee;

  ConventionRow({
    required this.id,
    required this.email,
    required this.statut,
    this.optionParcours,
    this.entreprise,
    this.representant,
    this.adresse,
    this.domaine,
    this.emailEntreprise,
    this.dateDebut,
    this.dateFin,
    this.cheminConventionAdmin,
    this.cheminConventionSignee,
  });

  static String? _str(Map<String, dynamic> j, String key) {
    final v = j[key];
    if (v == null) return null;
    return v.toString();
  }

  factory ConventionRow.fromJson(Map<String, dynamic> j) => ConventionRow(
        id: (j['id'] as num).toInt(),
        email: (j['emailEtudiant'] ?? '') as String,
        statut: (j['statut'] ?? '') as String,

        // Ces clés doivent correspondre à ton ConventionDTO backend
        optionParcours: _str(j, 'option'),
        entreprise: _str(j, 'entreprise'),
        representant: _str(j, 'representant'),
        adresse: _str(j, 'adresse'),
        domaine: _str(j, 'domaine'),
        emailEntreprise:
            _str(j, 'email_entreprise') ?? _str(j, 'emailEntreprise'),

        dateDebut: _str(j, 'date_debut') ?? _str(j, 'dateDebut'),
        dateFin: _str(j, 'date_fin') ?? _str(j, 'dateFin'),

        cheminConventionAdmin: _str(j, 'chemin_convention_admin') ??
            _str(j, 'cheminConventionAdmin'),
        cheminConventionSignee: _str(j, 'chemin_convention_signee') ??
            _str(j, 'cheminConventionSignee'),
      );
}

// ======= Tuile avec détails + actions selon le statut =======
class _ConventionTile extends StatelessWidget {
  final ConventionRow row;

  final VoidCallback onValider;
  final VoidCallback onRejeter;
  final VoidCallback onValiderSignee;
  final VoidCallback onRejeterSignee;

  const _ConventionTile({
    required this.row,
    required this.onValider,
    required this.onRejeter,
    required this.onValiderSignee,
    required this.onRejeterSignee,
  });

  bool get _isEnAttente => row.statut == 'EN_ATTENTE';
  bool get _isSigneeEnAttente => row.statut == 'SIGNEE_EN_ATTENTE_VALIDATION';

  @override
  Widget build(BuildContext context) {
    final optLabel = row.optionParcours == null
        ? '—'
        : (kOptionLabels[OptionParcours.values.firstWhere(
              (e) => e.name == row.optionParcours,
              orElse: () => OptionParcours.ERP_BI,
            )] ??
            row.optionParcours!);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: ListTile(
        isThreeLine: true,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(row.email.isEmpty ? '—' : row.email),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Statut: ${row.statut}'),
              Text('Option: $optLabel'),
              if (row.entreprise != null) Text('Entreprise: ${row.entreprise}'),
              if (row.representant != null)
                Text('Représentant: ${row.representant}'),
              if (row.adresse != null) Text('Adresse: ${row.adresse}'),
              if (row.domaine != null) Text('Domaine: ${row.domaine}'),
              if (row.emailEntreprise != null)
                Text('Email entreprise: ${row.emailEntreprise}'),
              if (row.dateDebut != null || row.dateFin != null)
                Text(
                    'Période: ${row.dateDebut ?? "?"} → ${row.dateFin ?? "?"}'),
              if (row.cheminConventionAdmin != null)
                Text('Fichier admin: ${row.cheminConventionAdmin}'),
              if (row.cheminConventionSignee != null)
                Text('Fichier signé: ${row.cheminConventionSignee}'),
            ],
          ),
        ),
        trailing: _buildActions(context),
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    final buttons = <Widget>[];

    if (_isEnAttente) {
      buttons.addAll([
        IconButton(
          tooltip: 'Valider',
          onPressed: onValider,
          icon: const Icon(Icons.check_circle, color: Colors.green),
        ),
        IconButton(
          tooltip: 'Rejeter',
          onPressed: onRejeter,
          icon: const Icon(Icons.cancel, color: Colors.red),
        ),
      ]);
    } else if (_isSigneeEnAttente) {
      buttons.addAll([
        IconButton(
          tooltip: 'Valider signée',
          onPressed: onValiderSignee,
          icon: const Icon(Icons.check_circle, color: Colors.green),
        ),
        IconButton(
          tooltip: 'Rejeter signée',
          onPressed: onRejeterSignee,
          icon: const Icon(Icons.cancel, color: Colors.red),
        ),
      ]);
    } else {
      // Aucun bouton si déjà validée/rejetée
      buttons.add(const SizedBox(width: 0, height: 0));
    }

    return Row(mainAxisSize: MainAxisSize.min, children: buttons);
  }
}
