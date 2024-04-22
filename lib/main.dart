import 'package:delivery/driver/driver_dashboard.dart';
import 'package:delivery/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
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
  Future<dynamic> getUserDB(AsyncSnapshot snapshot) async {
    try {
      final ref = FirebaseDatabase.instance.ref();
      final user = await ref.child('user/${snapshot.data?.uid}').get();
      final userData = user.value;

      print('userData type: ${userData.runtimeType}');
      print('userData value: $userData');

      if (userData == null || userData is! Map<Object?, Object?>) {
        print('userData is null or not a Map<Object?, Object?>');
        return;
      }

      // Convert the keys and values to the desired types
      final Map<String, dynamic> userDataMap = {};
      userData.forEach((key, value) {
        if (key is String) {
          final dynamicKey = key;
          final dynamicValue = value;
          userDataMap[dynamicKey] = dynamicValue;
        }
      });

      bool isRider = userDataMap['isRider'];

      return isRider;
    } catch (e) {
      print('Error fetching user data: $e');
    }
  }

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
          return FutureBuilder<dynamic>(
            future: getUserDB(snapshot),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else {
                if (snapshot.hasData && snapshot.data!) {
                  print(snapshot.data);
                  // User is authenticated in your database
                  return const MaterialApp(
                    title: 'Driver',
                    home: DriverDashboard(),
                  );
                } else {
                  // User is not authenticated in your database
                  return const MaterialApp(
                    title: 'Your App Title',
                    home: DashboardScreen(),
                  );
                }
              }
            },
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
