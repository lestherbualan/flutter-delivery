class Order {
  Map<String, dynamic> startingGeoPoint;
  Map<String, dynamic> endingGeoPoint;
  String distance;
  String uid;
  String status;
  String date;
  String vehicleType;
  String name;
  bool isScheduled;
  double netWeight;
  String? key;
  String? driverId;
  int rate;
  Order({
    required this.startingGeoPoint,
    required this.endingGeoPoint,
    required this.distance,
    required this.uid,
    required this.status,
    required this.date,
    required this.vehicleType,
    required this.name,
    required this.isScheduled,
    required this.netWeight,
    this.key,
    this.driverId,
    required this.rate,
  });
  Map<String, dynamic> toJson() => {
        'startingGeoPoint': startingGeoPoint,
        'endingGeoPoint': endingGeoPoint,
        'distance': distance,
        'uid': uid,
        'status': status,
        'date': date,
        'vehicleType': vehicleType,
        'name': name,
        'isScheduled': isScheduled,
        'netWeight': netWeight,
        'key': key,
        'driverId': driverId,
        'rate': rate,
      };
}
