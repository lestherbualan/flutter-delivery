class UserModel {
  final String uid;
  final String username;
  final String emailAddress;
  final bool isRider;
  final String profilePictureUrl; // New field for profile picture URL
  final String displayName;
  final String? contactNumber;
  final String? dateOfBirth;
  final String? gender;
  final bool? online;
  final double? driverRating;
  final String? driverSelfRating;
  final bool? firstOpen;

  UserModel({
    required this.uid,
    required this.username,
    required this.emailAddress,
    required this.isRider,
    required this.profilePictureUrl, // Updated constructor
    required this.displayName,
    this.contactNumber,
    this.dateOfBirth,
    this.gender,
    this.online,
    this.driverRating,
    this.driverSelfRating,
    this.firstOpen,
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'emailAddress': emailAddress,
      'isRider': isRider,
      'profilePictureUrl': profilePictureUrl, // Include profile picture URL in JSON
      'displayName': displayName,
      'contactNumber': contactNumber,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'online': online,
      'driverRating': driverRating,
      'driverSelfRating': driverSelfRating,
      'firstOpen': firstOpen
    };
  }
}
