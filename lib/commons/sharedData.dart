import 'package:flutter/foundation.dart';
import 'package:flutter_osm_plugin/flutter_osm_plugin.dart';

class SharedData extends ChangeNotifier {
  late GeoPoint _sharedVariable = GeoPoint(latitude: 0, longitude: 0);

  GeoPoint get sharedVariable => _sharedVariable;

  set sharedVariable(GeoPoint value) {
    _sharedVariable = value;
    notifyListeners(); // Notify listeners about the update
  }
}
