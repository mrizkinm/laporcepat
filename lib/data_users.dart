class DataUsers {
  String name;
  String password;
  String phone;
  String role;
  int status;
  String userId;

  DataUsers(
      {required this.name,
      required this.password,
      required this.phone,
      required this.role,
      required this.status,
      required this.userId});

  // Convert the Person object to a Map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'password': password,
      'phone': phone,
      'role': role,
      'status': status,
      'userId': userId
    };
  }

  // Create a Person object from a Map
  factory DataUsers.fromJson(Map<String, dynamic> json) {
    return DataUsers(
        name: json['name'] ?? '',
        password: json['password'] ?? '',
        phone: json['phone'] ?? '',
        role: json['role'] ?? '',
        status: json['status'] ?? 0,
        userId: json['userId'] ?? '');
  }
}
