class UserModel {
  final String uid;
  final String email;
  final String? username;
  final bool anonymous;
  final List<String> joinedAccounts;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    this.username,
    this.anonymous = false,
    this.joinedAccounts = const [],
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'],
      anonymous: map['anonymous'] ?? false,
      joinedAccounts: List<String>.from(map['joinedAccounts'] ?? []),
      createdAt: map['createdAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'anonymous': anonymous,
      'joinedAccounts': joinedAccounts,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    bool? anonymous,
    List<String>? joinedAccounts,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      anonymous: anonymous ?? this.anonymous,
      joinedAccounts: joinedAccounts ?? this.joinedAccounts,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}