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

  Future<void> insertUser(UserModel user) async {
    DatabaseReference ref = FirebaseDatabase.instance.ref("user/${user.uid}");
    await ref
        .set(user.toJson())
        .then((value) => print('done'))
        .catchError((onError) => {print(onError)});
  }

  Future<void> _pickImage() async {
    final pickedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedImage != null) {
        _image = File(pickedImage.path);
      } else {
        print('No image selected.');
      }
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
      print("Error uploading profile picture: $e");
      // Handle upload error
    }
  }

  Future<void> _getImage() async {
    final pickedFile =
        await ImagePicker().getImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
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
                    backgroundImage: _image != null
                        ? FileImage(_image!)
                        : const AssetImage('assets/images/user.png')
                            as ImageProvider<Object>,
                  ),
                ),
              ),
            ),
            TextFormField(
              onChanged: (value) {
                setState(() {
                  displayName = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Full Name',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter a Full Name';
                }
                return null;
              },
            ),
            // const SizedBox(height: 15),
            // Row(
            //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //   children: [
            //     Expanded(
            //       child: TextFormField(
            //         onChanged: (value) {
            //           setState(() {
            //             displayName = value;
            //           });
            //         },
            //         decoration: InputDecoration(
            //           labelText: 'Contact Number',
            //           filled: true,
            //           fillColor: Colors.grey[200],
            //           border: OutlineInputBorder(
            //             borderRadius: BorderRadius.circular(10.0),
            //           ),
            //         ),
            //         validator: (value) {
            //           if (value!.isEmpty) {
            //             return 'Please enter a Contact Number';
            //           }
            //           return null;
            //         },
            //       ),
            //     ),
            //     const SizedBox(width: 15),
            //     Expanded(
            //       child: DropdownButtonHideUnderline(
            //         child: DropdownButton2<String>(
            //           isExpanded: true,
            //           hint: Text(
            //             'Gender',
            //             style: TextStyle(
            //               fontSize: 14,
            //               color: Theme.of(context).hintColor,
            //             ),
            //           ),
            //           items: items
            //               .map((String item) => DropdownMenuItem<String>(
            //                     value: item,
            //                     child: Text(
            //                       '$item kg',
            //                       style: const TextStyle(
            //                         fontSize: 14,
            //                       ),
            //                     ),
            //                   ))
            //               .toList(),
            //           value: gender,
            //           onChanged: (String? value) {
            //             setState(() {
            //               gender = value!;
            //             });
            //           },
            //           buttonStyleData: ButtonStyleData(
            //             padding: const EdgeInsets.symmetric(horizontal: 16),
            //             height: 40,
            //             width: 180,
            //             decoration: BoxDecoration(
            //               borderRadius: BorderRadius.circular(14),
            //               border: Border.all(
            //                 color: Colors.black,
            //               ),
            //               color: Colors.white60,
            //             ),
            //           ),
            //           menuItemStyleData: const MenuItemStyleData(
            //             height: 40,
            //           ),
            //         ),
            //       ),
            //     ),
            //   ],
            // ),
            const SizedBox(height: 15),
            TextFormField(
              onChanged: (value) {
                setState(() {
                  username = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Username',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter a username';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            TextFormField(
              onChanged: (value) {
                setState(() {
                  emailAddress = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Email',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter an email';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
            TextFormField(
              onChanged: (value) {
                setState(() {
                  password = value;
                });
              },
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password',
                filled: true,
                fillColor: Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
              validator: (value) {
                if (value!.isEmpty) {
                  return 'Please enter a password';
                }
                return null;
              },
            ),
            const SizedBox(height: 15),
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
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  try {
                    await FirebaseAuth.instance
                        .createUserWithEmailAndPassword(
                      email: emailAddress,
                      password: password,
                    )
                        .then((UserCredential value) async {
                      if (_image != null) {
                        await _uploadProfilePicture(value.user!.uid);
                      }
                      await value.user?.updateDisplayName(displayName);

                      UserModel user = UserModel(
                        username: emailAddress,
                        emailAddress: emailAddress,
                        uid: value.user!.uid,
                        isRider: isRider,
                        profilePictureUrl: imageUrl,
                        displayName: displayName,
                      );

                      insertUser(user).then((value) {
                        print('registration complete');
                        print(imageUrl);
                      });
                    });
                    // Registration successful, show pop-up
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Registration Complete'),
                          content:
                              const Text('Your registration was successful!'),
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
                        const SnackBar(
                            content:
                                Text('The password provided is too weak.')),
                      );
                    } else if (e.code == 'email-already-in-use') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'The account already exists for that email.')),
                      );
                    }
                  } catch (e) {
                    print(e);
                  }
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
