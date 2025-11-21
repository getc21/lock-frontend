import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../order_provider.dart' as order_api;
import 'auth_notifier.dart';
import '../../services/cache_service.dart';

/// Estado para un detalle individual de orden
class OrderDetailState {
  final Map<String, dynamic>? order;
  final bool isLoading;
  final String? error;

  const OrderDetailState({
    this.order,
    this.isLoading = false,
    this.error,
  });

  OrderDetailState copyWith({
    Map<String, dynamic>? order,
    bool? isLoading,
    String? error,
  }) =>
      OrderDetailState(
        order: order ?? this.order,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

/// Notifier para un orden específico (lazy loading con .family)
class OrderDetailNotifier extends StateNotifier<OrderDetailState> {
  final Ref ref;
  final String orderId;
  final CacheService _cache = CacheService();
  late order_api.OrderProvider _orderProvider;

  OrderDetailNotifier(this.ref, this.orderId) : super(const OrderDetailState());

  /// Inicializar el provider con el token del auth
  void _initOrderProvider() {
    final authState = ref.read(authProvider);
    _orderProvider = order_api.OrderProvider(authState.token);
  }

  /// Cargar detalle de una orden específica
  Future<void> loadOrderDetail({bool forceRefresh = false}) async {
    _initOrderProvider();

    try {
      if (kDebugMode) {
        print('=== OrderDetailNotifier: loadOrderDetail ===');
        print('orderId: $orderId');
        print('forceRefresh: $forceRefresh');
      }

      // Intentar obtener del caché si no es forzado
      if (!forceRefresh) {
        final cacheKey = 'order_detail:$orderId';
        final cached = _cache.get<Map<String, dynamic>>(cacheKey);
        if (cached != null) {
          if (kDebugMode) {
            print('✅ Orden obtenida del caché');
          }
          state = state.copyWith(order: cached, isLoading: false);
          return;
        }
      }

      // Marcar como cargando
      if (!state.isLoading) {
        state = state.copyWith(isLoading: true, error: null);
      }

      // Petición al servidor
      final result = await _orderProvider.getOrderById(orderId);

      if (result['success']) {
        final order = result['data'] as Map<String, dynamic>;
        
        // Almacenar en caché con 15 minutos de TTL
        final cacheKey = 'order_detail:$orderId';
        _cache.set(
          cacheKey,
          order,
          ttl: const Duration(minutes: 15),
        );

        if (kDebugMode) {
          print('✅ Orden cargada del servidor');
        }

        state = state.copyWith(order: order, isLoading: false);
      } else {
        state = state.copyWith(
          error: result['message'] ?? 'Error obteniendo orden',
          isLoading: false,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error en loadOrderDetail: $e');
      }
      state = state.copyWith(
        error: 'Error de conexión: $e',
        isLoading: false,
      );
    }
  }

  /// Actualizar el estado de una orden
  Future<bool> updateOrderStatus({required String status}) async {
    _initOrderProvider();
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _orderProvider.updateOrderStatus(
        id: orderId,
        status: status,
      );

      if (result['success']) {
        // Actualizar el orden local
        final updatedOrder = {...?state.order, 'status': status};
        
        // Invalidar caché de este orden
        final cacheKey = 'order_detail:$orderId';
        _cache.invalidate(cacheKey);
        
        state = state.copyWith(
          order: updatedOrder,
          isLoading: false,
        );
        
        return true;
      } else {
        state = state.copyWith(
          error: result['message'] ?? 'Error actualizando orden',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        error: 'Error de conexión: $e',
        isLoading: false,
      );
      return false;
    }
  }

  /// Invalidar caché de este orden
  void invalidateCache() {
    final cacheKey = 'order_detail:$orderId';
    _cache.invalidate(cacheKey);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider con .family para lazy loading de detalles de órdenes
/// Uso: ref.watch(orderDetailProvider('order_id_123'))
final orderDetailProvider = StateNotifierProvider.family<
    OrderDetailNotifier,
    OrderDetailState,
    String // El ID del orden
>(
  (ref, orderId) => OrderDetailNotifier(ref, orderId),
);
