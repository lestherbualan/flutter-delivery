import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

class MapDisplay extends StatefulWidget {
  final MapController controller;
  List<GeoPoint> pointsRoad = [];

  MapDisplay({super.key, required this.controller});

  @override
  _MapDisplayState createState() => _MapDisplayState();
}

class _MapDisplayState extends State<MapDisplay> {
  @override
  void initState() {
    super.initState();
    widget.controller.listenerMapSingleTapping.addListener(() async {
      if (widget.controller.listenerMapSingleTapping.value != null) {
        if (widget.pointsRoad.isEmpty) {
          widget.pointsRoad
              .add(widget.controller.listenerMapSingleTapping.value!);
          await widget.controller
              .addMarker(widget.controller.listenerMapSingleTapping.value!,
                  markerIcon: const MarkerIcon(
                    icon: Icon(
                      Icons.person_pin_circle,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                  ));
        } else {
          widget.pointsRoad
              .add(widget.controller.listenerMapSingleTapping.value!);
          await widget.controller
              .addMarker(widget.controller.listenerMapSingleTapping.value!,
                  markerIcon: const MarkerIcon(
                    icon: Icon(
                      Icons.person_pin_circle,
                      color: Colors.blueAccent,
                      size: 48,
                    ),
                  ));
          widget.controller.drawRoad(
              widget.pointsRoad.first, widget.pointsRoad.last,
              roadType: RoadType.bike,
              intersectPoint: widget.pointsRoad
                  .getRange(1, widget.pointsRoad.length - 1)
                  .toList(),
              roadOption: const RoadOption(
                  roadColor: Colors.blue, roadWidth: 10, zoomInto: true));
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        OSMFlutter(
          controller: widget.controller,
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
        //black rectangle bellow
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
                const Text(
                  'Starting Point: 0',
                  style: TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 8),
                const Text(
                  'End Point: 0',
                  style: TextStyle(color: Colors.white),
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
