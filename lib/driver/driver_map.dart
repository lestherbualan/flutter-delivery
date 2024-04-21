import 'package:delivery/model/order.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';

class DriverMap extends StatefulWidget {
  final Order orderInformation;
  final MapController controller;
  const DriverMap(
      {super.key, required this.orderInformation, required this.controller});

  @override
  State<DriverMap> createState() => _DriverMapState();
}

class _DriverMapState extends State<DriverMap> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 500), () {
      widget.controller.addMarker(
        GeoPoint(
          latitude: double.parse(
              widget.orderInformation.startingGeoPoint['latitude']),
          longitude: double.parse(
              widget.orderInformation.startingGeoPoint['longitude']),
        ),
        markerIcon: const MarkerIcon(
          icon: Icon(
            Icons.person_pin_circle,
            color: Colors.redAccent,
            size: 48,
          ),
        ),
      );
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      widget.controller.addMarker(
        GeoPoint(
          latitude:
              double.parse(widget.orderInformation.endingGeoPoint['latitude']),
          longitude:
              double.parse(widget.orderInformation.endingGeoPoint['longitude']),
        ),
        markerIcon: const MarkerIcon(
          icon: Icon(
            Icons.person_pin_circle,
            color: Colors.blueAccent,
            size: 48,
          ),
        ),
      );
    });
    Future.delayed(const Duration(milliseconds: 500), () {
      widget.controller.drawRoad(
        GeoPoint(
          latitude: double.parse(
              widget.orderInformation.startingGeoPoint['latitude']),
          longitude: double.parse(
              widget.orderInformation.startingGeoPoint['longitude']),
        ),
        GeoPoint(
          latitude:
              double.parse(widget.orderInformation.endingGeoPoint['latitude']),
          longitude:
              double.parse(widget.orderInformation.endingGeoPoint['longitude']),
        ),
        roadType: RoadType.bike,
        roadOption: const RoadOption(
          roadColor: Colors.blue,
          roadWidth: 10,
          zoomInto: true,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          OSMFlutter(
            //here
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
          //rectangular container
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 200,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(10.0),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Your content here
                  Text(
                    'From : ${widget.orderInformation.startingGeoPoint['location']}',
                    style: TextStyle(color: Colors.black),
                  ),

                  Text(
                    'To : ${widget.orderInformation.endingGeoPoint['location']}',
                    style: TextStyle(color: Colors.black),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Distance: ${double.parse(widget.orderInformation.distance).toStringAsFixed(3)}km',
                    style: TextStyle(color: Colors.black),
                  ),
                  // Add more content if needed
                  Row(
                    children: [
                      Expanded(
                        // Order Now Button occupies all available space
                        child: TextButton(
                          onPressed: () {},
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.all(15.0),
                          ),
                          child: const Text(
                            'Accept',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10), // Add spacing between buttons
                      Expanded(
                        // Order Now Button occupies all available space
                        child: TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.all(15.0),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
