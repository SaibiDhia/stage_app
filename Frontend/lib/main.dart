import 'package:flutter/material.dart';
import 'package:pfeproject/screens/register_page.dart';
import 'package:pfeproject/screens/splash_screen.dart';
import 'package:pfeproject/screens/login_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
