import 'package:flutter/material.dart';
import 'package:pfeproject/screens/depot_page.dart';
import 'package:pfeproject/screens/demande_convention_page.dart';

class Sidebar extends StatelessWidget {
  const Sidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(color: Colors.indigo),
            child: Text('Menu',
                style: TextStyle(color: Colors.white, fontSize: 24)),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Tableau de Bord PFE'),
            onTap: () {
              Navigator.pushNamed(context, '/dashboard');
            },
          ),
          ExpansionTile(
            leading: const Icon(Icons.bookmark),
            title: const Text('Gérer Convention'),
            children: [
              ListTile(
                title: const Text('Demander Convention'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const DemandeConventionPage(),
                  ));
                },
              ),
              ListTile(
                title: const Text('Déposer Convention Signée'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        const DepotPage(documentType: 'Convention Signée'),
                  ));
                },
              ),
            ],
          ),
          ExpansionTile(
            leading: const Icon(Icons.cloud_upload),
            title: const Text('Livrables'),
            children: [
              ListTile(
                title: const Text('Déposer Journaux'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        const DepotPage(documentType: 'Journal de Bord'),
                  ));
                },
              ),
              ListTile(
                title: const Text('Déposer Bilans'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        const DepotPage(documentType: 'Bilan'),
                  ));
                },
              ),
              ListTile(
                title: const Text('Déposer Rapports'),
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) =>
                        const DepotPage(documentType: 'Rapport'),
                  ));
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
