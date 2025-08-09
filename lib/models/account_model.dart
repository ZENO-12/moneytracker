class AccountMember {
  final String userId;
  final String role; // 'admin' | 'member'
  AccountMember({required this.userId, required this.role});
  factory AccountMember.fromMap(Map<String, dynamic> map) => AccountMember(userId: map['userId'] ?? '', role: map['role'] ?? 'member');
  Map<String, dynamic> toMap() => { 'userId': userId, 'role': role };
}

class AccountModel {
  final String id;
  final String name;
  final double goalAmount;
  final String createdBy;
  final List<AccountMember> members; // role-aware members
  final Map<String, int> memberColors; // userId -> color index
  final DateTime createdAt;

  AccountModel({
    required this.id,
    required this.name,
    required this.goalAmount,
    required this.createdBy,
    required this.members,
    required this.memberColors,
    required this.createdAt,
  });

  factory AccountModel.fromMap(Map<String, dynamic> map, String id) {
    return AccountModel(
      id: id,
      name: map['name'] ?? '',
      goalAmount: (map['goalAmount'] ?? 0).toDouble(),
      createdBy: map['createdBy'] ?? '',
      members: (map['members'] as List<dynamic>? ?? []).map((m) => AccountMember.fromMap(Map<String, dynamic>.from(m))).toList(),
      memberColors: Map<String, int>.from(map['memberColors'] ?? {}),
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'goalAmount': goalAmount,
      'createdBy': createdBy,
      'members': members.map((m) => m.toMap()).toList(),
      'memberColors': memberColors,
      'createdAt': createdAt,
    };
  }

  AccountModel copyWith({
    String? id,
    String? name,
    double? goalAmount,
    String? createdBy,
    List<AccountMember>? members,
    Map<String, int>? memberColors,
    DateTime? createdAt,
  }) {
    return AccountModel(
      id: id ?? this.id,
      name: name ?? this.name,
      goalAmount: goalAmount ?? this.goalAmount,
      createdBy: createdBy ?? this.createdBy,
      members: members ?? this.members,
      memberColors: memberColors ?? this.memberColors,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}