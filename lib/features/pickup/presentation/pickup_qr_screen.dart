import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../application/pickup_providers.dart';

class PickupQrScreen extends ConsumerStatefulWidget {
  final int commandeId;
  const PickupQrScreen({super.key, required this.commandeId});

  @override
  ConsumerState<PickupQrScreen> createState() => _PickupQrScreenState();
}

class _PickupQrScreenState extends ConsumerState<PickupQrScreen> {
  bool _loading = true;
  String? _token;
  String? _status;
  String? _error;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data =
          await ref.read(pickupDataSourceProvider).generate(widget.commandeId);
      if (data['token'] != null) {
        _token = data['token'];
        _status = 'pending';
      } else {
        _status = data['status'] ?? 'pending';
        _error = 'Un code existe deja. Presentez le QR code original.';
      }
    } catch (e) {
      _error = '$e';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('pickup.qrTitle'))),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (_token != null) ...[
                    Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            QrImageView(
                              data: _token!,
                              version: QrVersions.auto,
                              size: 250,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.circle,
                                color: Colors.black,
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.circle,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              context.tr('pickup.showToSeller'),
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 14, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.timer,
                              color: Colors.green.shade700, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            context.tr('pickup.validFor48h'),
                            style: TextStyle(
                                color: Colors.green.shade700, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 20),
                    Icon(Icons.info_outline, size: 48, color: Colors.orange),
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}
