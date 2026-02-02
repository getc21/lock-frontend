// ignore_for_file: avoid_print, implementation_imports
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io;
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

class PdfService {
  // Obtener hora actual de Bolivia (UTC-4)
  static DateTime _getBoliviaTime() {
    // Bolivia está en zona UTC-4
    final utcNow = DateTime.now().toUtc();
    return utcNow.add(const Duration(hours: -4));
  }
  static Future<String> generateInventoryRotationPdf({
    required Map<String, dynamic> data,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final products = data['products'] as List? ?? [];
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          _buildHeader('Reporte de Rotación de Inventario', startDate, endDate),
          pw.SizedBox(height: 20),
          
          // Resumen
          _buildSummarySection(
            'Resumen General',
            [
              ('Rotación Promedio', '${summary['averageRotationRate']?.toStringAsFixed(2) ?? '0'} veces'),
              ('Productos Activos', '${summary['totalProducts'] ?? 0}'),
              ('Productos Rápidos', '${summary['fastMovingProducts'] ?? 0}'),
              ('Productos Lentos', '${summary['slowMovingProducts'] ?? 0}'),
            ],
          ),
          pw.SizedBox(height: 20),
          
          // Tabla de productos
          pw.Text('Análisis por Producto', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _buildProductsTable(products),
        ],
      ),
    );

