import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/missions_providers.dart';
import '../../data/models/mission.dart';

class MissionPaymentSheet extends ConsumerStatefulWidget {
  const MissionPaymentSheet({super.key, required this.mission});
  final Mission mission;

  @override
  ConsumerState<MissionPaymentSheet> createState() => _MissionPaymentSheetState();
}

enum _Step { choice, form, waiting, success, failed }

class _MissionPaymentSheetState extends ConsumerState<MissionPaymentSheet> {
  _Step _step = _Step.choice;
  String _provider = 'OM';
  final _phoneCtrl = TextEditingController();
  bool _busy = false;
  String? _errorMessage;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _payCash() async {
    setState(() => _busy = true);
    try {
      await ref
          .read(updateMissionStatusControllerProvider(widget.mission.id).notifier)
          .submit(MissionStatus.terminee, paymentMode: 'cash');
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('mission.pay.cash_direct_done'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _payPlatform() async {
    final phone = _phoneCtrl.text.trim();
    if (!RegExp(r'^6\d{8}$').hasMatch(phone)) {
      setState(() => _errorMessage = context.tr('mission.pay.invalid_phone'));
      return;
    }
    setState(() {
      _errorMessage = null;
      _step = _Step.waiting;
    });
    await ref
        .read(payMissionControllerProvider(widget.mission.id).notifier)
        .initiate(phone: '237$phone', provider: _provider);
  }

  @override
  Widget build(BuildContext context) {
    // Ecoute l'etat du controller pour reagir a success/failed.
    ref.listen(payMissionControllerProvider(widget.mission.id), (prev, next) {
      final data = next.valueOrNull;
      if (data == null) return;
      switch (data.stage) {
        case PayStage.success:
          if (_step != _Step.success && mounted) setState(() => _step = _Step.success);
          break;
        case PayStage.failed:
          if (_step != _Step.failed && mounted) setState(() => _step = _Step.failed);
          break;
        default:
          break;
      }
    });

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: _buildStep(context),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (_step) {
      case _Step.choice:
        return _buildChoice(context);
      case _Step.form:
        return _buildForm(context);
      case _Step.waiting:
        return _buildWaiting(context);
      case _Step.success:
        return _buildSuccess(context);
      case _Step.failed:
        return _buildFailed(context);
    }
  }

  Widget _buildChoice(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('mission.pay.choice_title'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(context.tr('mission.pay.choice_desc'),
            style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: _busy ? null : _payCash,
          icon: const Icon(Icons.payments_outlined),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(context.tr('mission.pay.cash')),
          ),
          style: OutlinedButton.styleFrom(minimumSize: const Size(double.infinity, 60)),
        ),
        const SizedBox(height: 12),
        if (widget.mission.freelancer?.acceptPlatformPayment != false)
          ElevatedButton.icon(
            onPressed: _busy ? null : () => setState(() => _step = _Step.form),
            icon: const Icon(Icons.phone_android),
            label: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(context.tr('mission.pay.platform')),
            ),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 60),
              backgroundColor: AppColors.royalBlue,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildForm(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(context.tr('mission.pay.platform'),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(
          '${context.tr('mission.pay.amount_due')}: ${widget.mission.cout?.toStringAsFixed(0) ?? '0'} XAF',
          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _ProviderButton(
                selected: _provider == 'OM',
                label: 'Orange Money',
                color: Colors.orange,
                onTap: () => setState(() => _provider = 'OM'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProviderButton(
                selected: _provider == 'MOMO',
                label: 'MTN MoMo',
                color: Colors.amber,
                onTap: () => setState(() => _provider = 'MOMO'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
              labelText: context.tr('mission.pay.select_provider'),
              hintText: context.tr('mission.pay.phone_hint'),
              prefixText: '+237 '),
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
                const Icon(Icons.error_outline, color: AppColors.error, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(_errorMessage!,
                      style:
                          const TextStyle(color: AppColors.error, fontSize: 13)),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _payPlatform,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(context.tr('mission.pay.confirm')),
          ),
        ),
      ],
    );
  }

  Widget _buildWaiting(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        const CircularProgressIndicator(),
        const SizedBox(height: 20),
        Text(context.tr('mission.pay.validation_required'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        const Icon(Icons.check_circle, color: AppColors.success, size: 64),
        const SizedBox(height: 16),
        Text(context.tr('mission.pay.success'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ),
      ],
    );
  }

  Widget _buildFailed(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        const Icon(Icons.cancel_outlined, color: AppColors.error, size: 64),
        const SizedBox(height: 16),
        Text(context.tr('mission.pay.failed'),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(context.tr('common.cancel')),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: () => setState(() => _step = _Step.form),
                child: Text(context.tr('common.retry')),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({
    required this.selected,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final bool selected;
  final String label;
  final Color color;
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
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selected ? color : AppColors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
