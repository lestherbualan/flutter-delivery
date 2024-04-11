import 'package:flutter/material.dart';

class ScheduleDeliveryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Schedule Delivery'),
      ),
      body: ListView.builder(
        itemCount: 10, // Example number of items
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            title: Text('Item $index'),
            subtitle: Text('Description of item $index'),
            onTap: () {
              // Add your onTap logic here
              print('Tapped on item $index');
            },
          );
        },
      ),
    );
  }
}
