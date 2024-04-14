class Order {
  Map<String, String> startingGeoPoint;
  Map<String, String> endingGeoPoint;
  String distance;
  String uid;
  String status;
  String date;
  String vehicleType;
  bool isScheduled;
  Order(
      {required this.startingGeoPoint,
      required this.endingGeoPoint,
      required this.distance,
      required this.uid,
      required this.status,
      required this.date,
      required this.vehicleType,
      required this.isScheduled});
  Map<String, dynamic> toJson() => {
        'startingGeoPoint': startingGeoPoint,
        'endingGeoPoint': endingGeoPoint,
        'distance': distance,
        'uid': uid,
        'status': status,
        'date': date,
        'vehicleType': vehicleType,
        'isScheduled': isScheduled,
      };
}
