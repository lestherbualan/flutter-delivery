import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:delivery/map_app/map_controller.dart';

class MapDisplay extends StatefulWidget {
  final MapController controller;
  final MapTapController tapController;
  List<GeoPoint> pointsRoad = [];
  final Function(String, String, double, GeoPoint, GeoPoint) onUpdate;

  MapDisplay({required this.controller, required this.onUpdate})
      : tapController = MapTapController(controller,
            updateDistance: _updateDistance,
            updateStartingAddress: _updateStartingAddress,
            updateEndingAddress: _updateEndingAddress,
            updateStartingGeopoint: _updateStartingGeopoint,
            updateEndingGeopoint: _updateEndingGeopoint);

  static void _updateDistance(double distance) {
    if (_mapDisplayState != null) {
      _mapDisplayState!.updateDistance(distance);
    }
  }

  static void _updateStartingAddress(String startingAddress) {
    if (_mapDisplayState != null) {
      _mapDisplayState!.updateStartingAddress(startingAddress);
    }
  }

  static void _updateEndingAddress(String endingAddress) {
    if (_mapDisplayState != null) {
      _mapDisplayState!.updateEndingAddress(endingAddress);
    }
  }

  static void _updateStartingGeopoint(GeoPoint starting) {
    if (_mapDisplayState != null) {
      _mapDisplayState!.updateStartingGeopoint(starting);
    }
  }

  static void _updateEndingGeopoint(GeoPoint ending) {
    if (_mapDisplayState != null) {
      _mapDisplayState!.updateEndingGeopoint(ending);
    }
  }

  static _MapDisplayState? _mapDisplayState;

  @override
  _MapDisplayState createState() {
    _mapDisplayState = _MapDisplayState();
    return _mapDisplayState!;
  }
}

class _MapDisplayState extends State<MapDisplay> {
  double distance = 0.0;
  String start = '';
  String end = '';
  GeoPoint startingGeopoint = GeoPoint(latitude: 0, longitude: 0);
  GeoPoint endingGeopoint = GeoPoint(latitude: 0, longitude: 0);

  @override
  void initState() {
    super.initState();

    // Set the BuildContext for the MapTapController
    widget.tapController.setContext(context);
  }

  void _updateData() {
    widget.onUpdate(start, end, distance, startingGeopoint, endingGeopoint);
  }

  void updateDistance(double newDistance) {
    setState(() {
      distance = newDistance;
      _updateData();
    });
  }

  void updateStartingAddress(String startingAddress) {
    setState(() {
      start = startingAddress;
      _updateData();
    });
  }

  void updateEndingAddress(String endingAddress) {
    setState(() {
      end = endingAddress;
      _updateData();
    });
  }

  void updateStartingGeopoint(GeoPoint starting) {
    setState(() {
      startingGeopoint = starting;
      _updateData();
    });
  }

  void updateEndingGeopoint(GeoPoint ending) {
    setState(() {
      endingGeopoint = ending;
      _updateData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        OSMFlutter(
          mapIsLoading: const Center(child: CircularProgressIndicator()),
          controller: widget.tapController.controller,
          osmOption: OSMOption(
            zoomOption: const ZoomOption(
              initZoom: 18,
              minZoomLevel: 3,
              maxZoomLevel: 19,
              stepZoom: 1.0,
            ),
            showZoomController: true,
            userLocationMarker: UserLocationMaker(
              personMarker: const MarkerIcon(
                icon: Icon(
                  Icons.location_history_rounded,
                  color: Colors.red,
                  size: 48,
                ),
              ),
              directionArrowMarker: const MarkerIcon(
                icon: Icon(
                  Icons.double_arrow,
                  size: 48,
                ),
              ),
            ),
            roadConfiguration: const RoadOption(
              roadColor: Colors.white,
            ),
            markerOption: MarkerOption(
              defaultMarker: const MarkerIcon(
                icon: Icon(
                  Icons.person_pin_circle,
                  color: Colors.blue,
                  size: 56,
                ),
              ),
            ),
            enableRotationByGesture: false,
          ),
        ),
      ],
    );
  }
}
