import 'dart:io';

import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../model/user.dart';
import 'package:firebase_storage/firebase_storage.dart';

class RegistrationScreen extends StatelessWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFFEDE1D5), // Background color set to #ede1d5
      body: Center(child: SingleChildScrollView(child: RegistrationForm())),
    );
  }
}

class RegistrationForm extends StatefulWidget {
  const RegistrationForm({Key? key}) : super(key: key);

  @override
  _RegistrationFormState createState() => _RegistrationFormState();
}

class _RegistrationFormState extends State<RegistrationForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String username = '';
  String emailAddress = '';
  String password = '';
  bool isRider = false;
  String displayName = '';
  File? _image; // File variable to store the selected image
  final FirebaseStorage _storage = FirebaseStorage.instance;
  String imageUrl = '';
  String gender = '';
  final List<String> items = [
    "Male",
    "Female",
  ];

  final RegExp _gmailRegex = RegExp(r'^[\w-\.]+@gmail\.com$');

  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  Future<void> insertUser(UserModel user) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("user/${user.uid}");
    await ref.set(user.toJson()).then((value) => print('done')).catchError((onError) => {print(onError)});
  }

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedImage != null) {
        _image = File(pickedImage.path);
      } else {}
    });
  }

  Future<void> _uploadProfilePicture(String userId) async {
    try {
      // Upload the image to Firebase Storage
      Reference ref = _storage.ref().child('profile_pictures/$userId.jpg');
      dynamic uploadTask = await ref.putFile(_image!);

      // Get download URL of uploaded image

      imageUrl = await ref.getDownloadURL();

      // Update user profile with the image URL (optional)
      // You may store this URL in Firestore or Realtime Database along with user details
    } catch (e) {
      // Handle upload error
    }
  }

  Future<void> _getImage() async {
    final pickedFile = await ImagePicker().getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {}
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: InkWell(
                onTap: _pickImage, // Open image picker when tapped
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.transparent,
                  ),
                  padding: const EdgeInsets.all(8),
                  child: CircleAvatar(
                    radius: 80,
                    backgroundColor: Colors.transparent,
                    backgroundImage:
                        _image != null ? FileImage(_image!) : const AssetImage('assets/images/user.png') as ImageProvider<Object>,
                  ),
                ),
              ),
            ),
            RegistrationInputField(
                labelText: 'Full Name',
                hintText: 'Please enter your Full Name',
                icon: Icons.contact_page_outlined,
                controller: _fullNameController),
            RegistrationInputField(
                labelText: 'Username',
                hintText: 'Please enter your username',
                icon: Icons.person_2_outlined,
                controller: _usernameController),
            RegistrationInputField(
                labelText: 'Phone Number',
                hintText: 'Please enter your phone number',
                icon: Icons.phone_android_outlined,
                controller: _phoneController),
            RegistrationInputField(
              labelText: 'Email Address',
              hintText: 'Please enter your email address',
              icon: Icons.email_outlined,
              controller: _emailController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter an email address';
                } else if (!_gmailRegex.hasMatch(value)) {
                  return 'Please enter a valid Gmail address';
                }
                return null;
              },
            ),
            RegistrationInputField(
                labelText: 'Password',
                hintText: 'Please enter your password',
                obscureText: true,
                icon: Icons.lock_outline,
                controller: _passwordController),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Are you a Rider?',
                  style: TextStyle(fontSize: 16),
                ),
                Switch(
                  value: isRider,
                  onChanged: (bool value) {
                    setState(() {
                      isRider = value;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 15),
            OutlinedButton(
              style: OutlinedButton.styleFrom(backgroundColor: Colors.white70),
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                      email: _emailController.value.text,
                      password: _passwordController.value.text,
                    )
                        .then((UserCredential value) async {
                      if (_image != null) {
                        await _uploadProfilePicture(value.user!.uid);
                      }
                      await value.user?.updateDisplayName(_fullNameController.value.text);

                      UserModel user = UserModel(
                        username: _emailController.value.text,
                        emailAddress: _emailController.value.text,
                        uid: value.user!.uid,
                        isRider: isRider,
                        profilePictureUrl: imageUrl,
                        displayName: _fullNameController.value.text,
                        online: true,
                        driverRating: 0,
                        firstOpen: true,
                        driverSelfRating: '0',
                        contactNumber: _phoneController.value.text,
                      );

                      insertUser(user).then((value) {});
                    });
                    // Registration successful, show pop-up
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Registration Complete'),
                          content: const Text('Your registration was successful!'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  } on FirebaseAuthException catch (e) {
                    if (e.code == 'weak-password') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('The password provided is too weak.')),
                      );
                    } else if (e.code == 'email-already-in-use') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('The account already exists for that email.')),
                      );
                    }
                  } catch (e) {}
                } else {
                  final errorMessage = (_formKey.currentState!.validate()) as String;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMessage)),
                  );
                }
              },
              child: const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  'Register',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 18.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RegistrationInputField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const RegistrationInputField(
      {required this.labelText,
      required this.hintText,
      required this.icon,
      this.obscureText = false,
      required this.controller,
      this.validator});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        validator: validator,
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
