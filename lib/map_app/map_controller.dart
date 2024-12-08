import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geodesy/geodesy.dart';
import 'package:geocoding/geocoding.dart';

class MapTapController {
  final MapController controller;
  final Function(double)? updateDistance;
  final Function(String)? updateStartingAddress;
  final Function(String)? updateEndingAddress;
  final Function(GeoPoint)? updateStartingGeopoint;
  final Function(GeoPoint)? updateEndingGeopoint;
  final List<GeoPoint> pointsRoad = [];
  final Geodesy geodesy = Geodesy();

  BuildContext? _context;

  MapTapController(this.controller,
      {this.updateDistance,
      this.updateStartingAddress,
      this.updateEndingAddress,
      this.updateStartingGeopoint,
      this.updateEndingGeopoint}) {
    controller.listenerMapSingleTapping.addListener(_handleMapTap);
  }

  // Method to set the context
  void setContext(BuildContext context) {
    _context = context;
  }

  void _handleMapTap() async {
    if (controller.listenerMapSingleTapping.value != null) {
      GeoPoint tappedPoint = controller.listenerMapSingleTapping.value!;
      if (pointsRoad.isEmpty) {
        pointsRoad.add(tappedPoint);
        getCoordinateInfo(pointsRoad[0].latitude, pointsRoad[0].longitude).then((value) {
          updateStartingAddress?.call(value);
          updateStartingGeopoint?.call(tappedPoint);
        });
        await controller.addMarker(
          tappedPoint,
          markerIcon: const MarkerIcon(
            icon: Icon(
              Icons.person_pin_circle,
              color: Colors.redAccent,
              size: 48,
            ),
          ),
        );
      } else {
        if (pointsRoad.length <= 1) {
          pointsRoad.add(tappedPoint);

          double firstDistance = _calculateDistance();
          if (!(firstDistance < 1.0)) {
            getCoordinateInfo(pointsRoad[1].latitude, pointsRoad[1].longitude).then((value) {
              updateEndingAddress?.call(value);
              updateEndingGeopoint?.call(tappedPoint);
            });
            await controller.addMarker(
              tappedPoint,
              markerIcon: const MarkerIcon(
                icon: Icon(
                  Icons.person_pin_circle,
                  color: Colors.blueAccent,
                  size: 48,
                ),
              ),
            );
            controller.drawRoad(
              pointsRoad.first,
              pointsRoad.last,
              roadType: RoadType.bike,
              intersectPoint: pointsRoad.sublist(1),
              roadOption: const RoadOption(
                roadColor: Colors.blue,
                roadWidth: 10,
                zoomInto: true,
              ),
            );
            double distance = _calculateDistance();
            updateDistance?.call(distance);
          } else {
            pointsRoad.removeLast();
            showDialog(
              context: _context!,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Invalid Point'),
                  content: const Text('The points are too close to each other. Please select a point further away.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop(); // Close the dialog
                      },
                      child: const Text('OK'),
                    ),
                  ],
                );
              },
            );
          }
        }
      }
    }
  }

  double _calculateDistance() {
    GeoPoint start = pointsRoad[pointsRoad.length - 2];
    GeoPoint end = pointsRoad[pointsRoad.length - 1];
    LatLng startLatLng = LatLng(start.latitude, start.longitude);
    LatLng endLatLng = LatLng(end.latitude, end.longitude);
    double distance = geodesy.distanceBetweenTwoGeoPoints(startLatLng, endLatLng) as double;
    return distance / 1000;
  }

  Future<String> getCoordinateInfo(double latitude, double longitude) async {
    String street = '';
    String locality = '';
    String subadministrative = '';
    try {
      // Create a new instance of GeocodingPlatform
      GeocodingPlatform? geocodingPlatform = GeocodingPlatform.instance;

      // Get placemarks using the new instance
      List<Placemark> placemarks = await geocodingPlatform!.placemarkFromCoordinates(latitude, longitude);

      Placemark firstPlacemark = placemarks.first;
      street = firstPlacemark.street ?? '';
      locality = firstPlacemark.locality ?? '';
      subadministrative = firstPlacemark.subAdministrativeArea ?? '';
    } catch (e) {
      return e.toString();
    }
    return '$street, $locality $subadministrative';
  }

  void dispose() {
    controller.listenerMapSingleTapping.removeListener(_handleMapTap);
  }
}
