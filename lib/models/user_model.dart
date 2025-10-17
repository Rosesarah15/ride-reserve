class UserModel {
  final String uid;
  final String FirstName;
  final String LastName;
  final String email;
  final String Role;
  final String? phoneNumber;
  final String? profileImageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.uid,
    required this.FirstName,
    required this.LastName,
    required this.email,
    required this.Role,
    this.phoneNumber,
    this.profileImageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'FirstName': FirstName,
      'LastName': LastName,
      'email': email,
      'Role': Role,
      'phoneNumber': phoneNumber,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      FirstName: map['FirstName'] ?? '',
      LastName: map['LastName'] ?? '',
      email: map['email'] ?? '',
      Role: map['Role'] ?? '',
      phoneNumber: map['phoneNumber'],
      profileImageUrl: map['profileImageUrl'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  UserModel copyWith({
    String? uid,
    String? FirstName,
    String? LastName,
    String? email,
    String? Role,
    String? phoneNumber,
    String? profileImageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      FirstName: FirstName ?? this.FirstName,
      LastName: LastName ?? this.LastName,
      email: email ?? this.email,
      Role: Role ?? this.Role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}