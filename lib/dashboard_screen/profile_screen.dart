import 'package:flutter/material.dart';

void main() {
  runApp(ProfileScreen());
}

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Color(0xFFEDE1D5),
        appBar: AppBar(
          title: const Text('User Profile'),
          backgroundColor: Colors.white,
        ),
        body: ProfileBody(),
      ),
    );
  }
}

class ProfileBody extends StatefulWidget {
  @override
  _ProfileBodyState createState() => _ProfileBodyState();
}

class _ProfileBodyState extends State<ProfileBody> {
  bool _isEditing = false;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _roleController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _bioController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundImage: AssetImage(
                'assets/profile_image.jpg'), // Replace with your image path
          ),
          const SizedBox(height: 20),
          _isEditing
              ? _buildEditableField(_nameController, 'Name')
              : _buildReadOnlyField('John Doe'),
          const SizedBox(height: 8),
          _isEditing
              ? _buildEditableField(_roleController, 'Role')
              : _buildReadOnlyField('Software Developer'),
          const SizedBox(height: 20),
          Divider(
            height: 20,
            thickness: 2,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          const Text(
            'Contact Information',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _isEditing
              ? _buildEditableField(_emailController, 'Email')
              : _buildReadOnlyField('john.doe@example.com'),
          const SizedBox(height: 5),
          _isEditing
              ? _buildEditableField(_phoneController, 'Phone')
              : _buildReadOnlyField('+1234567890'),
          const SizedBox(height: 20),
          Divider(
            height: 20,
            thickness: 2,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 20),
          const Text(
            'Bio',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          _isEditing
              ? _buildEditableField(_bioController, 'Bio')
              : _buildReadOnlyField(
                  'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                ),
          const SizedBox(height: 20),
          if (!_isEditing)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isEditing = true;
                  _nameController.text =
                      'John Doe'; // Populate with current data
                  _roleController.text =
                      'Software Developer'; // Populate with current data
                  _emailController.text =
                      'john.doe@example.com'; // Populate with current data
                  _phoneController.text =
                      '+1234567890'; // Populate with current data
                  _bioController.text =
                      'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.'; // Populate with current data
                });
              },
              child: const Text('Edit'),
            ),
          if (_isEditing)
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _isEditing = false;
                });
                // Here you can save the updated data to your backend or local storage
              },
              child: const Text('Save'),
            ),
        ],
      ),
    );
  }

  Widget _buildReadOnlyField(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 16,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildEditableField(
      TextEditingController controller, String hintText) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hintText,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _roleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
