import 'package:flutter/material.dart';
import '../home_screen/home_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(), // Replace with your home screen widget
    Text('Settings'), // Replace with your settings screen widget
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize:
            const Size.fromHeight(110.0), // Set preferred height here
        child: AppBar(
          toolbarHeight: 110.0,
          title: const Text(
            'Where are you \ngoing today?',
            style: TextStyle(
              fontFamily: 'Montserrat',
              fontWeight: FontWeight.bold,
              fontSize: 30.0,
            ),
          ),
          actions: <Widget>[
            IconButton(
              icon: const Icon(
                  Icons.account_circle), // Placeholder icon for user avatar
              onPressed: () {
                // Add your action here
              },
              iconSize: 40.0,
            ),
          ],
        ),
      ),
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 32), // Increased icon size
            label: '', // Empty label
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, size: 32), // Increased icon size
            label: '', // Empty label
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor:
            Theme.of(context).primaryColor, // Change the selected item color
        unselectedItemColor: Colors.grey, // Change the unselected item color
        showSelectedLabels: false, // Hide selected item labels
        showUnselectedLabels: false, // Hide unselected item labels
        backgroundColor: Colors.white, // Change background color
        type: BottomNavigationBarType
            .fixed, // Fix the type to ensure all icons are displayed
      ),
    );
  }
}
