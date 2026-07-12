import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/widgets.dart' show BuildContext;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/market/data/models/order.dart';
import '../i18n/app_localizations.dart';

/// Capture tous les libelles i18n des factures AVANT un async gap
/// (BuildContext inutilisable apres await). A passer aux generateurs via
/// `(k) => labels[k] ?? k`.
Map<String, String> invoiceLabels(BuildContext context) => {
      for (final k in const [
        'invoice.title',
        'invoice.order',
        'invoice.date',
        'invoice.item',
        'invoice.qty',
        'invoice.unit_price',
        'invoice.total',
        'invoice.subtotal',
        'invoice.delivery',
        'invoice.grand_total',
        'invoice.fees_note',
        'invoice.generated_by',
        'invoice.mission',
        'invoice.subscription',
        'invoice.freelance_note',
        'fees.commission',
        'fees.net_received',
        'sub.active_until',
      ])
        k: context.tr(k),
    };

/// Identite visuelle d'une facture selon le role de l'emetteur :
///   - Freelance  : logo BantuLink uniquement.
///   - Recruteur  : logo BantuHire + logo de l'entreprise du recruteur.
///   - Vendeur    : logo BantuMarket + logo de la boutique du vendeur.
class InvoiceBrand {
  const InvoiceBrand({
    required this.platformLabel,
    required this.accentColor,
    this.platformLogo,
    this.partnerLogo,
    this.partnerName,
  });

  /// Nom de la plateforme (fallback texte si le logo ne charge pas).
  final String platformLabel;
  final PdfColor accentColor;
  final pw.MemoryImage? platformLogo;

  /// Logo + nom du partenaire (entreprise du recruteur / boutique du
  /// vendeur). Null pour le freelance (BantuLink uniquement).
  final pw.MemoryImage? partnerLogo;
  final String? partnerName;

  static const _orange = PdfColor.fromInt(0xFFFF7A00);
  static const _blue = PdfColor.fromInt(0xFF1C2F6B);
  static const _green = PdfColor.fromInt(0xFF22C55E);

  /// Freelance : BantuLink uniquement.
  static Future<InvoiceBrand> freelance() async {
    return InvoiceBrand(
      platformLabel: 'BantuLink',
      accentColor: _orange,
      platformLogo: await _asset('assets/logos/logobantulink.png'),
    );
  }

  /// Recruteur : BantuHire + logo de l'entreprise.
  static Future<InvoiceBrand> recruiter(
      {String? companyLogoUrl, String? companyName}) async {
    return InvoiceBrand(
      platformLabel: 'BantuHire',
      accentColor: _blue,
      platformLogo: await _asset('assets/logos/logobantuhire.png'),
      partnerLogo: await _network(companyLogoUrl),
      partnerName: companyName,
    );
  }

  /// Vendeur : BantuMarket + logo de la boutique.
  static Future<InvoiceBrand> vendor(
      {String? shopLogoUrl, String? shopName}) async {
    return InvoiceBrand(
      platformLabel: 'BantuMarket',
      accentColor: _green,
      platformLogo: await _asset('assets/logos/logobantumarket.png'),
      partnerLogo: await _network(shopLogoUrl),
      partnerName: shopName,
    );
  }

  /// Acheteur (commande) : BantuMarket sans partenaire.
  static Future<InvoiceBrand> market() async {
    return InvoiceBrand(
      platformLabel: 'BantuMarket',
      accentColor: _green,
      platformLogo: await _asset('assets/logos/logobantumarket.png'),
    );
  }

  static Future<pw.MemoryImage?> _asset(String path) async {
    try {
      final data = await rootBundle.load(path);
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null; // fallback texte
    }
  }

  static Future<pw.MemoryImage?> _network(String? url) async {
    if (url == null || url.isEmpty) return null;
    try {
      final res = await Dio().get<List<int>>(
        url,
        options: Options(
            responseType: ResponseType.bytes,
            receiveTimeout: const Duration(seconds: 10)),
      );
      final bytes = res.data;
      if (bytes == null || bytes.isEmpty) return null;
      return pw.MemoryImage(Uint8List.fromList(bytes));
    } catch (_) {
      return null; // le logo distant ne doit jamais bloquer la facture
    }
  }
}

/// Ligne generique d'une facture.
class InvoiceLine {
  const InvoiceLine({
    required this.label,
    required this.qty,
    required this.unitPrice,
    required this.total,
  });
  final String label;
  final String qty;
  final String unitPrice;
  final String total;
}

