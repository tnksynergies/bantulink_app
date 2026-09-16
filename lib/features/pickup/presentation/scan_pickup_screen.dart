import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/i18n/app_localizations.dart';
import '../application/pickup_providers.dart';

class ScanPickupScreen extends ConsumerStatefulWidget {
  const ScanPickupScreen({super.key});

  @override
  ConsumerState<ScanPickupScreen> createState() => _ScanPickupScreenState();
}

class _ScanPickupScreenState extends ConsumerState<ScanPickupScreen> {
  final MobileScannerController _controller = MobileScannerController();
  bool _processing = false;
  bool _validated = false;
  String? _error;
  Map<String, dynamic>? _result;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_processing || _validated) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    setState(() { _processing = true; _error = null; });
    _controller.stop();

    try {
      final data = await ref.read(pickupDataSourceProvider).validate(barcode.rawValue!);
      if (data['data'] != null) {
        setState(() {
          _validated = true;
          _result = Map<String, dynamic>.from(data['data']);
        });
      } else {
        setState(() => _error = data['message'] ?? 'Code invalide.');
        _controller.start();
      }
    } catch (e) {
      setState(() => _error = '$e');
      _controller.start();
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.tr('pickup.scanTitle'))),
      body: _validated
          ? _buildSuccess()
          : Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(20)),
                    child: MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (_processing)
                        const CircularProgressIndicator()
                      else ...[
                        Text(
                          context.tr('pickup.scanInstructions'),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textMuted),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _error!,
                              style: TextStyle(
                                  color: Colors.red.shade700, fontSize: 13),
                            ),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSuccess() {
    final commande = _result?['commande'];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, size: 48, color: Colors.green.shade700),
            ),
            const SizedBox(height: 20),
            Text(
              context.tr('pickup.validated'),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            if (commande != null) ...[
              Text(
                'Commande : ${commande['numero'] ?? '#${commande['id']}'}',
                style: TextStyle(fontSize: 14, color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text('Terminé',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
