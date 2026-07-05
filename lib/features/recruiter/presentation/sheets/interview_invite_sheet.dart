import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/i18n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../application/recruiter_providers.dart';

/// Sheet pour envoyer une invitation d'entretien.
/// Utilise updateStatus avec statut=invitation_entretien + extras.
class InterviewInviteSheet extends ConsumerStatefulWidget {
  const InterviewInviteSheet({super.key, required this.applicationId});
  final int applicationId;

  @override
  ConsumerState<InterviewInviteSheet> createState() => _InterviewInviteSheetState();
}

class _InterviewInviteSheetState extends ConsumerState<InterviewInviteSheet> {
  DateTime? _date;
  TimeOfDay? _time;
  String _mode = 'visio';
  final _lieuCtrl = TextEditingController();
  final _lienCtrl = TextEditingController();
  bool _busy = false;
  String? _errorMessage;

  @override
  void dispose() {
    _lieuCtrl.dispose();
    _lienCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 10, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  String? _formattedDateTime() {
    if (_date == null || _time == null) return null;
    final d = _date!;
    final t = _time!;
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')} '
        '${t.hour.toString().padLeft(2, '0')}:'
        '${t.minute.toString().padLeft(2, '0')}:00';
  }

  Future<void> _submit() async {
    final iso = _formattedDateTime();
    if (iso == null) {
      setState(() => _errorMessage = context.tr('interview.date_required'));
      return;
    }
    if (_mode == 'presentiel' && _lieuCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = context.tr('interview.location_required'));
      return;
    }
    if (_mode == 'visio' && _lienCtrl.text.trim().isEmpty) {
      setState(() => _errorMessage = context.tr('interview.link_required'));
      return;
    }
    setState(() {
      _busy = true;
      _errorMessage = null;
    });
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(updateApplicationStatusControllerProvider(widget.applicationId)
              .notifier)
          .submit(
            statut: 'invitation_entretien',
            dateEntretien: iso,
            modeEntretien: _mode,
            lieuEntretien: _mode == 'presentiel' ? _lieuCtrl.text.trim() : null,
            lienVisio: _mode == 'visio' ? _lienCtrl.text.trim() : null,
          );
      if (!mounted) return;
      Navigator.pop(context);
      messenger.showSnackBar(
        SnackBar(content: Text(context.mounted ? context.tr('interview.sent') : '')),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(context.tr('interview.title'),
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Date + heure sur une ligne
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    child: InputDecorator(
                      decoration: InputDecoration(
                        labelText: context.tr('interview.date'),
                        suffixIcon: const Icon(Icons.calendar_today, size: 16),
                      ),
                      child: Text(_date == null
                          ? '-'
                          : '${_date!.year}-${_date!.month.toString().padLeft(2, '0')}-${_date!.day.toString().padLeft(2, '0')}'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: _pickTime,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'HH:mm',
                        suffixIcon: Icon(Icons.access_time, size: 16),
                      ),
                      child: Text(_time == null
                          ? '-'
                          : '${_time!.hour.toString().padLeft(2, '0')}:${_time!.minute.toString().padLeft(2, '0')}'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Mode d'entretien
            Text(context.tr('interview.mode'),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: _modeBtn(
                    label: context.tr('interview.mode_visio'),
                    icon: Icons.videocam_outlined,
                    selected: _mode == 'visio',
                    onTap: () => setState(() => _mode = 'visio'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _modeBtn(
                    label: context.tr('interview.mode_in_person'),
                    icon: Icons.location_on_outlined,
                    selected: _mode == 'presentiel',
                    onTap: () => setState(() => _mode = 'presentiel'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_mode == 'visio')
              TextField(
                controller: _lienCtrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: context.tr('interview.visio_link'),
                  hintText: 'https://meet...',
                ),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              )
            else
              TextField(
                controller: _lieuCtrl,
                decoration: InputDecoration(
                  labelText: context.tr('interview.location'),
                ),
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
              ),

            if (_errorMessage != null) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: AppColors.error.withOpacity(0.35))),
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
            ElevatedButton(
              onPressed: _busy ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6D28D9),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(context.tr('interview.send')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _modeBtn({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
              color: selected ? const Color(0xFF6D28D9) : AppColors.border,
              width: selected ? 2 : 1),
          borderRadius: BorderRadius.circular(10),
          color: selected
              ? const Color(0xFF6D28D9).withOpacity(0.08)
              : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: selected
                    ? const Color(0xFF6D28D9)
                    : AppColors.textPrimary),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? const Color(0xFF6D28D9)
                        : AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