/// Generation + impression des factures BantuLink (commande, mission,
/// abonnement). `Printing.layoutPdf` ouvre le dialogue natif : imprimer,
/// enregistrer en PDF ou partager.
class InvoicePdf {
  InvoicePdf._();

  static const _grey = PdfColor.fromInt(0xFF6B7280);
  static const _border = PdfColor.fromInt(0xFFE5E7EB);
  static const _blue = PdfColor.fromInt(0xFF1C2F6B);

  static String _money(num? v) => '${(v ?? 0).toStringAsFixed(0)} XAF';

  /// Facture d'une commande BantuMarket.
  /// [brand] : InvoiceBrand.market() cote acheteur, InvoiceBrand.vendor()
  /// cote vendeur (logo boutique).
  static Future<void> printOrder(
    Order order,
    String Function(String key) tr, {
    InvoiceBrand? brand,
    String? customerName,
  }) async {
    final b = brand ?? await InvoiceBrand.market();

    final deliveryParts = <String>[
      if (customerName != null && customerName.isNotEmpty) customerName,
      if (order.adresseLivraison != null) order.adresseLivraison!,
      if (order.villeLivraison != null) order.villeLivraison!,
      if (order.paysLivraison != null) order.paysLivraison!,
      if (order.telLivraison != null) order.telLivraison!,
    ];

    await _print(
      fileName: 'facture_commande_${order.id}.pdf',
      brand: b,
      tr: tr,
      reference: '${tr('invoice.order')} #${order.id}',
      date: order.dateCourt,
      infoLine: deliveryParts.isEmpty ? null : deliveryParts.join(' · '),
      lines: [
        for (final item in order.produits)
          InvoiceLine(
            label: item.produit.nomSafe,
            qty: '${item.quantite}',
            unitPrice: _money(item.prixUnitaire ?? item.produit.prix),
            total: _money(item.lineTotal),
          ),
      ],
      totals: [
        (tr('invoice.subtotal'), _money(order.sousTotal), false),
        (tr('invoice.delivery'), _money(order.fraisLivraison), false),
        (tr('invoice.grand_total'), _money(order.total), true),
      ],
      footNote: tr('invoice.fees_note'),
    );
  }

  /// Facture d'une prestation freelance (logo BantuLink uniquement).
  /// Detaille la commission par palier et le net percu par le freelance.
  static Future<void> printMission({
    required int missionId,
    required String missionTitle,
    required num amount,
    required double commissionPercent,
    required num commissionAmount,
    required num netAmount,
    String? date,
    String? clientName,
    required String Function(String key) tr,
  }) async {
    final b = await InvoiceBrand.freelance();
    await _print(
      fileName: 'facture_mission_$missionId.pdf',
      brand: b,
      tr: tr,
      reference: '${tr('invoice.mission')} #$missionId',
      date: date ?? '',
      infoLine: clientName,
      lines: [
        InvoiceLine(
          label: missionTitle,
          qty: '1',
          unitPrice: _money(amount),
          total: _money(amount),
        ),
      ],
      totals: [
        (tr('invoice.subtotal'), _money(amount), false),
        (
          '${tr('fees.commission')} (${commissionPercent.toStringAsFixed(2).replaceAll('.', ',')} %)',
          '- ${_money(commissionAmount)}',
          false
        ),
        (tr('fees.net_received'), _money(netAmount), true),
      ],
      footNote: tr('invoice.freelance_note'),
    );
  }

  /// Facture d'abonnement (recruteur Pro : BantuHire + logo entreprise ;
  /// reutilisable pour candidat/freelance avec le brand adapte).
  static Future<void> printSubscription({
    required InvoiceBrand brand,
    required String planLabel,
    required num amount,
    required String periodLabel,
    String? activeUntil,
    String? date,
    required String Function(String key) tr,
  }) async {
    await _print(
      fileName:
          'facture_abonnement_${planLabel.toLowerCase().replaceAll(' ', '_')}.pdf',
      brand: brand,
      tr: tr,
      reference: tr('invoice.subscription'),
      date: date ?? '',
      infoLine: activeUntil == null
          ? null
          : '${tr('sub.active_until')} $activeUntil',
      lines: [
        InvoiceLine(
          label: '$planLabel — $periodLabel',
          qty: '1',
          unitPrice: _money(amount),
          total: _money(amount),
        ),
      ],
      totals: [
        (tr('invoice.grand_total'), _money(amount), true),
      ],
      footNote: null,
    );
  }

