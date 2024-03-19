import 'package:flutter/material.dart';
import 'map_initializer.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Map App',
      home: Scaffold(
        body: MapInitializer(),
      ),
    );
  }
}
