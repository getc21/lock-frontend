import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/riverpod/order_detail_notifier.dart';
import '../providers/riverpod/product_detail_notifier.dart';
import '../providers/riverpod/customer_detail_notifier.dart';

/// Placeholder para LoadingWidget - Usar tu loading widget actual
class LoadingWidget extends StatelessWidget {
  const LoadingWidget();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

/// EJEMPLO 1: Página de Detalle de Orden usando .family
class OrderDetailPageExample extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailPageExample({required this.orderId});

  @override
  ConsumerState<OrderDetailPageExample> createState() =>
      _OrderDetailPageExampleState();
}

class _OrderDetailPageExampleState extends ConsumerState<OrderDetailPageExample> {
  @override
  void initState() {
    super.initState();
    // Cargar el detalle cuando entra a la página
    Future.microtask(() {
      ref.read(orderDetailProvider(widget.orderId).notifier)
          .loadOrderDetail();
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ CLAVE: Observa solo este orden específico (lazy loading)
    final orderDetailState = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Orden')),
      body: orderDetailState.isLoading
          ? const LoadingWidget()
          : orderDetailState.error != null
              ? ErrorWidget(error: orderDetailState.error!)
              : orderDetailState.order != null
                  ? OrderDetailContent(
                      order: orderDetailState.order!,
                      onStatusChange: (newStatus) async {
                        final success = await ref
                            .read(
                                orderDetailProvider(widget.orderId).notifier)
                            .updateOrderStatus(status: newStatus);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Estado actualizado'),
                            ),
                          );
                        }
                      },
                    )
                  : const SizedBox.shrink(),
    );
  }
}

/// EJEMPLO 2: Página de Detalle de Producto usando .family
class ProductDetailPageExample extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailPageExample({required this.productId});

  @override
  ConsumerState<ProductDetailPageExample> createState() =>
      _ProductDetailPageExampleState();
}

class _ProductDetailPageExampleState
    extends ConsumerState<ProductDetailPageExample> {
  @override
  void initState() {
    super.initState();
    // Cargar el detalle cuando entra a la página
    Future.microtask(() {
      ref.read(productDetailProvider(widget.productId).notifier)
          .loadProductDetail();
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ CLAVE: Observa solo este producto específico (lazy loading)
    final productDetailState =
        ref.watch(productDetailProvider(widget.productId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Producto')),
      body: productDetailState.isLoading
          ? const LoadingWidget()
          : productDetailState.error != null
              ? ErrorWidget(error: productDetailState.error!)
              : productDetailState.product != null
                  ? ProductDetailContent(
                      product: productDetailState.product!,
                      onPriceChange: (newPrice) async {
                        final success = await ref
                            .read(
                                productDetailProvider(widget.productId)
                                    .notifier)
                            .updatePrice(newPrice: newPrice);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Precio actualizado'),
                            ),
                          );
                        }
                      },
                      onStockChange: (newStock) async {
                        final success = await ref
                            .read(
                                productDetailProvider(widget.productId)
                                    .notifier)
                            .updateStock(newStock: newStock);
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Stock actualizado'),
                            ),
                          );
                        }
                      },
                    )
                  : const SizedBox.shrink(),
    );
  }
}

/// EJEMPLO 3: Página de Detalle de Cliente usando .family
class CustomerDetailPageExample extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerDetailPageExample({required this.customerId});

  @override
  ConsumerState<CustomerDetailPageExample> createState() =>
      _CustomerDetailPageExampleState();
}

class _CustomerDetailPageExampleState
    extends ConsumerState<CustomerDetailPageExample> {
  @override
  void initState() {
    super.initState();
    // Cargar el detalle cuando entra a la página
    Future.microtask(() {
      ref.read(customerDetailProvider(widget.customerId).notifier)
          .loadCustomerDetail();
    });
  }

  @override
  Widget build(BuildContext context) {
    // ✅ CLAVE: Observa solo este cliente específico (lazy loading)
    final customerDetailState =
        ref.watch(customerDetailProvider(widget.customerId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Cliente')),
      body: customerDetailState.isLoading
          ? const LoadingWidget()
          : customerDetailState.error != null
              ? ErrorWidget(error: customerDetailState.error!)
              : customerDetailState.customer != null
                  ? CustomerDetailContent(
                      customer: customerDetailState.customer!,
                      onInfoChange: (name, email, phone, address) async {
                        final success = await ref
                            .read(customerDetailProvider(widget.customerId)
                                .notifier)
                            .updateCustomerInfo(
                              name: name,
                              email: email,
                              phone: phone,
                              address: address,
                            );
                        if (success && mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cliente actualizado'),
                            ),
                          );
                        }
                      },
                    )
                  : const SizedBox.shrink(),
    );
  }
}

// ============================================================================
// WIDGETS DE CONTENIDO (Placeholders - Implementar según tu diseño)
// ============================================================================

class OrderDetailContent extends StatelessWidget {
  final Map<String, dynamic> order;
  final Function(String) onStatusChange;

  const OrderDetailContent({
    required this.order,
    required this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ID: ${order['_id']}'),
          Text('Total: \$${order['total']}'),
          Text('Estado: ${order['status']}'),
          // Implementar botones para cambiar estado
        ],
      ),
    );
  }
}

class ProductDetailContent extends StatelessWidget {
  final Map<String, dynamic> product;
  final Function(double) onPriceChange;
  final Function(int) onStockChange;

  const ProductDetailContent({
    required this.product,
    required this.onPriceChange,
    required this.onStockChange,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nombre: ${product['name']}'),
          Text('Precio: \$${product['price']}'),
          Text('Stock: ${product['stock']}'),
          // Implementar campos para editar precio y stock
        ],
      ),
    );
  }
}

class CustomerDetailContent extends StatelessWidget {
  final Map<String, dynamic> customer;
  final Function(String, String?, String?, String?) onInfoChange;

  const CustomerDetailContent({
    required this.customer,
    required this.onInfoChange,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Nombre: ${customer['name']}'),
          Text('Email: ${customer['email'] ?? 'N/A'}'),
          Text('Teléfono: ${customer['phone'] ?? 'N/A'}'),
          Text('Dirección: ${customer['address'] ?? 'N/A'}'),
          // Implementar campos para editar información
        ],
      ),
    );
  }
}

class ErrorWidget extends StatelessWidget {
  final String error;

  const ErrorWidget({required this.error});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(error, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ============================================================================
// COMPARACIÓN: USO EN TABLAS (Antes vs Después)
// ============================================================================

/// ✅ DESPUÉS: Cargar tabla sin detalles, detalles bajo demanda
class OrdersTableAfter extends ConsumerStatefulWidget {
  const OrdersTableAfter();

  @override
  ConsumerState<OrdersTableAfter> createState() => _OrdersTableAfterState();
}

class _OrdersTableAfterState extends ConsumerState<OrdersTableAfter> {
  @override
  Widget build(BuildContext context) {
    // Observar SOLO la lista (sin detalles)
    // final orders = ref.watch(orderProvider.select((s) => s.orders));

    return ListView.builder(
      itemCount: 5, // Placeholder
      itemBuilder: (context, index) {
        final order = {'_id': 'order_$index', 'total': 100};
        return ListTile(
          title: Text('Orden ${order['_id']}'),
          subtitle: Text('Total: \$${order['total']}'),
          onTap: () {
            // Navegar a detalle - carga SOLO este orden (lazy loading)
            // Navigator.push(context, MaterialPageRoute(
            //   builder: (_) => OrderDetailPageExample(
            //     orderId: order['_id'],
            //   ),
            // ));
          },
        );
      },
    );
  }
}
