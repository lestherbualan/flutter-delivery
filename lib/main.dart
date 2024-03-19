import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

void main() {
  runApp(
    Directionality(
      textDirection: TextDirection.ltr,
      child: MainApp(),
    ),
  );
}

class MainApp extends StatefulWidget {
  MainApp({Key? key}) : super(key: key);

  @override
  _MainAppState createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  @override
  void initState() {
    super.initState();
    _initMapController();
  }

  late MapController? controller;
  bool _isLoading = true;
  bool _isCollapsed = false;

  Future<void> _initMapController() async {
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

      // Initialize map controller with user's current position
      setState(() {
        controller = MapController(
          initPosition: GeoPoint(
            latitude: position.latitude,
            longitude: position.longitude,
          ),
        );
        _getCurrentCity(position.latitude, position.longitude);
      });
    } catch (e) {
      print("Error initializing map controller: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _getCurrentCity(double lat, double lon) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(lat, lon);
      String city = placemarks.first.locality ?? "Unknown";
      _setMapToCity(city, lat, lon);
    } catch (e) {
      print("Error: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _setMapToCity(String city, double lat, double lon) {
    setState(() {
      _isLoading = false;
    });

    // Define the padding factor for the bounding box
    final double paddingFactor = 0.1;

    // Define the latitude and longitude delta for the padding
    double latDelta = 0.005;
    double lonDelta = 0.005;

    // Calculate the north, south, east, and west boundaries of the bounding box
    double north = lat + latDelta;
    double south = lat - latDelta;
    double east = lon + lonDelta;
    double west = lon - lonDelta;

    // Move the map's camera to focus on the city by adjusting the viewport
    controller?.setStaticPosition(
      [
        GeoPoint(latitude: (north + south) / 2, longitude: (east + west) / 2),
      ],
      "17.0", // Zoom level
    );

    print("Current city: $city");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Map App',
      home: Scaffold(
        body: controller == null
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                children: [
                  OSMFlutter(
                    controller: controller!,
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
                      enableRotationByGesture: false,
                    ),
                  ),
                  Positioned(
                    bottom: _isCollapsed
                        ? -MediaQuery.of(context).size.height * 0.3
                        : 0,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _isCollapsed = !_isCollapsed;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        height: MediaQuery.of(context).size.height * 0.3,
                        decoration: const BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(20.0),
                            topRight: Radius.circular(20.0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
