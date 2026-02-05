
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/dashboard_layout.dart';
import '../../../shared/providers/riverpod/store_notifier.dart';
import '../models/return_models.dart';
import '../services/returns_service.dart';

class ReturnsListPage extends ConsumerWidget {
  const ReturnsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Obtener la tienda actual directamente
    final storeState = ref.watch(storeProvider);
    final currentStoreId = storeState.currentStore?['_id'] as String?;

    // DEBUG: Mostrar el storeId
    debugPrint('ReturnsListPage - currentStoreId: $currentStoreId');

    if (currentStoreId == null) {
      return DashboardLayout(
        title: 'Devoluciones',
        currentRoute: '/returns',
        child: const Center(
          child: Text('No hay tienda seleccionada'),
        ),
      );
    }

    final returnsAsync = ref.watch(
      returnsProvider(ReturnFilters(storeId: currentStoreId)),
    );

    return DashboardLayout(
      title: 'Devoluciones',
      currentRoute: '/returns',
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            returnsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
              error: (error, stack) {
                debugPrint('ReturnsListPage Error: $error');
                debugPrint('Stack: $stack');
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 20),
                      const Text('Error al cargar devoluciones', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text('Error: $error'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {
                          // ignore: unused_result
                          ref.refresh(returnsProvider(ReturnFilters(storeId: currentStoreId)));
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                );
              },
              data: (data) {
                final returns = data['returns'] as List<ReturnRequest>;
                final summary = data['summary'];

                if (returns.isEmpty) {
                  return SizedBox(
                    height: 600,
                    child: Card(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.receipt_long_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No hay devoluciones registradas',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Las devoluciones que crees aparecerán aquí',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Resumen simplificado
                      Row(
                        children: [
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Total de Devoluciones',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      summary['total'].toString(),
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    const Text(
                                      'Total Dinero Devuelto',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '\$${returns.fold<double>(0.0, (sum, item) => sum + item.totalRefundAmount).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Lista de devoluciones
                      const Text(
                        'Devoluciones Registradas',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      ...returns.map(
                        (returnRequest) => ReturnRequestCard(returnRequest: returnRequest),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class ReturnRequestCard extends StatelessWidget {
  final ReturnRequest returnRequest;
  const ReturnRequestCard({required this.returnRequest, super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Monto destacado con color
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monto de Reembolso',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${returnRequest.totalRefundAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
          ),
          // Detalles principales
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Orden y Cliente
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Orden: ${returnRequest.orderNumber}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cliente: ${returnRequest.customerName}',
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Tipo y Razón
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Tipo',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          returnRequest.type.label,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Razón',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          returnRequest.returnReasonCategory.label,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Método',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          returnRequest.refundMethod.label,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Artículos
                Text(
                  'Artículos (${returnRequest.items.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                ...returnRequest.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      '• ${item.productName ?? 'Producto'} x${item.returnQuantity} @ \$${item.unitPrice}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
