import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';

class SuperAdminScreen extends StatelessWidget {
  const SuperAdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Console'),
        centerTitle: true,
      ),
      body: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.people), text: 'Users'),
                Tab(icon: Icon(Icons.account_balance_wallet), text: 'Accounts'),
                Tab(icon: Icon(Icons.history), text: 'Members History'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _UsersTab(),
                  _AccountsTab(),
                  _MembersHistoryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text(data['email'] ?? ''),
              subtitle: Text('Username: ${data['username'] ?? '—'} | Anonymous: ${data['anonymous'] == true ? 'Yes' : 'No'}'),
            );
          },
        );
      },
    );
  }
}

class _AccountsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('accounts').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            final data = doc.data() as Map<String, dynamic>;
            final members = List<String>.from(data['members'] ?? []);
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ListTile(
                title: Text(data['name'] ?? ''),
                subtitle: Text('Members: ${members.length} | Created By: ${data['createdBy']}'),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'delete') {
                      await FirebaseFirestore.instance.collection('accounts').doc(doc.id).delete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'delete', child: Text('Delete Account')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _MembersHistoryTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // This tab lists activity without showing deposit amounts (no reading deposits collection)
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('accounts').snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];
        return ListView(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final members = List<String>.from(data['members'] ?? []);
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['name'] ?? '', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Members:'),
                    const SizedBox(height: 6),
                    ...members.map((m) => Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: AppTheme.textSecondary),
                        const SizedBox(width: 6),
                        Text(m, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    )),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}