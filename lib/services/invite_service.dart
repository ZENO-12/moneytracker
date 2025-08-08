import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:url_launcher/url_launcher.dart';
import 'auth_service.dart';
import '../models/invite_model.dart';
import 'firestore_service.dart';

class InviteService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  static const invitationsCollection = 'invitations';

  // token generator
  String _generateToken(int length) {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Future<String> _createDynamicLink(String token) async {
    final parameters = DynamicLinkParameters(
      link: Uri.parse('https://moneytracker.page.link/invite?token=$token'),
      uriPrefix: 'https://moneytracker.page.link',
      androidParameters: const AndroidParameters(packageName: 'com.example.moneyTracker'),
      iosParameters: const IOSParameters(bundleId: 'com.example.moneyTracker'),
    );
    final shortLink = await FirebaseDynamicLinks.instance.buildShortLink(parameters);
    return shortLink.shortUrl.toString();
  }

  Future<InviteModel> createInvite({
    required String accountId,
    required String invitedEmail,
  }) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      throw 'Not authenticated';
    }

    // Ensure inviter is the account admin
    final accountDoc = await _firestore.collection('accounts').doc(accountId).get();
    if (!accountDoc.exists) throw 'Account not found';
    final accountData = accountDoc.data() as Map<String, dynamic>;
    if (accountData['createdBy'] != currentUser.uid) {
      throw 'Only the account admin can send invites';
    }

    final token = _generateToken(20);
    final inviteDoc = _firestore.collection(invitationsCollection).doc(token);

    final invite = InviteModel(
      token: token,
      accountId: accountId,
      invitedEmail: invitedEmail.trim().toLowerCase(),
      invitedByUserId: currentUser.uid,
      status: InviteStatus.pending,
      createdAt: DateTime.now(),
    );

    await inviteDoc.set(invite.toMap());

    // Build dynamic link
    final link = await _createDynamicLink(token);

    // Open email composer
    final subject = Uri.encodeComponent('Join my Money Tracker account');
    final body = Uri.encodeComponent('Hi,\n\nI\'d like to invite you to join my Money Tracker account. Click the link below to accept the invite:\n\n$link\n\nIf you don\'t have the app, please install it first.');
    final uri = Uri.parse('mailto:$invitedEmail?subject=$subject&body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }

    return invite;
  }

  Future<void> cancelInvite(String token) async {
    await _firestore.collection(invitationsCollection).doc(token).update({
      'status': InviteStatus.canceled.name,
    });
  }

  Future<InviteModel?> getInvite(String token) async {
    final doc = await _firestore.collection(invitationsCollection).doc(token).get();
    if (!doc.exists) return null;
    return InviteModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  Future<void> acceptInvite(String token) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) throw 'Not authenticated';

    final invite = await getInvite(token);
    if (invite == null) throw 'Invite not found';
    if (invite.status != InviteStatus.pending) throw 'Invite is not active';

    // Ensure email matches
    final email = currentUser.email?.toLowerCase();
    if (email == null || email != invite.invitedEmail) {
      throw 'Invite email does not match your account';
    }

    // Add member to account and assign color
    await _firestoreService.addMemberToAccount(invite.accountId, currentUser.uid, assignColor: true);

    await _firestore.collection(invitationsCollection).doc(token).update({
      'status': InviteStatus.accepted.name,
      'acceptedBy': currentUser.uid,
      'acceptedAt': DateTime.now(),
    });
  }
}