    return await _savePdf(pdf, 'Rotacion_Inventario_${DateFormat('dd-MM-yyyy').format(_getBoliviaTime())}');
  }

  static Future<String> generateProfitabilityPdf({
    required Map<String, dynamic> data,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final products = data['products'] as List? ?? [];
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          _buildHeader('Reporte de Rentabilidad', startDate, endDate),
          pw.SizedBox(height: 20),
          
          // Resumen financiero
          _buildSummarySection(
            'Resumen Financiero',
            [
              ('Ventas Totales', '\$${(summary['totalRevenue'] ?? 0).toStringAsFixed(2)}'),
              ('Ganancia', '\$${(summary['totalProfit'] ?? 0).toStringAsFixed(2)}'),
              ('Margen Promedio', '${(summary['averageProfitMargin'] ?? 0).toStringAsFixed(1)}%'),
              ('Productos', '${summary['productCount'] ?? 0}'),
            ],
          ),
          pw.SizedBox(height: 20),
          
          // Tabla de rentabilidad
          pw.Text('Rentabilidad por Producto', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _buildProfitabilityTable(products),
        ],
      ),
    );

    return await _savePdf(pdf, 'Rentabilidad_${DateFormat('dd-MM-yyyy').format(_getBoliviaTime())}');
  }

  static Future<String> generateSalesTrendsPdf({
    required Map<String, dynamic> data,
    required DateTime startDate,
    required DateTime endDate,
    required String period,
  }) async {
    final pdf = pw.Document();
    
    final trends = data['trends'] as List? ?? [];
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          _buildHeader('Reporte de Tendencias de Ventas', startDate, endDate),
          pw.SizedBox(height: 20),
          
          // Resumen de tendencias
          _buildSummarySection(
            'Resumen de Tendencias',
            [
              ('Ventas Totales', '\$${(summary['totalRevenue'] ?? 0).toStringAsFixed(2)}'),
              ('Total Órdenes', '${summary['totalOrders'] ?? 0}'),
              ('Promedio Diario', '\$${(summary['averageDaily'] ?? 0).toStringAsFixed(2)}'),
              ('Valor Promedio Orden', '\$${(summary['averageOrderValue'] ?? 0).toStringAsFixed(2)}'),
            ],
          ),
          pw.SizedBox(height: 20),
          
          pw.Text('Período: ${_getPeriodLabel(period)}', style: pw.TextStyle(fontSize: 12, fontStyle: pw.FontStyle.italic)),
          pw.SizedBox(height: 10),
          
          // Tabla de tendencias
          _buildTrendsTable(trends),
        ],
      ),
    );

    return await _savePdf(pdf, 'Tendencias_Ventas_${DateFormat('dd-MM-yyyy').format(_getBoliviaTime())}');
  }

  static Future<String> generateComparisonPdf({
    required Map<String, dynamic> data,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final pdf = pw.Document();
    
    final comparison = data['comparison'] as Map<String, dynamic>? ?? {};
    final current = comparison['currentPeriod'] as Map<String, dynamic>? ?? {};
    final previous = comparison['previousPeriod'] as Map<String, dynamic>? ?? {};
    final productComparisons = data['productComparisons'] as List? ?? [];
    final profitabilityProducts = data['profitabilityProducts'] as List? ?? [];
    
    // Extract profitability names sorted by revenue (same logic as UI table)
    final profitabilityNames = <String>[];
    if (profitabilityProducts.isNotEmpty) {
      final sortedProfitability = List.from(profitabilityProducts);
      sortedProfitability.sort((a, b) {
        final saleA = (a['totalRevenue'] ?? 0) as num;
        final saleB = (b['totalRevenue'] ?? 0) as num;
        return saleB.compareTo(saleA); // Descendente
      });

      for (var p in sortedProfitability) {
        final name = p['productName']?.toString();
        if (name != null && name.isNotEmpty) {
          profitabilityNames.add(name);
        }
      }
    }
    
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(30),
        build: (context) => [
          _buildHeader('Reporte Comparativo', startDate, endDate),
          pw.SizedBox(height: 20),
          
          // Comparación de métricas principales
          pw.Text('Comparación de Métricas Principales', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 10),
          _buildComparisonTable(current, previous, comparison),
          pw.SizedBox(height: 20),
          
          // Tabla de comparación de productos
          if (productComparisons.isNotEmpty) ...[
            pw.Text('Top 10 Productos - Comparación', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            _buildProductComparisonTable(productComparisons, profitabilityNames),
          ]
        ],
      ),
    );

    return await _savePdf(pdf, 'Comparacion_Periodos_${DateFormat('dd-MM-yyyy').format(_getBoliviaTime())}');
  }

  //

  static pw.Widget _buildHeader(String title, DateTime startDate, DateTime endDate) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Período: ${DateFormat('dd/MM/yyyy').format(startDate)} - ${DateFormat('dd/MM/yyyy').format(endDate)}',
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.Text(
          'Generado: ${DateFormat('dd/MM/yyyy HH:mm').format(_getBoliviaTime())}',
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  static pw.Widget _buildSummarySection(String title, List<(String, String)> items) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceEvenly,
            children: items.map((item) {
              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(item.$1, style: const pw.TextStyle(fontSize: 10)),
                  pw.SizedBox(height: 5),
                  pw.Text(item.$2, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildProductsTable(List products) {
    return pw.TableHelper.fromTextArray(
      headers: ['Producto', 'Stock', 'Vendidos', 'Tasa', 'Dias', 'Estado'],
      data: products.take(20).map((p) {
        final daysToSell = p['daysToSellStock'] ?? 0;
        final rotationRate = p['rotationRate'] ?? 0;
        final statusText = p['status'] ?? 'normal';
        
        String status;
        switch (statusText) {
          case 'fast':
            status = 'Rapido';
            break;
          case 'slow':
            status = 'Lento';
            break;
          default:
            status = 'Normal';
        }
        
        return [
          (p['productName'] ?? '').toString().substring(0, (p['productName'] ?? '').length > 30 ? 30 : (p['productName'] ?? '').length),
          '${p['currentStock'] ?? 0}',
          '${p['totalSold'] ?? 0}',
          '${rotationRate.toStringAsFixed(2)}x',
          '${daysToSell.toStringAsFixed(1)}',
          status,
        ];
      }).toList(),
      border: pw.TableBorder.all(width: 0.5),
      cellHeight: 20,
      cellAlignment: pw.Alignment.center,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
    );
  }

  static pw.Widget _buildProfitabilityTable(List products) {
    return pw.TableHelper.fromTextArray(
      headers: ['Producto', 'Cant', 'Ordenes', 'Ingresos', 'Costo', 'Ganancia', 'Margen%'],
      data: products.take(20).map((p) {
        final margin = p['profitMargin'] ?? 0;
        return [
          (p['productName'] ?? '').toString().substring(0, (p['productName'] ?? '').length > 25 ? 25 : (p['productName'] ?? '').length),
          '${p['totalQuantity'] ?? 0}',
          '${p['orderCount'] ?? 0}',
          '\$${(p['totalRevenue'] ?? 0).toStringAsFixed(2)}',
          '\$${(p['totalCost'] ?? 0).toStringAsFixed(2)}',
          '\$${(p['totalProfit'] ?? 0).toStringAsFixed(2)}',
          '${margin.toStringAsFixed(1)}%',
        ];
      }).toList(),
      border: pw.TableBorder.all(width: 0.5),
      cellHeight: 20,
      cellAlignment: pw.Alignment.center,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
    );
  }

  static pw.Widget _buildTrendsTable(List trends) {
    return pw.TableHelper.fromTextArray(
      headers: ['Periodo', 'Ordenes', 'Ingresos', 'Items', 'Promedio'],
      data: trends.map((t) {
        final period = t['period'] ?? '';
        String formattedPeriod;
        try {
          final date = DateTime.parse(period.toString());
          formattedPeriod = DateFormat('dd/MM/yyyy').format(date);
        } catch (e) {
          formattedPeriod = period.toString();
        }
        
        return [
          formattedPeriod,
          '${t['orderCount'] ?? 0}',
          '\$${(t['totalRevenue'] ?? 0).toStringAsFixed(2)}',
          '${t['totalItems'] ?? 0}',
          '\$${(t['averageOrderValue'] ?? 0).toStringAsFixed(2)}',
        ];
      }).toList(),
      border: pw.TableBorder.all(width: 0.5),
      cellHeight: 20,
      cellAlignment: pw.Alignment.center,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
    );
  }

  static pw.Widget _buildComparisonTable(
    Map<String, dynamic> current,
    Map<String, dynamic> previous,
    Map<String, dynamic> comparison,
  ) {
    return pw.TableHelper.fromTextArray(
      headers: ['Metrica', 'Periodo Actual', 'Anterior', 'Crecimiento%'],
      data: [
        [
          'Ventas Totales',
          '\$${(current['totalSales'] ?? 0).toStringAsFixed(2)}',
          '\$${(previous['totalSales'] ?? 0).toStringAsFixed(2)}',
          '${(comparison['salesGrowth'] ?? 0).toStringAsFixed(1)}%',
        ],
        [
          'Numero Ordenes',
          '${current['totalOrders'] ?? 0}',
          '${previous['totalOrders'] ?? 0}',
          '${(comparison['ordersGrowth'] ?? 0).toStringAsFixed(1)}%',
        ],
        [
          'Ticket Promedio',
          '\$${(current['averageOrderValue'] ?? 0).toStringAsFixed(2)}',
          '\$${(previous['averageOrderValue'] ?? 0).toStringAsFixed(2)}',
          '${(comparison['avgOrderValueGrowth'] ?? 0).toStringAsFixed(1)}%',
        ],
        [
          'Total Items',
          '${current['totalItems'] ?? 0}',
          '${previous['totalItems'] ?? 0}',
          'N/A',
        ],
      ],
      border: pw.TableBorder.all(width: 0.5),
      cellHeight: 25,
      cellAlignment: pw.Alignment.center,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11),
      cellStyle: const pw.TextStyle(fontSize: 10),
    );
  }

  static pw.Widget _buildProductComparisonTable(List products, [List<String> profitabilityNames = const []]) {
    final productsToShow = products.take(10).toList();
    final tableData = <List<String>>[];
    
    for (int i = 0; i < productsToShow.length; i++) {
      final p = productsToShow[i];
      final growth = p['growth'] ?? 0;
      
      // Use mapped name from profitability if available, otherwise use API name
      String productName = p['productName'] ?? '';
      if (i >= 0 && i < profitabilityNames.length && profitabilityNames[i].isNotEmpty) {
        productName = profitabilityNames[i];
      }
      
      final displayName = productName.substring(0, productName.length > 20 ? 20 : productName.length);
      
      tableData.add([
        displayName,
        '\$${(p['currentSales'] ?? 0).toStringAsFixed(2)}',
        '${p['currentQuantity'] ?? 0}',
        '\$${(p['previousSales'] ?? 0).toStringAsFixed(2)}',
        '${p['previousQuantity'] ?? 0}',
        '${growth.toStringAsFixed(1)}%',
      ]);
    }
    
    return pw.TableHelper.fromTextArray(
      headers: ['Producto', 'Ventas Act', 'Cant Act', 'Ventas Ant', 'Cant Ant', 'Crec%'],
      data: tableData,
      border: pw.TableBorder.all(width: 0.5),
      cellHeight: 20,
      cellAlignment: pw.Alignment.center,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
      cellStyle: const pw.TextStyle(fontSize: 9),
    );
  }

  static String _getPeriodLabel(String period) {
    switch (period) {
      case 'daily':
        return 'Diario';
      case 'weekly':
        return 'Semanal';
      case 'monthly':
        return 'Mensual';
      default:
        return period;
    }
  }

  static Future<String> _savePdf(pw.Document pdf, String filename) async {
    try {
      final pdfBytes = await pdf.save();
      if (kIsWeb) {
        _downloadFileWeb('$filename.pdf', pdfBytes);
        return '$filename.pdf';
      } else {
        final output = await getApplicationDocumentsDirectory();
        final file = io.File('${output.path}/$filename.pdf');
        await file.writeAsBytes(pdfBytes);
        await OpenFilex.open(file.path);
        return file.path;
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<String> generateOrderPdf({
    required Map<String, dynamic> order,
  }) async {
    final pdf = pw.Document();
    
    // Datos de la orden
    final orderId = order['_id']?.toString() ?? 'N/A';
    final shortId = orderId.length > 8 ? orderId.substring(orderId.length - 8) : orderId;
    final customerData = order['customerId'];
    final customerName = customerData is Map ? (customerData['name'] ?? 'Sin nombre') : 'Sin cliente';
    final customerPhone = customerData is Map ? (customerData['phone'] ?? '') : '';
    final paymentMethod = order['paymentMethod'] as String? ?? 'efectivo';
    final totalOrden = (order['totalOrden'] as num? ?? 0).toDouble();
    final items = order['items'] as List? ?? [];
    final orderDate = order['orderDate'] ?? order['createdAt'];
    
      String getPaymentMethodText(String method) {
      switch (method.toLowerCase()) {
        case 'efectivo':
          return 'Efectivo';
        case 'tarjeta':
          return 'Tarjeta';
        case 'transferencia':
          return 'Transferencia';
        default:
          return method;
      }
    }
    
    String formatDate(dynamic date) {
      if (date == null) return 'N/A';
      try {
        final dateTime = date is DateTime ? date : DateTime.parse(date.toString());
        final localDateTime = dateTime.toLocal();
        return DateFormat('dd/MM/yyyy HH:mm').format(localDateTime);
      } catch (e) {
        return 'N/A';
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Encabezado
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(
                        'BELLEZAPP',
                        style: pw.TextStyle(
                          fontSize: 24,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Sistema de Gestión de Belleza',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'ORDEN #$shortId',
                        style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                      pw.Text(
                        'Fecha: ${formatDate(orderDate)}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 30),

              // Línea divisoria
              pw.Divider(),
              pw.SizedBox(height: 20),

              // Información del Cliente
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'INFORMACIÓN DEL CLIENTE',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Text('Nombre: $customerName'),
                  if (customerPhone.isNotEmpty)
                    pw.Text('Teléfono: $customerPhone'),
                ],
              ),
              pw.SizedBox(height: 20),

              // Línea divisoria
              pw.Divider(),
              pw.SizedBox(height: 20),

              // Tabla de productos
              pw.Text(
                'DETALLE DE PRODUCTOS',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 10),

              if (items.isEmpty)
                pw.Text('Sin productos en esta orden')
              else
                pw.Table(
                  border: pw.TableBorder.all(),
                  columnWidths: {
                    0: const pw.FlexColumnWidth(3),
                    1: const pw.FlexColumnWidth(1),
                    2: const pw.FlexColumnWidth(1),
                    3: const pw.FlexColumnWidth(1),
                  },
                  children: [
                    // Encabezado de tabla
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey300,
                      ),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Producto',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Precio',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Cantidad',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.center,
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(8),
                          child: pw.Text(
                            'Subtotal',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                            textAlign: pw.TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                    // Filas de productos
                    ...items.map((item) {
                      final product = item['productId'];
                      final productName = product is Map
                          ? (product['name'] ?? 'Producto')
                          : 'Producto';
                      final price = (item['price'] as num? ?? 0).toDouble();
                      final quantity = (item['quantity'] as num? ?? 0).toInt();
                      final subtotal = price * quantity;

                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(productName),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              '\$${price.toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              quantity.toString(),
                              textAlign: pw.TextAlign.center,
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8),
                            child: pw.Text(
                              '\$${subtotal.toStringAsFixed(2)}',
                              textAlign: pw.TextAlign.right,
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),

              pw.SizedBox(height: 20),

              // Resumen financiero
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                          'Método de pago: ${getPaymentMethodText(paymentMethod)}',
                        style: const pw.TextStyle(fontSize: 10),
                      ),
                      pw.SizedBox(height: 10),
                      pw.Row(
                        children: [
                          pw.Text(
                            'TOTAL: ',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.Text(
                            '\$${totalOrden.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              pw.Spacer(),

              // Pie de página
              pw.Divider(),
              pw.Text(
                'Gracias por tu compra en BellezApp',
                style: const pw.TextStyle(
                  fontSize: 10,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ],
          );
        },
      ),
    );

    return await _savePdf(pdf, 'Orden_$shortId');
  }

  static Future<String> generateProductQrLabels({
    required Map<String, dynamic> product,
  }) async {
    final pdf = pw.Document();
    
    final productId = product['_id']?.toString() ?? 'N/A';
    final productName = product['name']?.toString() ?? 'Producto';
    
    // 2x2 cm = aproximadamente 56.7 puntos (72 DPI)
    const qrSize = 56.7;
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(10),
        build: (pw.Context context) {
          return pw.Column(
            children: [
              pw.Text(
                'Códigos QR para Imprimir',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                productName,
                style: const pw.TextStyle(fontSize: 10),
              ),
              pw.SizedBox(height: 10),
              
              // Grid de 5 columnas x 2 filas = 10 QRs
              pw.Wrap(
                spacing: 5,
                runSpacing: 5,
                children: List.generate(10, (index) {
                  return pw.Container(
                    width: qrSize,
                    height: qrSize,
                    padding: const pw.EdgeInsets.all(2),
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(),
                    ),
                    child: pw.BarcodeWidget(
                      barcode: pw.Barcode.qrCode(),
                      data: productId,
                      width: qrSize - 4,
                      height: qrSize - 4,
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );

    return await _savePdf(pdf, 'QR_${productName.replaceAll(' ', '_')}');
  }

  static void _downloadFileWeb(String filename, List<int> bytes) {
    // Convert List<int> to Uint8List and then to JS for Blob
    final uint8List = Uint8List.fromList(bytes);
    final jsUint8Array = uint8List.toJS;
    final blob = web.Blob([jsUint8Array].toJS);
    final url = web.URL.createObjectURL(blob);
    final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
    anchor.href = url;
    anchor.setAttribute('download', filename);
    anchor.click();
    web.URL.revokeObjectURL(url);
  }
}

