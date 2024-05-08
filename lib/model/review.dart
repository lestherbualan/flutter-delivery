class Review {
  String driverId;
  String? message;
  String orderId;
  double rating;
  String userId;
  Review({
    required this.driverId,
    this.message,
    required this.orderId,
    required this.rating,
    required this.userId,
  });
  Map<String, dynamic> toJson() => {
        'driverId': driverId,
        'message': message,
        'orderId': orderId,
        'rating': rating,
        'userId': userId,
      };
}
