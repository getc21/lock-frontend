import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/providers/riverpod/receipt_notifier.dart';
import '../../shared/providers/riverpod/store_notifier.dart';
import '../../shared/widgets/dashboard_layout.dart';

class ReceiptsPage extends ConsumerStatefulWidget {
  const ReceiptsPage({super.key});

  @override
  ConsumerState<ReceiptsPage> createState() => _ReceiptsPageState();
}

class _ReceiptsPageState extends ConsumerState<ReceiptsPage> {
  final TextEditingController _searchController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  late DateFormat _dateFormat;

  @override
  void initState() {
    super.initState();
    _dateFormat = DateFormat('dd/MM/yyyy');
    _startDate = DateTime.now().subtract(const Duration(days: 30));
    _endDate = DateTime.now();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Cargar estadísticas y comprobantes cuando se inicializa la página
    final storeState = ref.read(storeProvider);
    if (storeState.currentStore != null) {
      final storeId = storeState.currentStore!['_id'] as String;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(receiptProvider.notifier).getReceiptStatistics(storeId);
        _loadReceiptsByDateRange();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: _startDate ?? DateTime.now().subtract(const Duration(days: 30)),
        end: _endDate ?? DateTime.now(),
      ),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });

      // Recargar comprobantes con nuevas fechas
      _loadReceiptsByDateRange();
    }
  }

  Future<void> _loadReceiptsByDateRange() async {
    final storeState = ref.read(storeProvider);
    if (storeState.currentStore == null) return;

    final storeId = storeState.currentStore!['_id'] as String;
    final startDate = DateFormat('yyyy-MM-dd').format(_startDate ?? DateTime.now());
    final endDate = DateFormat('yyyy-MM-dd').format(_endDate ?? DateTime.now());

    await ref.read(receiptProvider.notifier).getReceiptsByDateRange(
      storeId: storeId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  Future<void> _refreshStatistics() async {
    final storeState = ref.read(storeProvider);
    if (storeState.currentStore == null) return;

    final storeId = storeState.currentStore!['_id'] as String;
    await ref.read(receiptProvider.notifier).getReceiptStatistics(storeId);
    await _loadReceiptsByDateRange();
  }

  Future<void> _searchReceipt(String receiptNumber) async {
    if (receiptNumber.isEmpty) return;

    final storeState = ref.read(storeProvider);
    if (storeState.currentStore == null) return;

    final storeId = storeState.currentStore!['_id'] as String;
    await ref.read(receiptProvider.notifier).getReceiptByNumber(
      receiptNumber: receiptNumber,
      storeId: storeId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final receiptState = ref.watch(receiptProvider);
    ref.watch(storeProvider);

    return DashboardLayout(
      title: 'Comprobantes',
      currentRoute: '/receipts',
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing8),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            // Encabezado con filtros
            Card(
              elevation: 0,
              color: Colors.grey.shade50,
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Buscar Comprobantes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacing16),
                    Row(
                      children: [
                        // Campo de búsqueda
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Ej: RCP-2026-001-0000001',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {});
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (value) => setState(() {}),
                            onSubmitted: (value) {
                              if (value.isNotEmpty) {
                                _searchReceipt(value);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: AppSizes.spacing12),
                        // Botón buscar
                        ElevatedButton.icon(
                          onPressed: _searchController.text.isEmpty
                              ? null
                              : () => _searchReceipt(_searchController.text),
                          icon: const Icon(Icons.search),
                          label: const Text('Buscar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.spacing16),
                    // Filtro por fechas
                    Row(
                      children: [
                        const Text('Período: '),
                        const SizedBox(width: AppSizes.spacing8),
                        Expanded(
                          child: Text(
                            '${_dateFormat.format(_startDate ?? DateTime.now())} - ${_dateFormat.format(_endDate ?? DateTime.now())}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _selectDateRange,
                          icon: const Icon(Icons.date_range),
                          label: const Text('Cambiar'),
                        ),
                        const SizedBox(width: AppSizes.spacing12),
                        ElevatedButton.icon(
                          onPressed: () {
                            _loadReceiptsByDateRange();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Cargar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spacing20),
            // Estadísticas
            if (receiptState.statistics != null)
              Row(
                children: [
                  Expanded(
                    child: _buildStatisticsSection(receiptState.statistics!),
                  ),
                ],
              )
            else
              Center(
                child: ElevatedButton.icon(
                  onPressed: _refreshStatistics,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Cargar Estadísticas'),
                ),
              ),
            const SizedBox(height: AppSizes.spacing20),
            // Resultados
            SizedBox(
              width: double.infinity,
              child: receiptState.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : receiptState.receipts.isEmpty &&
                          receiptState.selectedReceipt == null
                      ? Center(
                          child: Text(
                            receiptState.errorMessage.isEmpty
                                ? 'No hay comprobantes para mostrar'
                                : receiptState.errorMessage,
                            style: TextStyle(
                              color: receiptState.errorMessage.isEmpty
                                  ? Colors.grey
                                  : Colors.red,
                            ),
                          ),
                        )
                      : SingleChildScrollView(
                          child: Column(
                            children: [
                              if (receiptState.selectedReceipt != null)
                                _buildReceiptDetail(
                                    receiptState.selectedReceipt!),
                              if (receiptState.receipts.isNotEmpty)
                                _buildReceiptsList(receiptState.receipts),
                            ],
                          ),
                        ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildStatisticsSection(Map<String, dynamic> stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Estadísticas de Comprobantes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.spacing16),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.5,
              children: [
                _buildStatCard(
                  'Total Comprobantes',
                  '${stats['totalReceipts'] ?? 0}',
                  Colors.blue,
                ),
                _buildStatCard(
                  'Emitidos',
                  '${stats['issuedCount'] ?? 0}',
                  Colors.green,
                ),
                _buildStatCard(
                  'Cancelados',
                  '${stats['cancelledCount'] ?? 0}',
                  Colors.orange,
                ),
                _buildStatCard(
                  'Monto Total',
                  '\$${(stats['totalAmount'] ?? 0).toStringAsFixed(2)}',
                  AppColors.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptDetail(Map<String, dynamic> receipt) {
    final receiptNumber = receipt['receiptNumber'] as String? ?? 'N/A';
    final amount = receipt['amount'] as num? ?? 0;
    final paymentMethod = receipt['paymentMethod'] as String? ?? 'N/A';
    final statusValue = receipt['status'] as String? ?? 'N/A';
    final issuedAt = receipt['issuedAt'];
    final items = receipt['items'] as List? ?? [];

    // Traducir estado al español
    String getStatusLabel(String status) {
      switch (status) {
        case 'issued':
          return 'Emitido';
        case 'cancelled':
          return 'Cancelado';
        case 'refunded':
          return 'Reembolsado';
        default:
          return status;
      }
    }

    Color getStatusColor(String status) {
      switch (status) {
        case 'issued':
          return Colors.green;
        case 'cancelled':
          return Colors.orange;
        case 'refunded':
          return Colors.blue;
        default:
          return Colors.grey;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Detalles del Comprobante',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    ref.read(receiptProvider.notifier).clearReceipts();
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Comprobante', receiptNumber),
                  const SizedBox(height: 8),
                  _buildDetailRow('Monto', '\$${amount.toStringAsFixed(2)}'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Método Pago', paymentMethod),
                  const SizedBox(height: 8),
                  _buildDetailRow(
                    'Estado',
                    getStatusLabel(statusValue),
                    valueColor: getStatusColor(statusValue),
                  ),
                  if (issuedAt != null) ...[
                    const SizedBox(height: 8),
                    _buildDetailRow(
                      'Fecha Emisión',
                      DateFormat('dd/MM/yyyy HH:mm').format(
                        DateTime.parse(issuedAt.toString()),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (items.isNotEmpty) ...[
              const SizedBox(height: AppSizes.spacing16),
              const Text(
                'Artículos',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...items.map((item) {
                // Obtener nombre del producto con mejor manejo
                String productName = 'Producto';
                final productId = item['productId'];
                if (productId is Map && productId.containsKey('name')) {
                  productName = productId['name'] ?? 'Producto';
                } else if (productId is String) {
                  productName = productId;
                }

                final quantity = item['quantity'] ?? 0;
                final price = item['price'] ?? 0;
                final subtotal = item['subtotal'] ?? 0;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          productName,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text('$quantity x \$$price'),
                      const SizedBox(width: 16),
                      Text('\$$subtotal'),
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptsList(List<Map<String, dynamic>> receipts) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comprobantes encontrados (${receipts.length})',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.spacing12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: receipts.length,
              itemBuilder: (context, index) {
                final receipt = receipts[index];
                final receiptNumber = receipt['receiptNumber'] as String? ?? 'N/A';
                final amount = receipt['amount'] as num? ?? 0;
                final status = receipt['status'] as String? ?? 'N/A';
                final issuedAt = receipt['issuedAt'];

                return ListTile(
                  title: Text(receiptNumber),
                  subtitle: issuedAt != null
                      ? Text(DateFormat('dd/MM/yyyy HH:mm').format(
                          DateTime.parse(issuedAt.toString()),
                        ))
                      : null,
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: status == 'issued'
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status == 'issued' ? 'Emitido' : 'Cancelado',
                          style: TextStyle(
                            fontSize: 12,
                            color: status == 'issued'
                                ? Colors.green
                                : Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    // Mostrar detalles del comprobante
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Detalles del Comprobante'),
                        content: _buildReceiptDetail(receipt),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cerrar'),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value,
      {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        SizedBox(width: 20),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
