import 'package:flutter/material.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import '../../services/invite_service.dart';
import '../../services/notification_service.dart';

class InviteHandler extends StatefulWidget {
  final Widget child;
  const InviteHandler({super.key, required this.child});

  @override
  State<InviteHandler> createState() => _InviteHandlerState();
}

class _InviteHandlerState extends State<InviteHandler> {
  final InviteService _inviteService = InviteService();

  @override
  void initState() {
    super.initState();
    _initDynamicLinks();
  }

  Future<void> _initDynamicLinks() async {
    final data = await FirebaseDynamicLinks.instance.getInitialLink();
    if (data != null) {
      await _handleLink(data);
    }
    FirebaseDynamicLinks.instance.onLink.listen((PendingDynamicLinkData linkData) async {
      await _handleLink(linkData);
    }).onError((error) {});
  }

  Future<void> _handleLink(PendingDynamicLinkData data) async {
    final Uri deepLink = data.link;
    if (deepLink.path.contains('invite')) {
      final token = deepLink.queryParameters['token'];
      if (token != null) {
        try {
          await _inviteService.acceptInvite(token);
          if (mounted) {
            NotificationService.showSuccessSnackBar(
              context: context,
              message: 'Invite accepted. You have joined the account.',
            );
          }
        } catch (e) {
          if (mounted) {
            NotificationService.showErrorSnackBar(
              context: context,
              message: e.toString(),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}