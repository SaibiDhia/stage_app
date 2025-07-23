import 'package:flutter/material.dart';
import 'package:pfeproject/screens/admin/web/admin_document_web_page.dart';
import 'package:pfeproject/screens/admin/web/admin_convention_web_page.dart';

class AdminDashboardWeb extends StatefulWidget {
  const AdminDashboardWeb({super.key});

  @override
  State<AdminDashboardWeb> createState() => _AdminDashboardWebState();
}

class _AdminDashboardWebState extends State<AdminDashboardWeb> {
  int selectedIndex = 0;

  final List<Widget> pages = const [
    AdminDocumentWebPage(),
    AdminConventionWebPage(),
  ];

  final List<String> titles = const [
    'Validation des Documents',
    'Gestion des Conventions',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(titles[selectedIndex]),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.indigo),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.admin_panel_settings,
                      size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text('Espace Admin',
                      style: TextStyle(fontSize: 20, color: Colors.white)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.file_present),
              title: const Text('Validation Documents'),
              selected: selectedIndex == 0,
              onTap: () {
                setState(() => selectedIndex = 0);
                Navigator.pop(context); // Ferme le drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.assignment_turned_in),
              title: const Text('Gestion Conventions'),
              selected: selectedIndex == 1,
              onTap: () {
                setState(() => selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Déconnexion'),
              onTap: () {
                // Logique de logout (optionnelle)
                Navigator.of(context).pushReplacementNamed('/');
              },
            ),
          ],
        ),
      ),
      body: pages[selectedIndex],
    );
  }
}
