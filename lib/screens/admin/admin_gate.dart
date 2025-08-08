import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/auth_service.dart';
import '../super_admin/super_admin_screen.dart';

class AdminGate extends StatelessWidget {
  const AdminGate({super.key});

  Future<bool> _isSuperAdmin(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data() as Map<String, dynamic>?;
    return data?['superAdmin'] == true;
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) return const SizedBox();

    return FutureBuilder<bool>(
      future: _isSuperAdmin(user.uid),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.data == true) {
          return const SuperAdminScreen();
        }
        return const Scaffold(body: Center(child: Text('Access denied')));
      },
    );
  }
}