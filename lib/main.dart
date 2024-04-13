import 'package:delivery/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import './authentication_screen/login_screen.dart';
import './dashboard_screen/dashboard_screen.dart'; // Import the dashboard screen file

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator(); // Show loading indicator while checking authentication state
        }
        if (snapshot.hasData && snapshot.data != null) {
          // User is logged in, navigate to dashboard screen
          print('currently logged in');
          return const MaterialApp(
            title: 'Your App Title',
            home: DashboardScreen(),
          );
        } else {
          // User is not logged in, navigate to login screen
          return const MaterialApp(
            title: 'Your App Title',
            home: LoginScreen(),
          );
        }
      },
    );
  }
}
