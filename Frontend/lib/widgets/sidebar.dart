import 'package:flutter/material.dart';

class Sidebar extends StatelessWidget {
  final void Function(String)? onSelect;

  const Sidebar({super.key, this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.red.shade900,
      child: ListView(
        children: [
          DrawerHeader(
            child: Text(
              'Gestion des PFE',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          _buildTile(Icons.dashboard, 'Tableau de Bord', 'dashboard'),
          _buildTile(
              Icons.calendar_today, 'Rendez-Vous & Visites', 'rendezvous'),
          _buildTile(Icons.description, 'Gérer Convention', 'convention'),
          _buildTile(Icons.work_outline, 'Gérer Plan Travail', 'plan'),
          _buildTile(Icons.folder, 'Mes Documents', 'documents'),
          _buildTile(Icons.star, 'Stage Ingénieur', 'stage'),
          _buildTile(Icons.person, 'Mon Profil', 'profil'),
        ],
      ),
    );
  }

  ListTile _buildTile(IconData icon, String title, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: TextStyle(color: Colors.white)),
      onTap: () => onSelect?.call(route),
    );
  }
}
