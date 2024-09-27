import 'package:delivery/commons/sharedData.dart';
import 'package:delivery/dashboard_screen/dashboard_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  Position? position;
  final TextEditingController _searchController = TextEditingController();
  MapController? _mapController;

  final ValueNotifier<List<SearchInfo>> suggestionsNotifier = ValueNotifier([]);
  String? currentCountryCode;

  late GeoPoint tappedPoint;

  @override
  void initState() {
    initPosition();
    _getCurrentCountryCode();
    super.initState();
  }

  Future<void> initPosition() async {
    position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    // _mapController =
    //     MapController.withPosition(initPosition: GeoPoint(latitude: position!.latitude, longitude: position!.longitude));
    _mapController = MapController(
        areaLimit: const BoundingBox.world(),
        initPosition: GeoPoint(latitude: position!.latitude, longitude: position!.longitude));
    _mapController?.listenerMapSingleTapping.addListener(_onMapEvent);
  }

  void _onMapEvent() async {
    tappedPoint = _mapController!.listenerMapSingleTapping.value!;
    print(tappedPoint);
    await _mapController?.addMarker(
      tappedPoint,
      markerIcon: const MarkerIcon(
        icon: Icon(
          Icons.person_pin_circle,
          color: Colors.redAccent,
          size: 48,
        ),
      ),
    );
  }

  Future<void> _getCurrentCountryCode() async {
    print('_getCurrentCountryCode is called');
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position!.latitude,
        position!.longitude,
      );
      print(placemarks);
      if (placemarks.isNotEmpty) {
        setState(() {
          currentCountryCode = placemarks.first.isoCountryCode;
        });
      }
      print('here');
      print(currentCountryCode);
    } catch (e) {
      print("Error getting country code: $e");
    }
  }

  void searchPlaces(String query) async {
    if (query.isNotEmpty) {
      try {
        final results = await addressSuggestion(
          query,
          limitInformation: 5,
        );
        suggestionsNotifier.value = results; // Update the ValueNotifier
      } catch (e) {
        print("Error searching places: $e");
      }
    } else {
      suggestionsNotifier.value.clear(); // Clear the suggestions without rebuilding the map
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FutureBuilder(
            future: initPosition(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              } else {
                return OSMFlutter(
                  mapIsLoading: const Center(child: CircularProgressIndicator()),
                  controller: _mapController!,
                  osmOption: OSMOption(
                    zoomOption: const ZoomOption(
                      initZoom: 18,
                      minZoomLevel: 16,
                      maxZoomLevel: 18,
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
                );
              }
            },
          ),
          Positioned(
            top: 60.0,
            left: 10.0,
            right: 10.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 4.0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search location',
                      border: InputBorder.none,
                      suffixIcon: Icon(Icons.search),
                    ),
                    onChanged: searchPlaces,
                  ),
                  ValueListenableBuilder<List<SearchInfo>>(
                    valueListenable: suggestionsNotifier,
                    builder: (context, suggestions, child) {
                      return suggestions.isNotEmpty
                          ? Container(
                              height: 150.0,
                              child: ListView.builder(
                                itemCount: suggestions.length,
                                itemBuilder: (context, index) {
                                  final suggestion = suggestions[index];
                                  return ListTile(
                                    title: Text(
                                      suggestion.address.toString(),
                                    ),
                                    onTap: () {
                                      if (suggestion.point != null) {
                                        _mapController!.goToLocation(suggestion.point!);
                                      }
                                      FocusScope.of(context).unfocus();
                                    },
                                  );
                                },
                              ),
                            )
                          : const SizedBox.shrink();
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              children: [
                FloatingActionButton(
                  heroTag: 'Okay',
                  shape: CircleBorder(),
                  onPressed: () {
                    context.read<SharedData>().sharedVariable = tappedPoint;
                    Navigator.pop(context);
                  },
                  backgroundColor: Colors.green,
                  child: const Icon(Icons.check),
                ),
                const SizedBox(height: 10), // Space between the buttons
                FloatingActionButton(
                  heroTag: 'Clear',
                  shape: CircleBorder(),
                  onPressed: () {
                    try {
                      _mapController?.removeMarker(tappedPoint);
                    } catch (e) {
                      print('tappoint is empyt');
                    }
                  },
                  //backgroundColor: Colors.red,
                  child: const Icon(Icons.close),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
