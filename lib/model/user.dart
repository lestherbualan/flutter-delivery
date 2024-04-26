class UserModel {
  final String uid;
  final String username;
  final String emailAddress;
  final bool isRider;
  final String profilePictureUrl; // New field for profile picture URL

  UserModel({
    required this.uid,
    required this.username,
    required this.emailAddress,
    required this.isRider,
    required this.profilePictureUrl, // Updated constructor
  });

  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'emailAddress': emailAddress,
      'isRider': isRider,
      'profilePictureUrl':
          profilePictureUrl, // Include profile picture URL in JSON
    };
  }
}
