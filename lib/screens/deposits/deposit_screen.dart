import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/account_model.dart';
import '../../models/deposit_model.dart';
import '../../theme/app_theme.dart';

class DepositScreen extends StatefulWidget {
  final AccountModel? account;

  const DepositScreen({super.key, this.account});

  @override
  State<DepositScreen> createState() => _DepositScreenState();
}

class _DepositScreenState extends State<DepositScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _authService = AuthService();
  final _firestoreService = FirestoreService();

  bool _isLoading = false;
  String? _errorMessage;
  AccountModel? _selectedAccount;
  DepositMethod _selectedMethod = DepositMethod.bank;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _selectedAccount = widget.account;
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitDeposit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccount == null) {
      setState(() {
        _errorMessage = 'Please select an account';
      });
      return;
    }

    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final amount = double.parse(_amountController.text.replaceAll(',', ''));
      
      await _firestoreService.createDeposit(
        userId: currentUser.uid,
        accountId: _selectedAccount!.id,
        amount: amount,
        date: _selectedDate,
        method: _selectedMethod,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deposit submitted for approval!'),
            backgroundColor: AppTheme.primary,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _authService.currentUser;
    if (currentUser == null) return const SizedBox();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Make Deposit'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  const SizedBox(height: 16),
                  Icon(
                    Icons.payment,
                    size: 64,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Submit Deposit',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your deposit will be reviewed by the admin',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Account selection
                  if (_selectedAccount == null) ...[
                    Text(
                      'Select Account',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<List<AccountModel>>(
                      stream: _firestoreService.getUserAccounts(currentUser.uid),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final accounts = snapshot.data!;
                        if (accounts.isEmpty) {
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.grey100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.grey300),
                            ),
                            child: Text(
                              'No accounts available. Create an account first.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          );
                        }

                        return DropdownButtonFormField<AccountModel>(
                          decoration: const InputDecoration(
                            labelText: 'Account',
                            prefixIcon: Icon(Icons.account_balance_wallet),
                          ),
                          items: accounts.map((account) {
                            return DropdownMenuItem(
                              value: account,
                              child: Text(account.name),
                            );
                          }).toList(),
                          onChanged: (account) {
                            setState(() {
                              _selectedAccount = account;
                            });
                          },
                          validator: (value) {
                            if (value == null) {
                              return 'Please select an account';
                            }
                            return null;
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.grey100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.grey300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Account',
                                  style: Theme.of(context).textTheme.labelMedium,
                                ),
                                Text(
                                  _selectedAccount!.name,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Amount field
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Amount (ZMW)',
                      prefixIcon: Icon(Icons.attach_money),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter an amount';
                      }
                      
                      final amount = double.tryParse(value.replaceAll(',', ''));
                      if (amount == null) {
                        return 'Please enter a valid number';
                      }
                      if (amount <= 0) {
                        return 'Amount must be greater than 0';
                      }
                      if (amount > 100000) {
                        return 'Amount must be less than 100,000';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      // Format currency as user types
                      if (value.isNotEmpty) {
                        final amount = double.tryParse(value.replaceAll(',', ''));
                        if (amount != null) {
                          final formatted = NumberFormat('#,##0.##').format(amount);
                          if (formatted != value) {
                            _amountController.value = TextEditingValue(
                              text: formatted,
                              selection: TextSelection.collapsed(offset: formatted.length),
                            );
                          }
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Date selection
                  GestureDetector(
                    onTap: _selectDate,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.grey100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.grey300),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            color: AppTheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Deposit Date',
                                  style: Theme.of(context).textTheme.labelMedium,
                                ),
                                Text(
                                  DateFormat('MMMM d, yyyy').format(_selectedDate),
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Payment method selection
                  Text(
                    'Payment Method',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ...DepositMethod.values.map((method) => RadioListTile<DepositMethod>(
                    title: Text(method.name == 'bank' ? 'Bank Transfer' :
                              method.name == 'airtel' ? 'Airtel Money' :
                              method.name == 'mtn' ? 'MTN Mobile Money' :
                              'Zamtel Kwacha'),
                    subtitle: Text(_getMethodDescription(method)),
                    value: method,
                    groupValue: _selectedMethod,
                    onChanged: (value) {
                      setState(() {
                        _selectedMethod = value!;
                      });
                    },
                    contentPadding: EdgeInsets.zero,
                  )),
                  const SizedBox(height: 24),

                  // Error message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.grey100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppTheme.error),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: AppTheme.error),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Submit button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _submitDeposit,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Submit Deposit'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _getMethodDescription(DepositMethod method) {
    switch (method) {
      case DepositMethod.bank:
        return 'Traditional bank transfer';
      case DepositMethod.airtel:
        return 'Airtel Money mobile payment';
      case DepositMethod.mtn:
        return 'MTN Mobile Money payment';
      case DepositMethod.zamtel:
        return 'Zamtel Kwacha mobile payment';
    }
  }
}