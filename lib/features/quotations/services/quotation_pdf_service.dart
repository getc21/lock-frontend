import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:bellezapp_web/shared/models/quotation.dart';

class QuotationPdfService {
  static Future<void> exportToPdf(Quotation quotation) async {
    final pdf = pw.Document();
    final shortId = (quotation.id ?? 'N/A')
        .substring(0, quotation.id != null ? 8 : 3)
        .toUpperCase();
    final dateFormat = DateFormat('dd/MM/yyyy');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'COTIZACIÓN',
                        style: pw.TextStyle(
                          fontSize: 28,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.blueGrey800,
                        ),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        '#$shortId',
                        style: pw.TextStyle(
                          fontSize: 14,
                          color: PdfColors.grey600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Divider(color: PdfColors.blueGrey200),
              pw.SizedBox(height: 16),

              // Info cliente y fechas
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('CLIENTE',
                            style: pw.TextStyle(
                                fontSize: 10,
                                color: PdfColors.grey600,
                                fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          quotation.customerName ?? 'No especificado',
                          style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        _infoRow('Fecha de emisión:',
                            dateFormat.format(quotation.quotationDate)),
                        pw.SizedBox(height: 4),
                        _infoRow(
                          'Vencimiento:',
                          quotation.expirationDate != null
                              ? dateFormat.format(quotation.expirationDate!)
                              : 'No definida',
                        ),
                        if (quotation.paymentMethod != null) ...[
                          pw.SizedBox(height: 4),
                          _infoRow('Método de pago:', quotation.paymentMethod!),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 24),

              // Tabla de productos
              pw.Text('ARTÍCULOS',
                  style: pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey600,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.blueGrey100, width: 0.5),
                columnWidths: {
                  0: const pw.FlexColumnWidth(4),
                  1: const pw.FlexColumnWidth(1.5),
                  2: const pw.FlexColumnWidth(2),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.blueGrey800),
                    children: [
                      _tableHeader('Producto'),
                      _tableHeader('Cant.', align: pw.TextAlign.center),
                      _tableHeader('Precio unit.', align: pw.TextAlign.right),
                      _tableHeader('Subtotal', align: pw.TextAlign.right),
                    ],
                  ),
                  // Item rows
                  ...quotation.items.asMap().entries.map((entry) {
                    final i = entry.key;
                    final item = entry.value;
                    final subtotal = item.quantity * item.price;
                    final bg = i.isEven ? PdfColors.white : PdfColors.blueGrey50;
                    return pw.TableRow(
                      decoration: pw.BoxDecoration(color: bg),
                      children: [
                        _tableCell(item.productName ?? 'Sin nombre'),
                        _tableCell(item.quantity.toString(), align: pw.TextAlign.center),
                        _tableCell('Bs. ${item.price.toStringAsFixed(2)}', align: pw.TextAlign.right),
                        _tableCell('Bs. ${subtotal.toStringAsFixed(2)}', align: pw.TextAlign.right),
                      ],
                    );
                  }),
                ],
              ),
              pw.SizedBox(height: 16),

              // Totales
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 220,
                    child: pw.Column(
                      children: [
                        _totalRow('Subtotal:', _calculateSubtotal(quotation)),
                        if (quotation.discountAmount > 0) ...[
                          pw.SizedBox(height: 4),
                          _totalRow('Descuento:', quotation.discountAmount,
                              color: PdfColors.red700),
                        ],
                        pw.SizedBox(height: 6),
                        pw.Divider(color: PdfColors.blueGrey300),
                        pw.SizedBox(height: 6),
                        _totalRow('TOTAL:', quotation.totalQuotation, isTotal: true),
                      ],
                    ),
                  ),
                ],
              ),

              // Notas
              if (quotation.notes != null && quotation.notes!.isNotEmpty) ...[
                pw.SizedBox(height: 24),
                pw.Text('NOTAS',
                    style: pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey600,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey100,
                    borderRadius: pw.BorderRadius.circular(6),
                  ),
                  child: pw.Text(quotation.notes!,
                      style: const pw.TextStyle(fontSize: 11)),
                ),
              ],

              pw.Spacer(),
              pw.Divider(color: PdfColors.blueGrey200),
              pw.SizedBox(height: 6),
              pw.Center(
                child: pw.Text(
                  'Documento generado el ${dateFormat.format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
                ),
              ),
            ],
          );
        },
      ),
    );

    final fileName = 'cotizacion_$shortId.pdf';

    if (kIsWeb) {
      await Printing.sharePdf(bytes: await pdf.save(), filename: fileName);
    } else {
      await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(),
        name: fileName,
      );
    }
  }

  static double _calculateSubtotal(Quotation q) =>
      q.items.fold(0, (sum, item) => sum + item.quantity * item.price);

  static pw.Widget _infoRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.end,
      children: [
        pw.Text(label,
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey600)),
        pw.SizedBox(width: 6),
        pw.Text(value,
            style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
      ],
    );
  }

  static pw.Widget _tableHeader(String text,
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(
        text,
        textAlign: align,
        style: pw.TextStyle(
          color: PdfColors.white,
          fontWeight: pw.FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  static pw.Widget _tableCell(String text,
      {pw.TextAlign align = pw.TextAlign.left}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: pw.Text(text, textAlign: align, style: const pw.TextStyle(fontSize: 11)),
    );
  }

  static pw.Widget _totalRow(String label, double amount,
      {PdfColor? color, bool isTotal = false}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: isTotal ? 13 : 11,
            fontWeight: isTotal ? pw.FontWeight.bold : null,
          ),
        ),
        pw.Text(
          'Bs. ${amount.toStringAsFixed(2)}',
          style: pw.TextStyle(
            fontSize: isTotal ? 13 : 11,
            fontWeight: isTotal ? pw.FontWeight.bold : null,
            color: color,
          ),
        ),
      ],
    );
  }
}
