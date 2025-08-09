import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../../services/invite_service.dart';
import '../../theme/app_theme.dart';
import '../../models/invite_model.dart';

class InvitesInboxScreen extends StatelessWidget {
  const InvitesInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(title: const Text('Invitations')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(InviteService.invitationsCollection)
            .where('sentToEmail', isEqualTo: user.email?.toLowerCase())
            .where('status', isEqualTo: InviteStatus.pending.name)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Text(
                'No invitations',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              ),
            );
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final inv = InviteModel.fromMap(docs[index].data() as Map<String, dynamic>, docs[index].id);
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ListTile(
                  title: Text('Invitation to account: ${inv.accountId}'),
                  subtitle: Text('Invited by: ${inv.sentBy}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextButton(
                        onPressed: () async {
                          await InviteService().cancelInvite(inv.token);
                        },
                        child: const Text('Reject'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () async {
                          await InviteService().acceptInvite(inv.token);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Invitation accepted'), backgroundColor: AppTheme.primary),
                            );
                          }
                        },
                        child: const Text('Accept'),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}