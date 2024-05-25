class Proposal {
  final String uid;
  final String orderId;

  Proposal({
    required this.uid,
    required this.orderId,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'orderId': orderId,
    };
  }
}