  // ------------------------------------------------------------------
  // Rendu commun
  // ------------------------------------------------------------------
  static Future<void> _print({
    required String fileName,
    required InvoiceBrand brand,
    required String Function(String key) tr,
    required String reference,
    required String date,
    String? infoLine,
    required List<InvoiceLine> lines,
    required List<(String, String, bool)> totals,
    String? footNote,
  }) async {
    final doc = pw.Document();

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ---- En-tete : logo plateforme + FACTURE ----
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (brand.platformLogo != null)
                        pw.Image(brand.platformLogo!,
                            height: 42, fit: pw.BoxFit.contain)
                      else
                        pw.Text(brand.platformLabel,
                            style: pw.TextStyle(
                                fontSize: 24,
                                fontWeight: pw.FontWeight.bold,
                                color: brand.accentColor)),
                      pw.SizedBox(height: 4),
                      pw.Text(tr('invoice.generated_by'),
                          style: const pw.TextStyle(
                              fontSize: 9, color: _grey)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(tr('invoice.title').toUpperCase(),
                          style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: _blue)),
                      pw.SizedBox(height: 4),
                      pw.Text(reference,
                          style: const pw.TextStyle(fontSize: 11)),
                      if (date.isNotEmpty)
                        pw.Text('${tr('invoice.date')} : $date',
                            style: const pw.TextStyle(
                                fontSize: 11, color: _grey)),
                    ],
                  ),
                ],
              ),

              // ---- Partenaire (entreprise recruteur / boutique vendeur) ----
              if (brand.partnerLogo != null ||
                  (brand.partnerName != null &&
                      brand.partnerName!.isNotEmpty)) ...[
                pw.SizedBox(height: 12),
                pw.Row(
                  children: [
                    if (brand.partnerLogo != null) ...[
                      pw.Container(
                        width: 36,
                        height: 36,
                        decoration: pw.BoxDecoration(
                          shape: pw.BoxShape.circle,
                          border: pw.Border.all(color: _border),
                        ),
                        child: pw.ClipOval(
                          child: pw.Image(brand.partnerLogo!,
                              fit: pw.BoxFit.cover),
                        ),
                      ),
                      pw.SizedBox(width: 8),
                    ],
                    if (brand.partnerName != null &&
                        brand.partnerName!.isNotEmpty)
                      pw.Text(brand.partnerName!,
                          style: pw.TextStyle(
                              fontSize: 13,
                              fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],

              pw.SizedBox(height: 14),
              pw.Divider(color: _border, thickness: 1),

              if (infoLine != null && infoLine.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text(infoLine,
                    style: const pw.TextStyle(fontSize: 10, color: _grey)),
              ],
              pw.SizedBox(height: 16),

              // ---- Lignes ----
              pw.TableHelper.fromTextArray(
                headers: [
                  tr('invoice.item'),
                  tr('invoice.qty'),
                  tr('invoice.unit_price'),
                  tr('invoice.total'),
                ],
                data: [
                  for (final l in lines) [l.label, l.qty, l.unitPrice, l.total],
                ],
                headerStyle: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: brand.accentColor),
                cellStyle: const pw.TextStyle(fontSize: 10),
                cellAlignments: {
                  0: pw.Alignment.centerLeft,
                  1: pw.Alignment.center,
                  2: pw.Alignment.centerRight,
                  3: pw.Alignment.centerRight,
                },
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                border: pw.TableBorder.all(color: _border, width: 0.5),
              ),
              pw.SizedBox(height: 14),

              // ---- Totaux ----
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.SizedBox(
                    width: 240,
                    child: pw.Column(
                      children: [
                        for (final t in totals) ...[
                          if (t.$3)
                            pw.Divider(color: _border, thickness: 0.5),
                          _totalRow(t.$1, t.$2,
                              bold: t.$3, accent: brand.accentColor),
                        ],
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // ---- Note + pied de page ----
              if (footNote != null && footNote.isNotEmpty) ...[
                pw.Container(
                  width: double.infinity,
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFF7F8FA),
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(footNote,
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontStyle: pw.FontStyle.italic,
                          color: _grey)),
                ),
                pw.SizedBox(height: 10),
              ],
              pw.Center(
                child: pw.Text(tr('invoice.generated_by'),
                    style: const pw.TextStyle(fontSize: 9, color: _grey)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (_) => doc.save(),
      name: fileName,
    );
  }

  static pw.Widget _totalRow(String label, String value,
      {bool bold = false, required PdfColor accent}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label,
              style: pw.TextStyle(
                  fontSize: bold ? 11 : 10,
                  fontWeight:
                      bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value,
              style: pw.TextStyle(
                  fontSize: bold ? 12 : 10,
                  fontWeight:
                      bold ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: bold ? accent : PdfColors.black)),
        ],
      ),
    );
  }
}
