import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../data/models/order.dart';

/// Generation + impression de la facture d'une commande BantuMarket
/// (point 7 de la seance de travail). `Printing.layoutPdf` ouvre le
/// dialogue natif : imprimer, enregistrer en PDF ou partager.
class InvoicePdf {
  InvoicePdf._();

  static const _brandOrange = PdfColor.fromInt(0xFFFF7A00);
  static const _brandBlue = PdfColor.fromInt(0xFF1C2F6B);
  static const _grey = PdfColor.fromInt(0xFF6B7280);
  static const _border = PdfColor.fromInt(0xFFE5E7EB);

  /// [tr] : resolveur i18n capture AVANT l'async gap (context.tr).
  static Future<void> printOrder(
    Order order,
    String Function(String key) tr, {
    String? customerName,
  }) async {
    final doc = pw.Document();

    String money(num? v) => '${(v ?? 0).toStringAsFixed(0)} XAF';

    final deliveryParts = <String>[
      if (customerName != null && customerName.isNotEmpty) customerName,
      if (order.adresseLivraison != null) order.adresseLivraison!,
      if (order.villeLivraison != null) order.villeLivraison!,
      if (order.paysLivraison != null) order.paysLivraison!,
      if (order.telLivraison != null) order.telLivraison!,
    ];

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ---- En-tete ----
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('BantuLink',
                          style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: _brandOrange)),
                      pw.Text('BantuMarket',
                          style: const pw.TextStyle(
                              fontSize: 11, color: _grey)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(tr('invoice.title').toUpperCase(),
                          style: pw.TextStyle(
                              fontSize: 20,
                              fontWeight: pw.FontWeight.bold,
                              color: _brandBlue)),
                      pw.SizedBox(height: 4),
                      pw.Text('${tr('invoice.order')} #${order.id}',
                          style: const pw.TextStyle(fontSize: 11)),
                      pw.Text('${tr('invoice.date')} : ${order.dateCourt}',
                          style: const pw.TextStyle(
                              fontSize: 11, color: _grey)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: _border, thickness: 1),

              // ---- Livraison ----
              if (deliveryParts.isNotEmpty) ...[
                pw.SizedBox(height: 8),
                pw.Text(deliveryParts.join(' · '),
                    style: const pw.TextStyle(fontSize: 10, color: _grey)),
              ],
              pw.SizedBox(height: 16),

              // ---- Lignes de la commande ----
              pw.TableHelper.fromTextArray(
                headers: [
                  tr('invoice.item'),
                  tr('invoice.qty'),
                  tr('invoice.unit_price'),
                  tr('invoice.total'),
                ],
                data: [
                  for (final item in order.produits)
                    [
                      item.produit.nomSafe,
                      '${item.quantite}',
                      money(item.prixUnitaire ?? item.produit.prix),
                      money(item.lineTotal),
                    ],
                ],
                headerStyle: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: _brandBlue),
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
                    width: 220,
                    child: pw.Column(
                      children: [
                        _totalRow(tr('invoice.subtotal'),
                            money(order.sousTotal)),
                        _totalRow(tr('invoice.delivery'),
                            money(order.fraisLivraison)),
                        pw.Divider(color: _border, thickness: 0.5),
                        _totalRow(tr('invoice.grand_total'),
                            money(order.total),
                            bold: true),
                      ],
                    ),
                  ),
                ],
              ),

              pw.Spacer(),

              // ---- Transparence tarifaire + pied de page ----
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: const PdfColor.fromInt(0xFFF7F8FA),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(tr('invoice.fees_note'),
                    style: pw.TextStyle(
                        fontSize: 9,
                        fontStyle: pw.FontStyle.italic,
                        color: _grey)),
              ),
              pw.SizedBox(height: 10),
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
      name: 'facture_commande_${order.id}.pdf',
    );
  }

  static pw.Widget _totalRow(String label, String value, {bool bold = false}) {
    final style = pw.TextStyle(
      fontSize: bold ? 12 : 10,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
      color: bold ? _brandOrange : PdfColors.black,
    );
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
          pw.Text(value, style: style),
        ],
      ),
    );
  }
}
