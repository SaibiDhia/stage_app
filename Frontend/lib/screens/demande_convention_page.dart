import 'package:flutter/material.dart';

class DemandeConventionPage extends StatelessWidget {
  const DemandeConventionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Demander Convention')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            '📧 Pour recevoir votre convention, veuillez envoyer un mail au service des stages :\n\nstages@esprit.tn',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
        ),
      ),
    );
  }
}
