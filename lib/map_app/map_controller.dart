import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geodesy/geodesy.dart';

class MapTapController {
  final MapController controller;
  final Function(double)? updateDistance;
  final List<GeoPoint> pointsRoad = [];
  final Geodesy geodesy = Geodesy();

  MapTapController(this.controller, {this.updateDistance}) {
    controller.listenerMapSingleTapping.addListener(_handleMapTap);
  }

  void _handleMapTap() async {
    if (controller.listenerMapSingleTapping.value != null) {
      GeoPoint tappedPoint = controller.listenerMapSingleTapping.value!;
      if (pointsRoad.isEmpty) {
        pointsRoad.add(tappedPoint);
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
        pointsRoad.add(tappedPoint);
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
      }
    }
  }

  double _calculateDistance() {
    GeoPoint start = pointsRoad[pointsRoad.length - 2];
    GeoPoint end = pointsRoad[pointsRoad.length - 1];
    LatLng startLatLng = LatLng(start.latitude, start.longitude);
    LatLng endLatLng = LatLng(end.latitude, end.longitude);
    double distance =
        geodesy.distanceBetweenTwoGeoPoints(startLatLng, endLatLng) as double;
    return distance / 1000;
  }

  void dispose() {
    controller.listenerMapSingleTapping.removeListener(_handleMapTap);
  }
}
