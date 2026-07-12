import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pawffy/main.dart';
import '../providers/wallet_controller.dart';

class PaymentsWalletScreen extends ConsumerStatefulWidget {
  const PaymentsWalletScreen({super.key});

  @override
  ConsumerState<PaymentsWalletScreen> createState() => _PaymentsWalletScreenState();
}

class _PaymentsWalletScreenState extends ConsumerState<PaymentsWalletScreen> {
  final _amountController = TextEditingController();
  final _withdrawFormKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _showWithdrawDialog(BuildContext context, double maxBalance) {
    _amountController.clear();
    showDialog(
      context: context,
      builder: (ctx) {
        final dialogIsDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: dialogIsDark ? const Color(0xFF1E1E1E) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Withdraw Funds',
            style: GoogleFonts.barlow(
              fontWeight: FontWeight.bold,
              color: dialogIsDark ? Colors.white : Colors.black87,
            ),
          ),
          content: Form(
            key: _withdrawFormKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Available Balance: \$${maxBalance.toStringAsFixed(2)}',
                  style: GoogleFonts.barlow(
                    fontSize: 13,
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: GoogleFonts.barlow(
                    color: dialogIsDark ? Colors.white : Colors.black87,
                  ),
                  decoration: InputDecoration(
                    prefixText: '\$ ',
                    prefixStyle: GoogleFonts.barlow(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.orange,
                    ),
                    hintText: 'Enter amount to withdraw',
                    filled: true,
                    fillColor: dialogIsDark ? const Color(0xFF2E2E2E) : const Color(0xFFF2F2F7),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Amount is required';
                    }
                    final amt = double.tryParse(value);
                    if (amt == null || amt <= 0) {
                      return 'Enter a valid positive number';
                    }
                    if (amt > maxBalance) {
                      return 'Amount exceeds available balance';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'CANCEL',
                style: GoogleFonts.barlow(
                  fontWeight: FontWeight.bold,
                  color: AppColors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_withdrawFormKey.currentState?.validate() ?? false) {
                  final amt = double.parse(_amountController.text.trim());
                  Navigator.pop(ctx);
                  _processWithdrawal(amt);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: const Size(80, 36),
              ),
              child: Text(
                'WITHDRAW',
                style: GoogleFonts.barlow(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _processWithdrawal(double amount) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            ),
            SizedBox(width: 16),
            Text('Processing withdrawal...'),
          ],
        ),
        duration: Duration(days: 1),
      ),
    );

    final success = await ref.read(walletControllerProvider.notifier).withdraw(amount);

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Withdrawal request submitted successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final walletState = ref.read(walletControllerProvider);
      final errorMsg = walletState.hasError
          ? walletState.error.toString().replaceFirst('Exception: ', '')
          : 'Failed to request withdrawal';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletAsync = ref.watch(walletControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : Colors.black87,
            size: 20,
          ),
        ),
        title: Text(
          'PAYMENTS & WALLETS',
          style: GoogleFonts.barlow(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: SafeArea(
        child: walletAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.orange),
          ),
          error: (err, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  'Failed to load wallet',
                  style: GoogleFonts.barlow(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  err.toString().replaceFirst('Exception: ', ''),
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
                  onPressed: () => ref.read(walletControllerProvider.notifier).refresh(),
                  child: const Text('Retry', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
          data: (wallet) {
            return RefreshIndicator(
              color: AppColors.orange,
              onRefresh: () => ref.read(walletControllerProvider.notifier).refresh(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                children: [
                  // Gradient Wallet Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.orange, AppColors.orangeLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.orange.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'TOTAL BALANCE',
                              style: GoogleFonts.barlow(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            ),
                            const Icon(
                              Icons.account_balance_wallet_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '\$${wallet.balance.toStringAsFixed(2)}',
                          style: GoogleFonts.barlow(
                            color: Colors.white,
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: wallet.balance > 0
                              ? () => _showWithdrawDialog(context, wallet.balance)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.orange,
                            disabledBackgroundColor: Colors.white.withOpacity(0.4),
                            disabledForegroundColor: Colors.white70,
                            minimumSize: const Size(double.infinity, 48),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'WITHDRAW FUNDS',
                                style: GoogleFonts.barlow(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.send_rounded, size: 16),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Transactions Title
                  Text(
                    'TRANSACTION HISTORY',
                    style: GoogleFonts.barlow(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white70 : Colors.black54,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (wallet.transactions.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long_outlined,
                            size: 48,
                            color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade400,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No transactions found',
                            style: GoogleFonts.barlow(
                              color: AppColors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: wallet.transactions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final tx = wallet.transactions[index];
                        final isCredit = tx.type.toLowerCase() == 'credit';
                        final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(tx.createdAt);
                        final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200,
                              width: 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isCredit
                                      ? AppColors.success.withOpacity(0.1)
                                      : AppColors.error.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isCredit
                                      ? Icons.arrow_downward_rounded
                                      : Icons.arrow_upward_rounded,
                                  color: isCredit ? AppColors.success : AppColors.error,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.description.isNotEmpty ? tx.description : (isCredit ? 'Fund Received' : 'Withdrawal Request'),
                                      style: GoogleFonts.barlow(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      dateStr,
                                      style: GoogleFonts.barlow(
                                        fontSize: 11,
                                        color: AppColors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${isCredit ? '+' : '-'}\$${tx.amount.toStringAsFixed(2)}',
                                style: GoogleFonts.barlow(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isCredit ? AppColors.success : AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
