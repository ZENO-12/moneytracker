import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/account_model.dart';
import '../../models/deposit_model.dart';
import '../../theme/app_theme.dart';
import '../accounts/create_account_screen.dart';
import '../deposits/deposit_screen.dart';
import '../admin/admin_panel_screen.dart';
import '../profile/profile_screen.dart';
import '../invites/invites_inbox_screen.dart';
import '../admin/admin_gate.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  final NumberFormat _currencyFormat = NumberFormat.currency(symbol: 'ZMW ');

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Money Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mail_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InvitesInboxScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileScreen(),
                ),
              );
            },
          ),

          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<AccountModel>>(
        stream: _firestoreService.getUserAccounts(currentUser.uid),
        builder: (context, accountsSnapshot) {
          if (accountsSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!accountsSnapshot.hasData || accountsSnapshot.data!.isEmpty) {
            return _buildNoAccountsView();
          }

          final account = accountsSnapshot.data!.first;
          return _buildDashboardContent(account, currentUser.uid);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const DepositScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildNoAccountsView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.account_balance_wallet_outlined,
              size: 80,
              color: AppTheme.grey400,
            ),
            const SizedBox(height: 24),
            Text(
              'No Accounts Found',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first account to start tracking money',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateAccountScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Account'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardContent(AccountModel account, String userId) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account Header
          _buildAccountHeader(account),
          const SizedBox(height: 24),

          // Progress Section
          StreamBuilder<List<DepositModel>>(
            stream: _firestoreService.getAccountDeposits(account.id),
            builder: (context, depositsSnapshot) {
              if (!depositsSnapshot.hasData) {
                return const CircularProgressIndicator();
              }

              final deposits = depositsSnapshot.data!;
              final approvedDeposits = deposits
                  .where((d) => d.status == DepositStatus.approved)
                  .toList();
              final totalAmount = approvedDeposits.fold<double>(
                0,
                (sum, deposit) => sum + deposit.amount,
              );

              return Column(
                children: [
                  _buildProgressSection(totalAmount, account.goalAmount),
                  const SizedBox(height: 24),
                  _buildContributionChart(approvedDeposits, account.members),
                  const SizedBox(height: 24),
                  _buildRecentDeposits(deposits.take(5).toList()),
                ],
              );
            },
          ),

          const SizedBox(height: 24),
          _buildActionButtons(account, userId),
        ],
      ),
    );
  }

  Widget _buildAccountHeader(AccountModel account) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  color: AppTheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    account.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Goal: ${_currencyFormat.format(account.goalAmount)}',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${account.members.length} members',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(double currentAmount, double goalAmount) {
    final progress = goalAmount > 0 ? currentAmount / goalAmount : 0.0;
    final progressPercent = (progress * 100).clamp(0, 100);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: AppTheme.grey200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _currencyFormat.format(currentAmount),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  '${progressPercent.toStringAsFixed(1)}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContributionChart(List<DepositModel> deposits, List<AccountMember> members) {
    if (deposits.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                'Contributions',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Text(
                'No contributions yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final contributions = <String, double>{};
    for (final deposit in deposits) {
      contributions[deposit.userId] = (contributions[deposit.userId] ?? 0) + deposit.amount;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contributions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: contributions.entries.map((entry) {
                    final total = contributions.values.fold<double>(0, (a, b) => a + b);
                    final percentage = entry.value / total * 100;
                    return PieChartSectionData(
                      value: entry.value,
                      title: '${percentage.toStringAsFixed(1)}%',
                      color: _getColorForUser(entry.key, account: account),
                      radius: 60,
                    );
                  }).toList(),
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...contributions.entries.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: _getColorForUser(entry.key, account: account),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FutureBuilder<Map<String, String>>(
                      future: _firestoreService.getUsersData([entry.key]),
                      builder: (context, snapshot) {
                        final username = snapshot.data?[entry.key] ?? 'Loading...';
                        return Text(username);
                      },
                    ),
                  ),
                  Text(_currencyFormat.format(entry.value)),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDeposits(List<DepositModel> deposits) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Deposits',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            if (deposits.isEmpty)
              Text(
                'No deposits yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              )
            else
              ...deposits.map((deposit) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(deposit.status),
                  child: Icon(
                    _getStatusIcon(deposit.status),
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                title: Text(_currencyFormat.format(deposit.amount)),
                subtitle: Text(deposit.methodDisplayName),
                trailing: Text(
                  DateFormat('MMM d').format(deposit.date),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              )),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(AccountModel account, String userId) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DepositScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.add),
                label: const Text('Make Deposit'),
              ),
            ),
            const SizedBox(width: 16),
            FutureBuilder<bool>(
              future: _firestoreService.isAccountAdmin(account.id, userId),
              builder: (context, snapshot) {
                if (snapshot.data == true) {
                  return Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AdminPanelScreen(account: account),
                          ),
                        );
                      },
                      icon: const Icon(Icons.admin_panel_settings),
                      label: const Text('Admin Panel'),
                    ),
                  );
                }
                return const SizedBox();
              },
            ),
          ],
        ),
      ],
    );
  }

  Color _getColorForUser(String userId, {AccountModel? account}) {
    final palette = [
      AppTheme.primary,
      AppTheme.grey800,
      AppTheme.grey600,
      AppTheme.grey400,
      const Color(0xFF000000),
      const Color(0xFF1E1E1E),
      const Color(0xFF5A5A5A),
      const Color(0xFF9A9A9A),
    ];
    if (account != null && account.memberColors.containsKey(userId)) {
      final idx = account.memberColors[userId]!.clamp(0, palette.length - 1);
      return palette[idx];
    }
    return palette[userId.hashCode % palette.length];
  }

  Color _getStatusColor(DepositStatus status) {
    switch (status) {
      case DepositStatus.pending:
        return AppTheme.grey500;
      case DepositStatus.approved:
        return AppTheme.primary;
      case DepositStatus.rejected:
        return AppTheme.error;
    }
  }

  IconData _getStatusIcon(DepositStatus status) {
    switch (status) {
      case DepositStatus.pending:
        return Icons.schedule;
      case DepositStatus.approved:
        return Icons.check;
      case DepositStatus.rejected:
        return Icons.close;
    }
  }
}