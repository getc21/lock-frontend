import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/dashboard_layout.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/providers/riverpod/order_notifier.dart';
import '../../../shared/providers/riverpod/product_notifier.dart';
import '../models/return_models.dart';
import '../services/returns_service.dart';

class CreateReturnPage extends ConsumerStatefulWidget {
  final String orderId;
  final String? customerName;

  const CreateReturnPage({
    required this.orderId,
    this.customerName,
    super.key,
  });

  @override
  ConsumerState<CreateReturnPage> createState() => _CreateReturnPageState();
}

class _CreateReturnPageState extends ConsumerState<CreateReturnPage> {
  late final TextEditingController reasonDetailsController;
  late final TextEditingController notesController;
  
  ReturnType selectedType = ReturnType.return_;
  ReturnReasonCategory selectedReason = ReturnReasonCategory.defective;
  RefundMethod selectedRefundMethod = RefundMethod.efectivo;
  String selectedReturnReason = 'Defecto de fabricación'; // Reason for each item
  final Map<int, int> selectedItemQuantities = {}; // index -> quantity
  Map<String, dynamic>? orderData;

  @override
  void initState() {
    super.initState();
    reasonDetailsController = TextEditingController();
    notesController = TextEditingController();
    
    // Cargar datos de la orden
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrderData();
    });
  }

  Future<void> _loadOrderData() async {
    // Buscar la orden en el estado global de órdenes
    final orderState = ref.read(orderProvider);
    final order = orderState.orders.where((o) => o['_id'] == widget.orderId).firstOrNull;
    
    if (order != null) {
      setState(() {
        orderData = order;
        // Inicializar cantidades en 0 (no seleccionadas)
        final items = order['items'] as List? ?? [];
        for (int i = 0; i < items.length; i++) {
          selectedItemQuantities[i] = 0;
        }
      });
    }
  }

  @override
  void dispose() {
    reasonDetailsController.dispose();
    notesController.dispose();
    super.dispose();
  }

  List<ReturnItem> _getSelectedItems() {
    if (orderData == null) return [];
    
    final items = orderData?['items'] as List? ?? [];
    final selectedItems = <ReturnItem>[];
    
    selectedItemQuantities.forEach((index, quantity) {
      if (quantity > 0 && index < items.length) {
        final item = items[index];
        
        // Extract productId - handle both string and object formats
        final productIdValue = item['productId'];
        final productId = productIdValue is Map 
            ? (productIdValue['_id']?.toString() ?? '')
            : (productIdValue?.toString() ?? '');
        
        final originalQuantity = item['quantity'] as int? ?? 0;
        
        selectedItems.add(
          ReturnItem(
            productId: productId,
            originalQuantity: originalQuantity,
            returnQuantity: quantity,
            unitPrice: (item['price'] as num?)?.toDouble() ?? 0,
            returnReason: selectedReturnReason,
          ),
        );
      }
    });
    
    return selectedItems;
  }

  double get totalRefund {
    return _getSelectedItems().fold(
      0.0,
      (sum, item) => sum + (item.returnQuantity * item.unitPrice),
    );
  }

  void _submitForm() async {
    final selectedItems = _getSelectedItems();
    
    if (selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona al menos un artículo para devolver'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final storeIdValue = orderData?['storeId'];
    final storeId = storeIdValue is Map 
        ? (storeIdValue['_id']?.toString() ?? '')
        : (storeIdValue?.toString() ?? '');
    
    // Si no hay detalles, usar un valor por defecto basado en la categoría
    final reasonDetails = reasonDetailsController.text.trim().isNotEmpty
        ? reasonDetailsController.text.trim()
        : selectedReason.label;
    
    final createReturnNotifier = ref.read(createReturnProvider.notifier);
    
    try {
      await createReturnNotifier.createReturn(
        orderId: widget.orderId,
        type: selectedType,
        items: selectedItems,
        refundMethod: selectedRefundMethod,
        reasonCategory: selectedReason,
        reasonDetails: reasonDetails,
        notes: notesController.text.isNotEmpty 
            ? notesController.text
            : null,
        storeId: storeId,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Solicitud de devolución creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Actualizar estado local INMEDIATAMENTE
        ref.read(orderProvider.notifier).updateOrderAfterReturn(
          orderId: widget.orderId,
          returnedItems: selectedItems,
        );
        
        // IMPORTANTE: Limpiar completamente el caché y estado de productos
        // Esto asegura que cuando el usuario vuelva a productos, se recargue desde servidor
        ref.read(productProvider.notifier).clearProducts();
        
        // CRITICAL: Invalidar el provider de devoluciones para que se recargue la lista
        // Esto asegura que la nueva devolución aparezca en la página de devoluciones
        ref.invalidate(returnsProvider);
        
        // Recargar desde servidor en background
        Future.microtask(() {
          ref.read(orderProvider.notifier).loadOrdersForCurrentStore(forceRefresh: true);
        });
        
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si orderData no está inicializado aún, mostrar cargando
    if (orderData == null) {
      return DashboardLayout(
        title: 'Nueva Devolución',
        currentRoute: '/returns/create/${widget.orderId}',
        child: const Center(
          child: LoadingIndicator(message: 'Cargando orden...'),
        ),
      );
    }

    final items = orderData?['items'] as List? ?? [];
    final customerName = widget.customerName ?? 'Cliente desconocido';
    final shortOrderId = widget.orderId.length > 8 
        ? widget.orderId.substring(widget.orderId.length - 8) 
        : widget.orderId;

    return DashboardLayout(
      title: 'Nueva Devolución',
      currentRoute: '/returns/create/${widget.orderId}',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información de la orden
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Información de la Orden',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Text('Orden: #$shortOrderId', style: const TextStyle(fontSize: 14)),
                    Text('Cliente: $customerName', style: const TextStyle(fontSize: 14)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Seleccionar artículos
            const Text(
              'Artículos a Devolver',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            if (items.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No hay artículos en esta orden'),
              )
            else
              Column(
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final product = item['productId'];
                  final productName = product is Map ? (product['name'] ?? 'Producto') : 'Producto';
                  final price = (item['price'] as num?)?.toDouble() ?? 0;
                  final originalQuantity = item['quantity'] as int? ?? 0;
                  final selectedQty = selectedItemQuantities[index] ?? 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  productName,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  'Precio unitario: \$${price.toStringAsFixed(2)}',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                                Text(
                                  'Disponible: $originalQuantity unidades',
                                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            width: 120,
                            child: Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: selectedQty > 0
                                      ? () {
                                          setState(() {
                                            selectedItemQuantities[index] = selectedQty - 1;
                                          });
                                        }
                                      : null,
                                ),
                                SizedBox(
                                  width: 40,
                                  child: Text(
                                    selectedQty.toString(),
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline),
                                  onPressed: selectedQty < originalQuantity
                                      ? () {
                                          setState(() {
                                            selectedItemQuantities[index] = selectedQty + 1;
                                          });
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            const SizedBox(height: 24),

            // Tipo de devolución
            const Text(
              'Tipo de Devolución',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ReturnType>(
              initialValue: selectedType,
              items: ReturnType.values
                  .map((type) => DropdownMenuItem(value: type, child: Text(type.label)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => selectedType = value);
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),

            // Razón de devolución
            const Text(
              'Razón de Devolución',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<ReturnReasonCategory>(
              initialValue: selectedReason,
              items: ReturnReasonCategory.values
                  .map((reason) => DropdownMenuItem(value: reason, child: Text(reason.label)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => selectedReason = value);
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonDetailsController,
              decoration: const InputDecoration(
                labelText: 'Detalles de la razón (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // Método de reembolso
            const Text(
              'Método de Reembolso',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<RefundMethod>(
              initialValue: selectedRefundMethod,
              items: RefundMethod.values
                  .map((method) => DropdownMenuItem(value: method, child: Text(method.label)))
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => selectedRefundMethod = value);
              },
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            // Total de reembolso
            Card(
              color: Colors.blue.withValues(alpha: 0.1),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Monto Total de Reembolso',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      '\$${totalRefund.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Notas
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notas adicionales (opcional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _getSelectedItems().isEmpty ? null : _submitForm,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Crear Devolución'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
