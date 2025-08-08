class AccountModel {
  final String id;
  final String name;
  final double goalAmount;
  final String createdBy;
  final List<String> members; // userIds
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
      members: List<String>.from(map['members'] ?? []),
      memberColors: Map<String, int>.from(map['memberColors'] ?? {}),
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'goalAmount': goalAmount,
      'createdBy': createdBy,
      'members': members,
      'memberColors': memberColors,
      'createdAt': createdAt,
    };
  }

  AccountModel copyWith({
    String? id,
    String? name,
    double? goalAmount,
    String? createdBy,
    List<String>? members,
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