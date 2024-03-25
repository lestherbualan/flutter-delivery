import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:delivery/map_app/map_controller.dart';

class MapDisplay extends StatefulWidget {
  final MapController controller;
  final MapTapController tapController;
  List<GeoPoint> pointsRoad = [];

  MapDisplay({required this.controller})
      : tapController =
            MapTapController(controller, updateDistance: _updateDistance);

  static void _updateDistance(double distance) {
    if (_mapDisplayState != null) {
      _mapDisplayState!.updateDistance(distance);
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

  void updateDistance(double newDistance) {
    setState(() {
      distance = newDistance;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        OSMFlutter(
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
              roadColor: Colors.yellowAccent,
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
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(16.0),
            height: MediaQuery.of(context).size.height * 0.3,
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20.0),
                topRight: Radius.circular(20.0),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Starting Point: ${widget.pointsRoad.isNotEmpty ? 1 : 0}',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                Text(
                  'End Point: ${widget.pointsRoad.length}',
                  style: const TextStyle(color: Colors.white),
                ),
                Text(
                  'Distance: ${distance.toStringAsFixed(2)} km',
                  style: const TextStyle(color: Colors.white),
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    color: Colors.white,
                  ),
                  child: TextButton(
                    onPressed: () {
                      // Handle button press
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 32.0),
                    ),
                    child: const Text(
                      'Order now',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
