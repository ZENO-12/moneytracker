enum InviteStatus { pending, accepted, canceled, revoked, expired }

class InviteModel {
  final String token; // document id
  final String accountId;
  final String invitedEmail;
  final String invitedBy; // userId
  final InviteStatus status;
  final DateTime createdAt;
  final String? acceptedBy; // userId
  final DateTime? acceptedAt;

  InviteModel({
    required this.token,
    required this.accountId,
    required this.invitedEmail,
    required this.invitedBy,
    this.status = InviteStatus.pending,
    required this.createdAt,
    this.acceptedBy,
    this.acceptedAt,
  });

  factory InviteModel.fromMap(Map<String, dynamic> map, String token) {
    return InviteModel(
      token: token,
      accountId: map['accountId'] ?? '',
      invitedEmail: map['invitedEmail'] ?? '',
      invitedBy: map['invitedBy'] ?? '',
      status: InviteStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => InviteStatus.pending,
      ),
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      acceptedBy: map['acceptedBy'],
      acceptedAt: map['acceptedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accountId': accountId,
      'invitedEmail': invitedEmail,
      'invitedBy': invitedBy,
      'status': status.name,
      'createdAt': createdAt,
      'acceptedBy': acceptedBy,
      'acceptedAt': acceptedAt,
    };
  }
}