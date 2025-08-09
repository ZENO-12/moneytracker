enum DepositMethod { bank, airtel, mtn, zamtel }

enum DepositStatus { pending, approved, rejected }

class DepositModel {
  final String id;
  final String userId;
  final String accountId;
  final double amount;
  final DateTime date;
  final DepositMethod method;
  final DepositStatus status;
  final DateTime createdAt;
  final String? notes;
  final String? approvedBy;
  final DateTime? approvedAt;

  DepositModel({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.amount,
    required this.date,
    required this.method,
    this.status = DepositStatus.pending,
    required this.createdAt,
    this.notes,
    this.approvedBy,
    this.approvedAt,
  });

  factory DepositModel.fromMap(Map<String, dynamic> map, String id) {
    return DepositModel(
      id: id,
      userId: map['userId'] ?? '',
      accountId: map['accountId'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      date: map['date']?.toDate() ?? DateTime.now(),
      method: DepositMethod.values.firstWhere(
        (e) => e.name == map['method'],
        orElse: () => DepositMethod.bank,
      ),
      status: DepositStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => DepositStatus.pending,
      ),
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      notes: map['notes'],
      approvedBy: map['approvedBy'],
      approvedAt: map['approvedAt']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'accountId': accountId,
      'amount': amount,
      'date': date,
      'method': method.name,
      'status': status.name,
      'createdAt': createdAt,
      'notes': notes,
      'approvedBy': approvedBy,
      'approvedAt': approvedAt,
    };
  }

  DepositModel copyWith({
    String? id,
    String? userId,
    String? accountId,
    double? amount,
    DateTime? date,
    DepositMethod? method,
    DepositStatus? status,
    DateTime? createdAt,
    String? approvedBy,
    DateTime? approvedAt,
  }) {
    return DepositModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      method: method ?? this.method,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
    );
  }

  String get methodDisplayName {
    switch (method) {
      case DepositMethod.bank:
        return 'Bank Transfer';
      case DepositMethod.airtel:
        return 'Airtel Money';
      case DepositMethod.mtn:
        return 'MTN Mobile Money';
      case DepositMethod.zamtel:
        return 'Zamtel Kwacha';
    }
  }
}