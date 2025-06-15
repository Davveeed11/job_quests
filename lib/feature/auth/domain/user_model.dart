class UserModel {
  final String uid;
  final String email;
  final String? displayName;

  UserModel(this.displayName, {required this.email, required this.uid});
}
