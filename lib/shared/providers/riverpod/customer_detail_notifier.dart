import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../customer_provider.dart' as customer_api;
import 'auth_notifier.dart';
import '../../services/cache_service.dart';

/// Estado para un detalle individual de cliente
class CustomerDetailState {
  final Map<String, dynamic>? customer;
  final bool isLoading;
  final String? error;

  const CustomerDetailState({
    this.customer,
    this.isLoading = false,
    this.error,
  });

  CustomerDetailState copyWith({
    Map<String, dynamic>? customer,
    bool? isLoading,
    String? error,
  }) {
    return CustomerDetailState(
      customer: customer ?? this.customer,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// Notifier para un cliente específico (lazy loading con .family)
class CustomerDetailNotifier extends StateNotifier<CustomerDetailState> {
  final Ref ref;
  final String customerId;
  final CacheService _cache = CacheService();
  late customer_api.CustomerProvider _customerProvider;

  CustomerDetailNotifier(this.ref, this.customerId)
      : super(const CustomerDetailState());

  /// Inicializar el provider con el token del auth
  void _initCustomerProvider() {
    final authState = ref.read(authProvider);
    _customerProvider = customer_api.CustomerProvider(authState.token);
  }

  /// Cargar detalle de un cliente específico
  Future<void> loadCustomerDetail({bool forceRefresh = false}) async {
    _initCustomerProvider();

    try {
      if (kDebugMode) {
        print('=== CustomerDetailNotifier: loadCustomerDetail ===');
        print('customerId: $customerId');
        print('forceRefresh: $forceRefresh');
      }

      // Intentar obtener del caché si no es forzado
      if (!forceRefresh) {
        final cacheKey = 'customer_detail:$customerId';
        final cached = _cache.get<Map<String, dynamic>>(cacheKey);
        if (cached != null) {
          if (kDebugMode) {
            print('✅ Cliente obtenido del caché');
          }
          state = state.copyWith(customer: cached, isLoading: false);
          return;
        }
      }

      // Marcar como cargando
      if (!state.isLoading) {
        state = state.copyWith(isLoading: true, error: null);
      }

      // Petición al servidor
      final result = await _customerProvider.getCustomerById(customerId);

      if (result['success']) {
        final customer = result['data'] as Map<String, dynamic>;

        // Almacenar en caché con 15 minutos de TTL
        final cacheKey = 'customer_detail:$customerId';
        _cache.set(
          cacheKey,
          customer,
          ttl: const Duration(minutes: 15),
        );

        if (kDebugMode) {
          print('✅ Cliente cargado del servidor');
        }

        state = state.copyWith(customer: customer, isLoading: false);
      } else {
        state = state.copyWith(
          error: result['message'] ?? 'Error obteniendo cliente',
          isLoading: false,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error en loadCustomerDetail: $e');
      }
      state = state.copyWith(
        error: 'Error de conexión: $e',
        isLoading: false,
      );
    }
  }

  /// Actualizar información del cliente
  Future<bool> updateCustomerInfo({
    required String name,
    String? email,
    String? phone,
    String? address,
  }) async {
    _initCustomerProvider();
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _customerProvider.updateCustomer(
        id: customerId,
        name: name,
        email: email,
        phone: phone,
        address: address,
      );

      if (result['success']) {
        // Actualizar el cliente local
        final updatedCustomer = {
          ...?state.customer,
          'name': name,
          if (email != null) 'email': email,
          if (phone != null) 'phone': phone,
          if (address != null) 'address': address,
        };

        // Invalidar caché de este cliente
        final cacheKey = 'customer_detail:$customerId';
        _cache.invalidate(cacheKey);

        state = state.copyWith(
          customer: updatedCustomer,
          isLoading: false,
        );

        return true;
      } else {
        state = state.copyWith(
          error: result['message'] ?? 'Error actualizando cliente',
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

  /// Invalidar caché de este cliente
  void invalidateCache() {
    final cacheKey = 'customer_detail:$customerId';
    _cache.invalidate(cacheKey);
    _cache.invalidate('customer_orders:$customerId');
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider con .family para lazy loading de detalles de clientes
/// Uso: ref.watch(customerDetailProvider('customer_id_123'))
final customerDetailProvider = StateNotifierProvider.family<
    CustomerDetailNotifier,
    CustomerDetailState,
    String // El ID del cliente
>(
  (ref, customerId) => CustomerDetailNotifier(ref, customerId),
);
