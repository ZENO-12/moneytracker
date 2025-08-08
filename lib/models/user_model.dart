class UserModel {
  final String uid;
  final String email;
  final String? username;
  final bool anonymous;
  final bool isSuperAdmin;
  final List<String> joinedAccounts;
  final List<Map<String, dynamic>> pendingInvites; // list of invite objects (token, accountId, status)
  final bool suspended;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    this.username,
    this.anonymous = false,
    this.isSuperAdmin = false,
    this.joinedAccounts = const [],
    this.pendingInvites = const [],
    this.suspended = false,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'],
      anonymous: map['anonymous'] ?? false,
      isSuperAdmin: map['isSuperAdmin'] ?? false,
      joinedAccounts: List<String>.from(map['joinedAccounts'] ?? []),
      pendingInvites: List<Map<String, dynamic>>.from(map['pendingInvites'] ?? []),
      suspended: map['suspended'] ?? false,
      createdAt: map['createdAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'anonymous': anonymous,
      'isSuperAdmin': isSuperAdmin,
      'joinedAccounts': joinedAccounts,
      'pendingInvites': pendingInvites,
      'suspended': suspended,
      'createdAt': createdAt,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    bool? anonymous,
    bool? isSuperAdmin,
    List<String>? joinedAccounts,
    List<Map<String, dynamic>>? pendingInvites,
    bool? suspended,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      anonymous: anonymous ?? this.anonymous,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      joinedAccounts: joinedAccounts ?? this.joinedAccounts,
      pendingInvites: pendingInvites ?? this.pendingInvites,
      suspended: suspended ?? this.suspended,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}