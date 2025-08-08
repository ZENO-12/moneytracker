import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../models/account_model.dart';
import '../models/deposit_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ACCOUNT OPERATIONS

  // Create a new account
  Future<String> createAccount({
    required String name,
    required double goalAmount,
    required String createdBy,
  }) async {
    try {
      DocumentReference accountRef = await _firestore.collection('accounts').add({
        'name': name,
        'goalAmount': goalAmount,
        'createdBy': createdBy,
        'members': [createdBy],
        'memberColors': { createdBy: 0 },
        'createdAt': DateTime.now(),
      });

      // Add account ID to user's joinedAccounts
      await _firestore.collection('users').doc(createdBy).update({
        'joinedAccounts': FieldValue.arrayUnion([accountRef.id])
      });

      return accountRef.id;
    } catch (e) {
      throw 'Error creating account: $e';
    }
  }

  // Get accounts for a user
  Stream<List<AccountModel>> getUserAccounts(String userId) {
    return _firestore
        .collection('accounts')
        .where('members', arrayContains: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AccountModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get specific account
  Future<AccountModel?> getAccount(String accountId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('accounts').doc(accountId).get();
      if (doc.exists) {
        return AccountModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      throw 'Error getting account: $e';
    }
  }

  // Add member to account
  Future<void> addMemberToAccount(String accountId, String userId, {bool assignColor = false}) async {
    try {
      final accountRef = _firestore.collection('accounts').doc(accountId);
      await accountRef.update({
        'members': FieldValue.arrayUnion([userId])
      });

      // Optionally assign a color index for the member in this account
      if (assignColor) {
        final snap = await accountRef.get();
        final data = snap.data() as Map<String, dynamic>?;
        final existing = Map<String, dynamic>.from(data?['memberColors'] ?? {});
        // next color index from 0..7
        final nextIndex = (existing.length % 8);
        existing[userId] = nextIndex;
        await accountRef.update({'memberColors': existing});
      }

      await _firestore.collection('users').doc(userId).update({
        'joinedAccounts': FieldValue.arrayUnion([accountId])
      });
    } catch (e) {
      throw 'Error adding member to account: $e';
    }
  }

  Future<void> removeMemberFromAccount(String accountId, String userId) async {
    try {
      final accountRef = _firestore.collection('accounts').doc(accountId);
      await accountRef.update({
        'members': FieldValue.arrayRemove([userId])
      });
      await _firestore.collection('users').doc(userId).update({
        'joinedAccounts': FieldValue.arrayRemove([accountId])
      });
      // keep memberColors entry to preserve legend history, or remove if desired
    } catch (e) {
      throw 'Error removing member: $e';
    }
  }

  // DEPOSIT OPERATIONS

  // Create a new deposit
  Future<String> createDeposit({
    required String userId,
    required String accountId,
    required double amount,
    required DateTime date,
    required DepositMethod method,
  }) async {
    try {
      DocumentReference depositRef = await _firestore
          .collection('accounts')
          .doc(accountId)
          .collection('deposits')
          .add({
        'userId': userId,
        'accountId': accountId,
        'amount': amount,
        'date': date,
        'method': method.name,
        'status': DepositStatus.pending.name,
        'createdAt': DateTime.now(),
      });

      return depositRef.id;
    } catch (e) {
      throw 'Error creating deposit: $e';
    }
  }

  // Get deposits for an account
  Stream<List<DepositModel>> getAccountDeposits(String accountId) {
    return _firestore
        .collection('accounts')
        .doc(accountId)
        .collection('deposits')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DepositModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get pending deposits for admin approval
  Stream<List<DepositModel>> getPendingDeposits(String accountId) {
    return _firestore
        .collection('accounts')
        .doc(accountId)
        .collection('deposits')
        .where('status', isEqualTo: DepositStatus.pending.name)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DepositModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Get user's deposits across all accounts
  Stream<List<DepositModel>> getUserDeposits(String userId) {
    return _firestore
        .collectionGroup('deposits')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => DepositModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  // Approve or reject a deposit
  Future<void> updateDepositStatus({
    required String accountId,
    required String depositId,
    required DepositStatus status,
    required String approvedBy,
  }) async {
    try {
      await _firestore
          .collection('accounts')
          .doc(accountId)
          .collection('deposits')
          .doc(depositId)
          .update({
        'status': status.name,
        'approvedBy': approvedBy,
        'approvedAt': DateTime.now(),
      });
    } catch (e) {
      throw 'Error updating deposit status: $e';
    }
  }

  // ANALYTICS AND REPORTS

  // Get total approved deposits for an account
  Future<double> getTotalApprovedDeposits(String accountId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('accounts')
          .doc(accountId)
          .collection('deposits')
          .where('status', isEqualTo: DepositStatus.approved.name)
          .get();

      double total = 0;
      for (var doc in snapshot.docs) {
        total += (doc.data() as Map<String, dynamic>)['amount'] ?? 0;
      }
      return total;
    } catch (e) {
      return 0;
    }
  }

  // Get user contributions for an account
  Future<Map<String, double>> getUserContributions(String accountId) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('accounts')
          .doc(accountId)
          .collection('deposits')
          .where('status', isEqualTo: DepositStatus.approved.name)
          .get();

      Map<String, double> contributions = {};
      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        String userId = data['userId'];
        double amount = data['amount']?.toDouble() ?? 0;
        contributions[userId] = (contributions[userId] ?? 0) + amount;
      }
      return contributions;
    } catch (e) {
      return {};
    }
  }

  // Get user statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      DateTime now = DateTime.now();
      DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));
      DateTime monthStart = DateTime(now.year, now.month, 1);
      DateTime dayStart = DateTime(now.year, now.month, now.day);

      QuerySnapshot allDeposits = await _firestore
          .collectionGroup('deposits')
          .where('userId', isEqualTo: userId)
          .where('status', isEqualTo: DepositStatus.approved.name)
          .get();

      double totalAmount = 0;
      double weeklyAmount = 0;
      double monthlyAmount = 0;
      double dailyAmount = 0;

      for (var doc in allDeposits.docs) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        double amount = data['amount']?.toDouble() ?? 0;
        DateTime createdAt = data['createdAt']?.toDate() ?? DateTime.now();

        totalAmount += amount;

        if (createdAt.isAfter(weekStart)) weeklyAmount += amount;
        if (createdAt.isAfter(monthStart)) monthlyAmount += amount;
        if (createdAt.isAfter(dayStart)) dailyAmount += amount;
      }

      return {
        'totalAmount': totalAmount,
        'weeklyAmount': weeklyAmount,
        'monthlyAmount': monthlyAmount,
        'dailyAmount': dailyAmount,
        'totalDeposits': allDeposits.docs.length,
      };
    } catch (e) {
      return {
        'totalAmount': 0.0,
        'weeklyAmount': 0.0,
        'monthlyAmount': 0.0,
        'dailyAmount': 0.0,
        'totalDeposits': 0,
      };
    }
  }

  // USER OPERATIONS

  // Get user data with username
  Future<Map<String, String>> getUsersData(List<String> userIds) async {
    try {
      Map<String, String> usersData = {};
      
      for (String userId in userIds) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(userId).get();
        if (doc.exists) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          String displayName = data['username'] ?? 'Anonymous';
          if (data['anonymous'] == true) displayName = 'Anonymous';
          usersData[userId] = displayName;
        }
      }
      
      return usersData;
    } catch (e) {
      return {};
    }
  }

  // Check if user is admin of account
  Future<bool> isAccountAdmin(String accountId, String userId) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('accounts').doc(accountId).get();
      if (doc.exists) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return data['createdBy'] == userId;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}