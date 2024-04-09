import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import './authentication_screen/login_screen.dart';
import './dashboard_screen/dashboard_screen.dart'; // Import the dashboard screen file
import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_ui_auth/firebase_ui_auth.dart';

Future<void> main() async {
  runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final providers = [EmailAuthProvider()];
    return MaterialApp(
      title: 'Your App Title',
      home: SignInScreen(
        providers: providers,
        actions: [
          AuthStateChangeAction<SignedIn>((context, state) {
            Navigator.pushReplacementNamed(context, '/profile');
          }),
        ],
      ),
    );
  }
}
