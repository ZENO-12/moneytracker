import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/firestore_service.dart';
import '../../services/invite_service.dart';
import '../../services/auth_service.dart';
import '../../models/account_model.dart';
import '../../models/invite_model.dart';
import '../../theme/app_theme.dart';

class ManageMembersScreen extends StatefulWidget {
  final AccountModel account;
  const ManageMembersScreen({super.key, required this.account});

  @override
  State<ManageMembersScreen> createState() => _ManageMembersScreenState();
}

class _ManageMembersScreenState extends State<ManageMembersScreen> {
  final _emailController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _inviteService = InviteService();
  final _authService = AuthService();

  bool _isInviting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    setState(() { _isInviting = true; _error = null; });
    try {
      await _inviteService.createInvite(
        accountId: widget.account.id,
        invitedEmail: _emailController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invite created. Email composer opened.'), backgroundColor: AppTheme.primary),
        );
        _emailController.clear();
      }
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      setState(() { _isInviting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Members')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Invite Member', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isInviting ? null : _invite,
                  child: _isInviting ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Invite'),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppTheme.error)),
            ],
            const SizedBox(height: 24),
            Expanded(
              child: ListView(
                children: [
                  _buildMembersSection(),
                  const SizedBox(height: 16),
                  _buildInvitesSection(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMembersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Members', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            ...widget.account.members.map((m) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(m.userId),
              subtitle: Text(m.role == 'admin' ? 'Admin' : 'Member'),
              trailing: m.userId == widget.account.createdBy
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: () async {
                        await _firestoreService.removeMemberFromAccount(widget.account.id, m.userId);
                        if (mounted) setState(() {});
                      },
                    ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitesSection() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('invites')
          .where('accountId', isEqualTo: widget.account.id)
          .where('status', isEqualTo: InviteStatus.pending.name)
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Pending Invites', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                if (docs.isEmpty)
                  Text('No pending invites', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary))
                else
                  ...docs.map((d) {
                    final invite = InviteModel.fromMap(d.data() as Map<String, dynamic>, d.id);
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(invite.sentToEmail),
                      subtitle: const Text('Pending'),
                      trailing: TextButton(
                        onPressed: () async {
                          await _inviteService.cancelInvite(invite.token);
                        },
                        child: const Text('Cancel'),
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}