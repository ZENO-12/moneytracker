enum InviteStatus { pending, accepted, canceled, revoked, expired }

class InviteModel {
  final String token; // inviteId
  final String accountId;
  final String sentBy; // userId
  final String sentToEmail;
  final InviteStatus status; // pending | accepted | declined | canceled | revoked | expired (we map to 3)
  final DateTime sentAt;
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
      sentBy: map['sentBy'] ?? map['invitedByUserId'] ?? '',
      sentToEmail: map['sentToEmail'] ?? map['invitedEmail'] ?? '',
      status: InviteStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => InviteStatus.pending,
      ),
      sentAt: (map['sentAt'] ?? map['createdAt'])?.toDate() ?? DateTime.now(),
      acceptedBy: map['acceptedBy'],
      acceptedAt: map['acceptedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accountId': accountId,
      'sentBy': sentBy,
      'sentToEmail': sentToEmail,
      'status': status.name,
      'sentAt': sentAt,
      'acceptedBy': acceptedBy,
      'acceptedAt': acceptedAt,
    };
  }
}