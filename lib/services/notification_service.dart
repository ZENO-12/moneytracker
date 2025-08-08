import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationService {
  static void showSnackBar({
    required BuildContext context,
    required String message,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor ?? AppTheme.primary,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static void showSuccessSnackBar({
    required BuildContext context,
    required String message,
  }) {
    showSnackBar(
      context: context,
      message: message,
      backgroundColor: AppTheme.primary,
    );
  }

  static void showErrorSnackBar({
    required BuildContext context,
    required String message,
  }) {
    showSnackBar(
      context: context,
      message: message,
      backgroundColor: AppTheme.error,
    );
  }

  static Future<void> showGoalReachedDialog({
    required BuildContext context,
    required String accountName,
    required double goalAmount,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.celebration,
                color: AppTheme.primary,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text('Congratulations!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You\'ve reached your goal for "$accountName"!',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.grey100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ZMW ${goalAmount.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Awesome!'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showDepositApprovedDialog({
    required BuildContext context,
    required double amount,
    required String accountName,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: AppTheme.primary,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text('Deposit Approved'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your deposit of ZMW ${amount.toStringAsFixed(2)} to "$accountName" has been approved!',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showGoalCloseDialog({
    required BuildContext context,
    required String accountName,
    required double currentAmount,
    required double goalAmount,
  }) async {
    final percentage = (currentAmount / goalAmount * 100).round();
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.trending_up,
                color: AppTheme.primary,
                size: 28,
              ),
              const SizedBox(width: 8),
              const Text('Almost There!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You\'re $percentage% of the way to your goal for "$accountName"!',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: currentAmount / goalAmount,
                backgroundColor: AppTheme.grey200,
                valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
              ),
              const SizedBox(height: 8),
              Text(
                'ZMW ${currentAmount.toStringAsFixed(2)} of ZMW ${goalAmount.toStringAsFixed(2)}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Keep Going!'),
            ),
          ],
        );
      },
    );
  }

  static Future<bool?> showConfirmationDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    Color? confirmColor,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Text(title),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(cancelText),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              style: confirmColor != null
                  ? ElevatedButton.styleFrom(backgroundColor: confirmColor)
                  : null,
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }
}