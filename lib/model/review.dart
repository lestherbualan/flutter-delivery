class Review {
  String reviewerUserType;
  String driverId;
  String driverName;
  String? message;
  String orderId;
  double rating;
  String customerId;
  String customerName;
  String timestamp;
  Review({
    required this.reviewerUserType,
    required this.driverId,
    required this.driverName,
    this.message,
    required this.orderId,
    required this.rating,
    required this.customerId,
    required this.customerName,
    required this.timestamp,
  });
  Map<String, dynamic> toJson() => {
        'reviewerUserType': reviewerUserType,
        'driverId': driverId,
        'driverName': driverName,
        'message': message,
        'orderId': orderId,
        'rating': rating,
        'customerId': customerId,
        'customerName': customerName,
        'timestamp': timestamp,
      };

  factory Review.fromMap(Map<String, dynamic> data) {
    return Review(
      reviewerUserType: data['reviewerUserType'],
      driverId: data['driverId'],
      driverName: data['driverName'],
      message: data['message'] ?? '',
      orderId: data['orderId'],
      rating: double.parse(data['rating'].toString()),
      customerId: data['customerId'],
      customerName: data['customerName'],
      timestamp: data['timestamp'],
    );
  }
}
