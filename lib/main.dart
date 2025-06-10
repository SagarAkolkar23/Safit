import 'package:flutter/material.dart';
import 'package:safit/distressBridge.dart';
import 'package:safit/screens/HomePage.dart';
import 'package:safit/screens/login.dart';
import 'package:safit/screens/profilePage.dart';
import 'package:safit/screens/signUp.dart';
import 'package:safit/screens/splashScreen.dart' hide EmergencyLoginPage, HomePage;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures channel + engine is ready

  registerDistressChannel(); // Register MethodChannel AFTER ensuring Flutter binding

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => EmergencyLoginPage(),
        '/signup': (context) => const SignUpPage(),
        '/home': (context) => const HomePage(),
        '/profile': (context) => const ProfilePage(),
      },
    );
  }
}