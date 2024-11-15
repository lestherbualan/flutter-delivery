import 'dart:io';

import 'package:delivery/dashboard_screen/dashboard_screen.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _displayNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _websiteController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final TextEditingController _driverSelfRate = TextEditingController();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  User? user = FirebaseAuth.instance.currentUser;
  final DatabaseReference userRef = FirebaseDatabase.instance.ref('user');
  String imageFileUrl = '';
  File? _image;
  String imageUrl = '';
  Map<dynamic, dynamic> currentUser = {};

  bool _isUsernameDirty = false;
  bool _isPasswordDirty = false;

  List<String>? items;
  String? vehicleType;

  Future getImageUrlFromFireStore() async {
    Reference ref = _storage.ref().child('profile_pictures/${user?.uid}.jpg');

    String imageUrl = await ref.getDownloadURL();
    setState(() {
      imageFileUrl = imageUrl;
    });
  }

  Future<void> _pickImage() async {
    final pickedImage = await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedImage != null) {
        _image = File(pickedImage.path);
      } else {
        print('No image selected.');
      }
    });
  }

  void populateForm() {
    setState(() {
      _emailController.text = currentUser['emailAddress'];
      _displayNameController.text = currentUser['displayName'];
      _driverSelfRate.text = currentUser['driverSelfRating'];
      _usernameController.text = user?.email ?? '';
      _phoneController.text = currentUser['contactNumber'] ?? '';
      if (currentUser.containsKey('vehicle')) {
        vehicleType = currentUser['vehicle'] ?? '';
      } else {
        vehicleType = 'Bike';
      }
    });
  }

  Future getUserFromRealTimeDB() async {
    DatabaseReference currentUserRef = FirebaseDatabase.instance.ref("user/${user?.uid}");
    final snapshot = await currentUserRef.get();
    setState(() {
      currentUser = snapshot.value as Map<dynamic, dynamic>;
    });
    print(currentUser);
    populateForm();
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
      print("Error uploading profile picture: $e");
      // Handle upload error
    }
  }

  void _checkIfUsernameDirty() {
    setState(() {
      _isUsernameDirty = _usernameController.text != currentUser['username'];
    });
  }

  void _checkIfPasswordDirty() {
    setState(() {
      _isPasswordDirty = _passwordController.text != '';
    });
  }

  void checkImageUpdate() async {
    if (_image != null) {
      Reference ref = _storage.ref().child('profile_pictures/${user?.uid}.jpg');
      ref.delete();
      dynamic uploadTask = await ref.putFile(_image!);
      imageUrl = await ref.getDownloadURL();
    }
  }

  @override
  void initState() {
    super.initState();

    items = ['Bike', 'Motorcycle', 'Car'];

    getImageUrlFromFireStore();
    getUserFromRealTimeDB();
    _usernameController.addListener(_checkIfUsernameDirty);
    _passwordController.addListener(_checkIfPasswordDirty);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Builder(builder: (context) {
          return SafeArea(
            child: Column(
              children: [
                Stack(
                  children: [
                    Container(
                      height: 250,
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/authlogo.jpg'),
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Center(
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
                              backgroundColor: Colors.white,
                              backgroundImage: _image != null
                                  ? FileImage(_image!)
                                  : (imageFileUrl.isNotEmpty
                                      ? NetworkImage(imageFileUrl)
                                      : const AssetImage('assets/images/user.png')) as ImageProvider<Object>,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  currentUser['displayName'] ?? 'Loading Name',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      ProfileInputField(
                        labelText: 'Your email',
                        hintText: 'Please enter your email',
                        icon: const Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: Icon(Icons.email_outlined),
                        ),
                        controller: _emailController,
                      ),
                      ProfileInputField(
                        labelText: 'Display Name',
                        hintText: 'Please enter your name',
                        icon: const Padding(
                          padding: EdgeInsets.only(left: 10),
                          child: Icon(Icons.person_3_outlined),
                        ),
                        controller: _displayNameController,
                      ),
                      Visibility(
                        visible: !currentUser['isRider'],
                        child: ProfileInputField(
                          labelText: 'Phone Number',
                          hintText: 'Please enter your contact number',
                          icon: const Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Icon(Icons.phone_android_outlined),
                          ),
                          controller: _phoneController,
                        ),
                      ),
                      Visibility(
                        visible: currentUser['isRider'],
                        child: ProfileInputField(
                          labelText: 'Rate per Request',
                          hintText: 'If empty, default will be 0',
                          icon: Padding(
                              padding: EdgeInsets.only(left: 10),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: Image.asset(
                                  'assets/images/peso.png',
                                  fit: BoxFit.contain, // Ensures proper scaling
                                  color: Color.fromARGB(255, 65, 64, 64),
                                ),
                              )),
                          controller: _driverSelfRate,
                        ),
                      ),
                      Visibility(
                        visible: currentUser['isRider'],
                        child: SizedBox(
                          height: 60, // Adjust this value to reduce the height
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              DropdownButtonHideUnderline(
                                child: DropdownButton2<String>(
                                  isExpanded: true,
                                  hint: Text(
                                    'Select your vehicle',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Theme.of(context).hintColor,
                                    ),
                                  ),
                                  items: items!
                                      .map((String item) => DropdownMenuItem<String>(
                                            value: item,
                                            child: Text(
                                              item,
                                              style: const TextStyle(
                                                fontSize: 14,
                                              ),
                                            ),
                                          ))
                                      .toList(),
                                  value: vehicleType,
                                  onChanged: (String? value) {
                                    setState(() {
                                      vehicleType = value!;
                                    });
                                  },
                                  buttonStyleData: ButtonStyleData(
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    height: 60,
                                    width: 180,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.black,
                                      ),
                                      //color: Colors.white60,
                                    ),
                                  ),
                                  menuItemStyleData: const MenuItemStyleData(
                                    height: 40,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Visibility(
                          visible: false,
                          child: ProfileInputField(
                            labelText: 'User name',
                            hintText: 'Please enter your user name',
                            icon: const Padding(padding: EdgeInsets.only(left: 10), child: Icon(Icons.person_outline)),
                            controller: _usernameController,
                          )),
                      Visibility(
                        visible: false,
                        child: ProfileInputField(
                          labelText: 'Password',
                          hintText: 'Please enter your password',
                          icon: const Padding(padding: EdgeInsets.only(left: 10), child: Icon(Icons.lock_outline)),
                          obscureText: true,
                          controller: _passwordController,
                        ),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: () {
                          final TextEditingController _loginEmailController = TextEditingController();
                          final TextEditingController _loginPasswordController = TextEditingController();

                          DatabaseReference currentUserRef = FirebaseDatabase.instance.ref("user/${user?.uid}");

                          if (_isPasswordDirty || _isUsernameDirty) {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  title: const Text('Verification'),
                                  content: SingleChildScrollView(
                                    child: IntrinsicHeight(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          ProfileInputField(
                                            labelText: 'Email',
                                            hintText: 'Please enter your email',
                                            icon: const Icon(Icons.email_outlined),
                                            controller: _loginEmailController,
                                          ),
                                          ProfileInputField(
                                            labelText: 'Password',
                                            hintText: 'Please enter your password',
                                            icon: const Icon(Icons.lock_outline),
                                            obscureText: true,
                                            controller: _loginPasswordController,
                                          ),
                                          OutlinedButton(
                                            onPressed: () async {
                                              AuthCredential credential = EmailAuthProvider.credential(
                                                email: _loginEmailController.value.text,
                                                password: _loginPasswordController.value.text,
                                              );
                                              await user!.reauthenticateWithCredential(credential);
                                              if (_isUsernameDirty) {
                                                await user!.verifyBeforeUpdateEmail(_usernameController.value.text);
                                                currentUserRef.update({'username': _usernameController.value.text});
                                              }
                                              if (_isPasswordDirty) {
                                                await user!.updatePassword(_passwordController.value.text);
                                              }
                                              Navigator.pop(context);
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(content: Text('Information updated successfully')),
                                              );
                                            },
                                            child: const Padding(
                                              padding: EdgeInsets.all(12.0),
                                              child: Text(
                                                'Confirm',
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
                                  ),
                                );
                              },
                            );
                          }

                          checkImageUpdate();

                          if (currentUser['isRider']) {
                            currentUserRef.update({
                              'emailAddress': _emailController.value.text,
                              'displayName': _displayNameController.value.text,
                              'driverSelfRating': _driverSelfRate.value.text,
                              'contactNumber': _phoneController.value.text != '' ? _phoneController.value.text : '',
                              'vehicle': vehicleType ?? ''
                            });
                          } else {
                            currentUserRef.update({
                              'emailAddress': _emailController.value.text,
                              'displayName': _displayNameController.value.text,
                              'driverSelfRating': _driverSelfRate.value.text,
                              'contactNumber': _phoneController.value.text != '' ? _phoneController.value.text : '',
                            });
                          }

                          user?.updateDisplayName(_displayNameController.value.text);
                          Navigator.pop(context);
                        },
                        child: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  @override
  void dispose() {
    // Dispose controllers to avoid memory leaks
    _emailController.dispose();
    _usernameController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// Custom class for Input fields to customize capturing data using controller and some basic design.
class ProfileInputField extends StatelessWidget {
  final String labelText;
  final String hintText;
  final Widget icon;
  final bool obscureText;
  final TextEditingController controller;

  const ProfileInputField({
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
          hintText: hintText,
          prefixIcon: icon,
          prefixIconConstraints: const BoxConstraints(
            maxHeight: 50, // Set the height constraint
            maxWidth: 50, // Set the width constraint
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }
}
