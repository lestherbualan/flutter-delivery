class UserModel {
  String uid;
  bool isRider;
  UserModel({
    required this.uid,
    required this.isRider,
  });
  Map<String, dynamic> toJson() => {
        'uid': uid,
        'isRider': isRider,
      };
}
