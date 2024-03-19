import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'map_display.dart';

class MapInitializer extends StatelessWidget {
  const MapInitializer({super.key});

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
          return MapDisplay(controller: snapshot.data!);
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
        ),
      );
    } catch (e) {
      print("Error initializing map controller: $e");
      rethrow;
    }
  }
}
