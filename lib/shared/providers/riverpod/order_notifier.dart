import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../order_provider.dart' as order_api;
import 'auth_notifier.dart';
import 'store_notifier.dart';
import '../../services/cache_service.dart';

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
  final CacheService _cache = CacheService();

  OrderNotifier(this.ref) : super(OrderState());

  late order_api.OrderProvider _orderProvider;

  // Inicializar el provider con el token del auth
  void _initOrderProvider() {
    final authState = ref.read(authProvider);
    _orderProvider = order_api.OrderProvider(authState.token);
  }

  /// Genera una clave de caché para órdenes basada en los parámetros
  String _getCacheKey({
    String? storeId,
    String? customerId,
    String? status,
    String? startDate,
    String? endDate,
  }) {
    return 'orders:$storeId:$customerId:$status:$startDate:$endDate';
  }

  // Cargar órdenes con soporte para caché
  Future<void> loadOrders({
    String? storeId,
    String? customerId,
    String? status,
    String? startDate,
    String? endDate,
    bool forceRefresh = false,
  }) async {
    _initOrderProvider();

    try {
      // Usar storeId proporcionado o obtener del state actual
      final effectiveStoreId = storeId ?? ref.read(storeProvider).currentStore?['_id'];

      if (effectiveStoreId == null) {
        state = state.copyWith(orders: [], isLoading: false);
        return;
      }

      if (kDebugMode) {


      }

      final cacheKey = _getCacheKey(
        storeId: effectiveStoreId,
        customerId: customerId,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );

      // SIEMPRE intentar obtener del caché primero (incluso si forceRefresh)
      final cachedOrders = _cache.get<List<Map<String, dynamic>>>(cacheKey);
      if (cachedOrders != null && !forceRefresh) {
        // Mostrar datos en caché inmediatamente SIN loading
        state = state.copyWith(orders: cachedOrders, isLoading: false, errorMessage: '');
        return;
      } else if (cachedOrders == null) {
        // Si no hay caché, mostrar loading
        state = state.copyWith(isLoading: true, errorMessage: '');
      }
      // Si forceRefresh=true, continuar sin cambiar isLoading (mantendrá el estado anterior)

      final result = await _orderProvider.getOrders(
        storeId: effectiveStoreId,
        customerId: customerId,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );

      if (result['success']) {
        final orders = List<Map<String, dynamic>>.from(result['data']);
        // Almacenar en caché con 10 minutos de TTL
        _cache.set(
          cacheKey,
          orders,
          ttl: const Duration(minutes: 10),
        );
        state = state.copyWith(orders: orders, isLoading: false);
      } else {
        state = state.copyWith(
          errorMessage: result['message'] ?? 'Error cargando órdenes',
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error de conexión: $e',
        isLoading: false,
      );
    }
  }

  // Cargar órdenes de la tienda actual
  Future<void> loadOrdersForCurrentStore({bool forceRefresh = false}) async {
    _initOrderProvider();
    final storeState = ref.read(storeProvider);

    if (storeState.currentStore != null) {
      await loadOrders(
        storeId: storeState.currentStore!['_id'],
        forceRefresh: forceRefresh,
      );
    } else {
      state = state.copyWith(orders: []);
    }
  }

  // Obtener orden por ID con caché
  Future<Map<String, dynamic>?> getOrderById(String id) async {
    _initOrderProvider();
    
    final cacheKey = 'order:$id';
    final cached = _cache.get<Map<String, dynamic>>(cacheKey);
    if (cached != null) {
      return cached;
    }

    state = state.copyWith(isLoading: true);

    try {
      final result = await _orderProvider.getOrderById(id);

      if (result['success']) {
        final order = result['data'] as Map<String, dynamic>;
        _cache.set(cacheKey, order, ttl: const Duration(minutes: 10));
        state = state.copyWith(isLoading: false);
        return order;
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
        // Invalidar caché de órdenes después de crear una nueva
        _cache.invalidatePattern('orders:$storeId');
        
        // IMPORTANTE: Invalidar caché de productos para forzar recarga del stock
        _cache.invalidatePattern('products:$storeId');
        
        // Refrescar lista de órdenes
        await loadOrders(storeId: storeId, forceRefresh: true);
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
        // Invalidar caché de orden actualizado
        _cache.invalidate('order:$id');
        _cache.invalidatePattern('orders:');
        await loadOrdersForCurrentStore(forceRefresh: true);
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

  // Obtener reporte de ventas con caché
  Future<Map<String, dynamic>?> getSalesReport({
    String? storeId,
    String? startDate,
    String? endDate,
    String? groupBy,
  }) async {
    _initOrderProvider();
    
    final cacheKey = 'report:sales:$storeId:$startDate:$endDate:$groupBy';
    final cached = _cache.get<Map<String, dynamic>>(cacheKey);
    if (cached != null) {
      return cached;
    }

    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _orderProvider.getSalesReport(
        storeId: storeId,
        startDate: startDate,
        endDate: endDate,
        groupBy: groupBy,
      );

      if (result['success']) {
        final report = result['data'] as Map<String, dynamic>;
        _cache.set(cacheKey, report, ttl: const Duration(minutes: 15));
        state = state.copyWith(isLoading: false);
        return report;
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
        // Invalidar cachés relacionados
        _cache.invalidate('order:$id');
        _cache.invalidatePattern('orders:');
        _cache.invalidatePattern('report:');
        
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

  /// Actualizar orden cuando se procesa una devolución
  /// Reduce las cantidades de los items devueltos y recalcula el total
  void updateOrderAfterReturn({
    required String orderId,
    required List<dynamic> returnedItems,
  }) {
    final updatedOrders = state.orders.map((order) {
      if (order['_id'] != orderId) return order;

      // Crear una copia de la orden
      final updatedOrder = Map<String, dynamic>.from(order);
      final items = List<Map<String, dynamic>>.from(order['items'] ?? []);

      // Reducir cantidades de items devueltos
      for (final returnedItem in returnedItems) {
        // Extraer productId (puede ser string o Map)
        String itemProductId = '';
        final pId = returnedItem.productId ?? returnedItem['productId'];
        
        if (pId is Map) {
          itemProductId = (pId['_id'] ?? pId['id'])?.toString() ?? '';
        } else {
          itemProductId = pId?.toString() ?? '';
        }

        final itemIndex = items.indexWhere(
          (item) => item['productId'].toString() == itemProductId,
        );

        if (itemIndex >= 0) {
          final item = Map<String, dynamic>.from(items[itemIndex]);
          final currentQty = (item['quantity'] as num?)?.toInt() ?? 0;
          final returnQty = (returnedItem.returnQuantity ?? returnedItem['returnQuantity'] ?? 0) as num;

          item['quantity'] = currentQty - returnQty.toInt();

          if (item['quantity'] <= 0) {
            items.removeAt(itemIndex);
          } else {
            items[itemIndex] = item;
          }
        }
      }

      // Recalcular total
      double newTotal = 0;
      for (final item in items) {
        final price = (item['price'] as num?)?.toDouble() ?? 0;
        final qty = (item['quantity'] as num?)?.toDouble() ?? 0;
        newTotal += price * qty;
      }

      updatedOrder['items'] = items;
      updatedOrder['totalOrden'] = newTotal;

      return updatedOrder;
    }).toList();

    state = state.copyWith(orders: updatedOrders);
  }
}

// Provider
final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>((ref) {
  return OrderNotifier(ref);
});

