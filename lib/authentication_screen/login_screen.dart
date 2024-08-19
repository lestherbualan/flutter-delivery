import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../dashboard_screen/dashboard_screen.dart';
import 'registration_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String emailAddress = '';
    String password = '';
    TextEditingController email = TextEditingController(text: "driver@gmail.com");
    TextEditingController pass = TextEditingController(text: "driver");

    final TextEditingController _emailController = TextEditingController();
    final TextEditingController _passwordController = TextEditingController();

    return Scaffold(
      backgroundColor: const Color(0xFFEDE1D5),
      body: Builder(builder: (context) {
        return Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Image.asset(
                    'assets/images/authlogo.jpeg', // Replace with your image path
                    height: 250, // Adjust height as needed
                    width: double.infinity,
                    fit: BoxFit.fill,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      LoginInputField(
                        labelText: 'Email',
                        hintText: 'Please enter your email',
                        icon: Icons.email_outlined,
                        controller: _emailController,
                      ),
                      LoginInputField(
                        labelText: 'Password',
                        hintText: 'Please enter your password',
                        icon: Icons.lock_outline,
                        obscureText: true,
                        controller: _passwordController,
                      ),
                      SizedBox(height: 20),
                      OutlinedButton(
                        style: OutlinedButton.styleFrom(backgroundColor: Colors.white70),
                        onPressed: () async {
                          FocusScope.of(context).unfocus();
                          try {
                            final UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
                              email: _emailController.value.text,
                              password: _passwordController.value.text,
                            );
                            print(_emailController.value.text);
                            print(_passwordController.value.text);
                          } on FirebaseAuthException catch (e) {
                            if (e.code == 'user-not-found') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('No user found for that email.')),
                              );
                            } else if (e.code == 'wrong-password') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Wrong password provided for that user.')),
                              );
                            } else {
                              print(e);
                            }
                          }
                        },
                        child: const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Text(
                            'Sign In',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 18.0,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      TextButton(
                        onPressed: () {
                          // Navigate to the registration screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                          );
                        },
                        child: const Text('Don\'t have an Account? Sign up here'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}

class LoginInputField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextEditingController controller;

  const LoginInputField({
    required this.labelText,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
          labelText: labelText,
          fillColor: Colors.white70,
          filled: true,
          hintText: hintText,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
