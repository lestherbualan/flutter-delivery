import 'package:delivery/driver/driver_map.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';

import '../model/order.dart';

class DriverMapInitializer extends StatefulWidget {
  final Order orderInformation;
  const DriverMapInitializer({super.key, required this.orderInformation});

  @override
  State<DriverMapInitializer> createState() => _DriverMapInitializerState();
}

class _DriverMapInitializerState extends State<DriverMapInitializer> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MapController>(
      future: _initMapController(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else {
          return DriverMap(
            controller: snapshot.data!,
            orderInformation: widget.orderInformation,
          );
          //return Text('hello map initializer');
        }
      },
    );
  }

  Future<MapController> _initMapController() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse &&
            permission != LocationPermission.always) {
          throw Exception('Location permission not granted');
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return MapController(
          initPosition: GeoPoint(
        latitude: position.latitude,
        longitude: position.longitude,
      ));
    } catch (e) {
      print("Error initializing map controller: $e");
      rethrow;
    }
  }
}
