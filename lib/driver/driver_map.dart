import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:delivery/model/order.dart';

class DriverMap extends StatefulWidget {
  final Order orderInformation;
  final MapController controller;

  const DriverMap({
    Key? key,
    required this.orderInformation,
    required this.controller,
  }) : super(key: key);

  @override
  State<DriverMap> createState() => _DriverMapState();
}

class _DriverMapState extends State<DriverMap> {
  DatabaseReference ref = FirebaseDatabase.instance.ref("order");
  bool accepted = false;
  Color containerColor = Colors.blue;
  User? user = FirebaseAuth.instance.currentUser;

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

  void _acceptOrder() async {
    await ref.update({
      '${widget.orderInformation.key}/status': 'ACCEPTED',
      '${widget.orderInformation.key}/driverId': user?.uid,
    });
    setState(() {
      accepted = true;
      containerColor = Colors.lightBlue; // Change container color to light blue
    });
  }

  void _completeOrder() async {
    await ref.update({
      '${widget.orderInformation.key}/status': 'COMPLETED',
    });

    setState(() {
      containerColor = Colors.lightBlue; // Change container color to light blue
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
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
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: accepted
                  ? 200
                  : null, // Adjust height based on acceptance status
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: containerColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(10.0),
                  topRight: Radius.circular(10.0),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Your content here
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white60,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        'From : ${widget.orderInformation.startingGeoPoint['location']}',
                        style: const TextStyle(
                            color: Colors.black, fontSize: 18.0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white60,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.all(10.0),
                      child: Text(
                        'To : ${widget.orderInformation.endingGeoPoint['location']}',
                        style: const TextStyle(
                            color: Colors.black, fontSize: 18.0),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Container for Distance
                        Container(
                          width: MediaQuery.of(context).size.width *
                              0.4, // Adjust width as needed
                          decoration: BoxDecoration(
                            color: Colors.white60,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Distance:',
                                style: TextStyle(
                                    color: Colors.black, fontSize: 18.0),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${double.parse(widget.orderInformation.distance).toStringAsFixed(3)}km',
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 20.0),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(
                            width: 8), // Add spacing between containers
                        // Container for Rate
                        Container(
                          width: MediaQuery.of(context).size.width *
                              0.4, // Adjust width as needed
                          decoration: BoxDecoration(
                            color: Colors.white60,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.all(10.0),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rate:',
                                style: TextStyle(
                                    color: Colors.black, fontSize: 18.0),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '70 PHP', // Replace 'rate' with your actual rate value
                                style: TextStyle(
                                    color: Colors.black, fontSize: 20.0),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    if (!accepted) // Only show Accept and Close buttons if order is not accepted
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: _acceptOrder,
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
                          const SizedBox(width: 10),
                          Expanded(
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
                    if (accepted) // Show Complete and Cancel buttons if order is accepted
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                _completeOrder();
                                Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.all(15.0),
                              ),
                              child: const Text(
                                'Complete',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                // Handle cancellation logic
                                Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                backgroundColor: Colors.white,
                                padding: const EdgeInsets.all(15.0),
                              ),
                              child: const Text(
                                'Cancel',
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
          ),
        ],
      ),
    );
  }
}
