import 'package:flutter/material.dart';
import '../screens/depot_page.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.red[900],
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.red),
            child: Text(
              'Menu PFE',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
          ),
          _buildTile(Icons.dashboard, "Tableau de Bord PFE", () {}),
          _buildTile(Icons.event, "Rendez-Vous & Visites", () {}),
          _buildTile(Icons.assignment, "Gérer Convention", () {}),
          _buildTile(Icons.article, "Gérer Plan Travail", () {}),
          _buildTile(Icons.edit_document, "Gérer Avenants", () {}),
          ExpansionTile(
            title:
                const Text("Livrables", style: TextStyle(color: Colors.white)),
            leading: const Icon(Icons.cloud_upload, color: Colors.white),
            collapsedIconColor: Colors.white,
            iconColor: Colors.white,
            children: [
              ListTile(
                title: const Text("Déposer Journaux"),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const DepotPage(documentType: "Journal de Bord"),
                  ),
                ),
              ),
              ListTile(
                title: const Text("Déposer Bilans"),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const DepotPage(documentType: "Bilan"),
                  ),
                ),
              ),
              ListTile(
                title: const Text("Déposer Rapports"),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const DepotPage(documentType: "Rapport"),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  ListTile _buildTile(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: const TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
