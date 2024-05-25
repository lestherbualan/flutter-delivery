class DriverState {
  final String uid;
  final bool isAvailable;

  DriverState({
    required this.uid,
    required this.isAvailable,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'isAvailable': isAvailable,
    };
  }
}
