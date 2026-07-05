import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../application/freelancers_providers.dart';
import '../data/freelancers_remote_data_source.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(walletProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('wallet.title'))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(walletProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.success, Color(0xFF16A34A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(context.tr('wallet.balance'),
                        style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text('${data.balance.toStringAsFixed(0)} XAF',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openWithdraw(context, ref, data.balance),
                        icon: const Icon(Icons.arrow_upward),
                        label: Text(context.tr('wallet.withdraw')),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.success),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(context.tr('wallet.transactions'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              if (data.transactions.isEmpty)
                Text(context.tr('wallet.no_transactions'),
                    style: const TextStyle(color: AppColors.textMuted))
              else
                ...data.transactions.map((t) => _txRow(context, t)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _txRow(BuildContext context, WalletTransaction t) {
    final isWithdraw = t.isWithdrawal;
    final amount = t.amount ?? 0;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isWithdraw ? AppColors.error.withOpacity(0.15) : AppColors.success.withOpacity(0.15),
          child: Icon(
            isWithdraw ? Icons.arrow_upward : Icons.arrow_downward,
            color: isWithdraw ? AppColors.error : AppColors.success,
          ),
        ),
        title: Text(t.description ??
            (isWithdraw ? context.tr('wallet.withdrawal') : context.tr('wallet.mission_payment'))),
        subtitle: Text([
          if (t.method != null) t.method!,
          if (t.createdAt != null && t.createdAt!.length >= 10) t.createdAt!.substring(0, 10),
        ].join(' · ')),
        trailing: Text(
          '${isWithdraw ? '-' : '+'}${amount.toStringAsFixed(0)} XAF',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isWithdraw ? AppColors.error : AppColors.success),
        ),
      ),
    );
  }

  Future<void> _openWithdraw(BuildContext context, WidgetRef ref, num balance) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WithdrawSheet(currentBalance: balance),
    );
  }
}

class _WithdrawSheet extends ConsumerStatefulWidget {
  const _WithdrawSheet({required this.currentBalance});
  final num currentBalance;

  @override
  ConsumerState<_WithdrawSheet> createState() => _WithdrawSheetState();
}

class _WithdrawSheetState extends ConsumerState<_WithdrawSheet> {
  String _method = 'OM';
  final _amountCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  bool _busy = false;
  String? _errorMessage;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = num.tryParse(_amountCtrl.text.trim());
    if (amount == null || amount < 500) {
      setState(() => _errorMessage = context.tr('wallet.withdraw_min'));
      return;
    }
    if (amount > widget.currentBalance) {
      setState(() => _errorMessage = context.tr('wallet.insufficient'));
      return;
    }
    if (!RegExp(r'^6\d{8}$').hasMatch(_phoneCtrl.text.trim())) {
      setState(() => _errorMessage = context.tr('mission.pay.invalid_phone'));
      return;
    }
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref.read(freelancersDataSourceProvider).withdraw(
            amount: amount,
            phone: '237${_phoneCtrl.text.trim()}',
            method: _method,
          );
      ref.invalidate(walletProvider);
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text(context.tr('wallet.withdraw_requested'))),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('wallet.withdraw'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                  child: _PayBtn(
                      label: 'Orange Money',
                      color: Colors.orange,
                      selected: _method == 'OM',
                      onTap: () => setState(() => _method = 'OM'))),
              const SizedBox(width: 8),
              Expanded(
                  child: _PayBtn(
                      label: 'MTN MoMo',
                      color: Colors.amber,
                      selected: _method == 'MOMO',
                      onTap: () => setState(() => _method = 'MOMO'))),
            ]),
            const SizedBox(height: 16),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: context.tr('wallet.amount')),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                  labelText: context.tr('mission.pay.phone_hint'), prefixText: '+237 '),
              onChanged: (_) {
                if (_errorMessage != null) setState(() => _errorMessage = null);
              },
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.error.withOpacity(0.35))),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.error, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: const TextStyle(
                              color: AppColors.error, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(context.tr('wallet.confirm_withdraw')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayBtn extends StatelessWidget {
  const _PayBtn(
      {required this.label,
      required this.color,
      required this.selected,
      required this.onTap});
  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: selected ? color : AppColors.border, width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
          color: selected ? color.withOpacity(0.08) : Colors.transparent,
        ),
        child: Center(
          child: Text(label,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: selected ? color : AppColors.textPrimary)),
        ),
      ),
    );
  }
}
