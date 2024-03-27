import 'package:flutter/material.dart';
import './authentication_screen/login_screen.dart';
import './dashboard_screen/dashboard_screen.dart'; // Import the dashboard screen file

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Your App Title',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // Use a named route for navigation
      initialRoute: '/dashboard',
      routes: {
        '/': (context) => const LoginScreen(), // Route to LoginScreen
        '/dashboard': (context) =>
            const DashboardScreen(), // Route to DashboardScreen
      },
    );
  }
}
