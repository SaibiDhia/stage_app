import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../widgets/sidebar.dart';
import '../widgets/timeline.dart';

// Plugin de notif local (à déclarer globalement dans main.dart)
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class DashboardStudent extends StatefulWidget {
  const DashboardStudent({super.key});

  @override
  State<DashboardStudent> createState() => _DashboardStudentState();
}

class _DashboardStudentState extends State<DashboardStudent> {
  @override
  void initState() {
    super.initState();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'channel_id',
              'Notifications',
              importance: Importance.max,
              priority: Priority.high,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final timelineSteps = [
      TimelineStep(
          title: 'Lancement Stage PFE', date: '24-02-2025', done: true),
      TimelineStep(title: 'Demande Convention', date: '20-02-2025', done: true),
      TimelineStep(title: 'Remise Plan Travail', date: '--', done: false),
      TimelineStep(title: 'Dépôt Journal', date: '10-03-2025', done: false),
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
                      "TRAITÉE", Colors.green.shade100),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _statusCard("Traitement Plan Travail", "18-04-2025",
                      "DÉPOSÉE", Colors.blue.shade100),
                ),
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
