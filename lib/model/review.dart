class Review {
  String reviewerId;
  String? message;
  String orderId;
  double rating;
  String revieweeId;
  Review({
    required this.reviewerId,
    this.message,
    required this.orderId,
    required this.rating,
    required this.revieweeId,
  });
  Map<String, dynamic> toJson() => {
        'driverId': reviewerId,
        'message': message,
        'orderId': orderId,
        'rating': rating,
        'userId': revieweeId,
      };
}
