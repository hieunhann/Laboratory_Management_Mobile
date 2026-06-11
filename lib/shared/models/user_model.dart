class UserModel {
  final String? userId;
  final String? username;
  final String? email;
  final String? fullName;
  final String? role;

  UserModel({
    this.userId,
    this.username,
    this.email,
    this.fullName,
    this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['userId']?.toString() ?? json['id']?.toString(),
      username: json['username']?.toString(),
      email: json['email']?.toString(),
      fullName: json['fullName']?.toString() ?? json['name']?.toString(),
      role: json['role']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'username': username,
        'email': email,
        'fullName': fullName,
        'role': role,
      };
}
