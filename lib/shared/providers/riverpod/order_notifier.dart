import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../order_provider.dart' as order_api;
import 'auth_notifier.dart';
import 'store_notifier.dart';

// Estado de órdenes
class OrderState {
  final List<Map<String, dynamic>> orders;
  final bool isLoading;
  final String errorMessage;

  OrderState({
    this.orders = const [],
    this.isLoading = false,
    this.errorMessage = '',
  });

  OrderState copyWith({
    List<Map<String, dynamic>>? orders,
    bool? isLoading,
    String? errorMessage,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Notifier para órdenes
class OrderNotifier extends StateNotifier<OrderState> {
  final Ref ref;

  OrderNotifier(this.ref) : super(OrderState());

  late order_api.OrderProvider _orderProvider;

  // Inicializar el provider con el token del auth
  void _initOrderProvider() {
    final authState = ref.read(authProvider);
    _orderProvider = order_api.OrderProvider(authState.token);
  }

  // Cargar órdenes
  Future<void> loadOrders({
    String? storeId,
    String? customerId,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    _initOrderProvider();

    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      // Usar storeId proporcionado o obtener del state actual
      final effectiveStoreId = storeId ?? ref.read(storeProvider).currentStore?['_id'];

      if (effectiveStoreId == null) {
        state = state.copyWith(orders: [], isLoading: false);
        return;
      }

      if (kDebugMode) {
        print('=== OrderNotifier: loadOrders ===');
        print('effectiveStoreId: $effectiveStoreId');
      }

      final result = await _orderProvider.getOrders(
        storeId: effectiveStoreId,
        customerId: customerId,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );

      if (result['success']) {
        final orders = List<Map<String, dynamic>>.from(result['data']);
        state = state.copyWith(orders: orders);
      } else {
        state = state.copyWith(
          errorMessage: result['message'] ?? 'Error cargando órdenes',
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error de conexión: $e',
      );
    }
    
    state = state.copyWith(isLoading: false);
  }

  // Cargar órdenes de la tienda actual
  Future<void> loadOrdersForCurrentStore() async {
    _initOrderProvider();
    final storeState = ref.read(storeProvider);

    if (storeState.currentStore != null) {
      await loadOrders(storeId: storeState.currentStore!['_id']);
    } else {
      state = state.copyWith(orders: []);
    }
  }

  // Obtener orden por ID
  Future<Map<String, dynamic>?> getOrderById(String id) async {
    _initOrderProvider();
    state = state.copyWith(isLoading: true);

    try {
      final result = await _orderProvider.getOrderById(id);

      if (result['success']) {
        state = state.copyWith(isLoading: false);
        return result['data'];
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error obteniendo orden',
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error de conexión: $e',
      );
      return null;
    }
  }

  // Crear orden
  Future<bool> createOrder({
    required String storeId,
    String? customerId,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    String? cashRegisterId,
    String? discountId,
  }) async {
    _initOrderProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _orderProvider.createOrder(
        storeId: storeId,
        customerId: customerId,
        items: items,
        paymentMethod: paymentMethod,
        cashRegisterId: cashRegisterId,
        discountId: discountId,
      );

      if (result['success']) {
        // Refrescar lista de órdenes
        await loadOrders(storeId: storeId);
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error creando orden',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error de conexión: $e',
      );
      return false;
    }
  }

  // Actualizar estado de orden
  Future<bool> updateOrderStatus({
    required String id,
    required String status,
  }) async {
    _initOrderProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _orderProvider.updateOrderStatus(
        id: id,
        status: status,
      );

      if (result['success']) {
        await loadOrdersForCurrentStore();
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error actualizando estado',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error de conexión: $e',
      );
      return false;
    }
  }

  // Obtener reporte de ventas
  Future<Map<String, dynamic>?> getSalesReport({
    String? storeId,
    String? startDate,
    String? endDate,
    String? groupBy,
  }) async {
    _initOrderProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _orderProvider.getSalesReport(
        storeId: storeId,
        startDate: startDate,
        endDate: endDate,
        groupBy: groupBy,
      );

      if (result['success']) {
        state = state.copyWith(isLoading: false);
        return result['data'];
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error obteniendo reporte',
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error de conexión: $e',
      );
      return null;
    }
  }

  // Eliminar orden
  Future<bool> deleteOrder(String id) async {
    _initOrderProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _orderProvider.deleteOrder(id);

      if (result['success']) {
        state = state.copyWith(
          orders: state.orders.where((o) => o['_id'] != id).toList(),
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error eliminando orden',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error de conexión: $e',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: '');
  }

  void clearOrders() {
    state = OrderState();
  }
}

// Provider
final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  return OrderNotifier(ref);
});
