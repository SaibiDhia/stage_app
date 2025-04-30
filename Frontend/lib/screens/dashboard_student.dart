import 'package:flutter/material.dart';
import '../widgets/sidebar.dart';
import '../widgets/timeline.dart';

class DashboardStudent extends StatelessWidget {
  const DashboardStudent({super.key});

  @override
  Widget build(BuildContext context) {
    final timelineSteps = [
      TimelineStep(
          title: 'Lancement Stage PFE', date: '24-02-2025', done: true),
      TimelineStep(title: 'Demande Convention', date: '20-02-2025', done: true),
      TimelineStep(title: 'Remise Plan Travail', date: '--', done: false),
      TimelineStep(title: 'Dépôt Journal', date: '10-03-2025', done: false),
      // ajoute le reste
    ];

    return Scaffold(
      drawer: Sidebar(),
      appBar: AppBar(title: const Text("Tableau de Bord PFE")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Session Juin 2024",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                    child: _statusCard("Traitement Convention", "20-02-2025",
                        "TRAITÉE", Colors.green.shade100)),
                SizedBox(width: 12),
                Expanded(
                    child: _statusCard("Traitement Plan Travail", "18-04-2025",
                        "DÉPOSÉE", Colors.blue.shade100)),
              ],
            ),
            SizedBox(height: 24),
            TimelineWidget(steps: timelineSteps),
          ],
        ),
      ),
    );
  }

  Widget _statusCard(String title, String date, String status, Color bgColor) {
    return Card(
      color: bgColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
            Text("Date : $date"),
            Text("État : $status",
                style: TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
