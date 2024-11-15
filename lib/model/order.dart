class Order {
  Map<Object?, Object?> startingGeoPoint;
  Map<Object?, Object?> endingGeoPoint;
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
  bool isRated;
  String? noteToRider;
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
    required this.isRated,
    this.noteToRider,
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
        'isRated': isRated,
        'noteToRider': noteToRider
      };
  factory Order.fromMap(Map<String, dynamic> data) {
    return Order(
      startingGeoPoint: data['startingGeoPoint']! as Map<Object?, Object?>,
      endingGeoPoint: data['endingGeoPoint'] as Map<Object?, Object?>,
      distance: data['distance'],
      uid: data['uid'],
      status: data['status'],
      date: data['date'],
      vehicleType: data['vehicleType'],
      name: data['name'],
      isScheduled: data['isScheduled'],
      netWeight: double.parse(data['netWeight'].toString()),
      key: data['key'],
      driverId: data['driverId'],
      rate: data['rate'],
      isRated: data['isRated'],
      noteToRider: data['noteToRider'],
    );
  }
}
