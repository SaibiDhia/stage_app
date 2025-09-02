import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart'; // pour kIsWeb
import 'package:pfeproject/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';

import 'package:pfeproject/screens/register_page.dart';
import 'package:pfeproject/screens/splash_screen.dart';
import 'package:pfeproject/screens/login_page.dart';

// 📢 Plugin pour affichage local de la notification
final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// 🔄 Notification en arrière-plan
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('📩 Notification en arrière-plan: ${message.notification?.title}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  if (!kIsWeb) {
    // 🔐 Récupérer le token FCM (utile aussi pour Android)
    final fcmToken = await FirebaseMessaging.instance.getToken();
    print('🔐 FCM Token: $fcmToken');

    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 🔔 Notifications locales (Android uniquement)
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await flutterLocalNotificationsPlugin.initialize(initSettings);
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      // Si l’utilisateur est connecté, renvoie le nouveau token au backend
      final prefs = await SharedPreferences.getInstance();
      final jwt = prefs.getString('token');
      final userId = prefs.getInt('userId');
      if (jwt != null && userId != null) {
        await registerFcmToken(userId: userId, jwt: jwt);
      }
      if (!kIsWeb) {
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
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stage App',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
