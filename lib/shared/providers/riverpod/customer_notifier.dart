import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../customer_provider.dart' as customer_api;
import 'auth_notifier.dart';
import 'store_notifier.dart';
import '../../services/cache_service.dart';

class CustomerState {
  final List<Map<String, dynamic>> customers;
  final bool isLoading;
  final String errorMessage;

  CustomerState({
    this.customers = const [],
    this.isLoading = false,
    this.errorMessage = '',
  });

  CustomerState copyWith({
    List<Map<String, dynamic>>? customers,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CustomerState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class CustomerNotifier extends StateNotifier<CustomerState> {
  final Ref ref;
  final CacheService _cache = CacheService();

  CustomerNotifier(this.ref) : super(CustomerState());

  late customer_api.CustomerProvider _customerProvider;

  String _getCacheKey(String storeId) => 'customers:$storeId';

  void _initCustomerProvider() {
    final authState = ref.read(authProvider);
    _customerProvider = customer_api.CustomerProvider(authState.token);
  }

  Future<void> loadCustomers({String? storeId, bool forceRefresh = false}) async {
    _initCustomerProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final effectiveStoreId = storeId ?? ref.read(storeProvider).currentStore?['_id'];

      if (effectiveStoreId == null) {
        state = state.copyWith(customers: [], isLoading: false);
        return;
      }

      final cacheKey = _getCacheKey(effectiveStoreId);

      // Intentar obtener del caché si no es forzado
      if (!forceRefresh) {
        final cachedCustomers = _cache.get<List<Map<String, dynamic>>>(cacheKey);
        if (cachedCustomers != null) {
          state = state.copyWith(customers: cachedCustomers, isLoading: false);
          return;
        }
      }

      final result = await _customerProvider.getCustomers(
        storeId: effectiveStoreId,
      );

      if (result['success']) {
        final customers = List<Map<String, dynamic>>.from(result['data'] ?? []);
        _cache.set(
          cacheKey,
          customers,
          ttl: const Duration(minutes: 10),
        );
        state = state.copyWith(customers: customers);
      } else {
        state = state.copyWith(
          errorMessage: result['message'] ?? 'Error cargando clientes',
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error de conexión: $e',
      );
    }
    
    state = state.copyWith(isLoading: false);
  }

  Future<void> loadCustomersForCurrentStore({bool forceRefresh = false}) async {
    _initCustomerProvider();
    final storeState = ref.read(storeProvider);

    if (storeState.currentStore != null) {
      await loadCustomers(storeId: storeState.currentStore!['_id'], forceRefresh: forceRefresh);
    } else {
      state = state.copyWith(customers: []);
    }
  }

  Future<bool> createCustomer({
    required String name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    _initCustomerProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final storeState = ref.read(storeProvider);
      if (storeState.currentStore == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No store selected',
        );
        return false;
      }

      final result = await _customerProvider.createCustomer(
        name: name,
        phone: phone,
        email: email,
        address: address,
        notes: notes,
        storeId: storeState.currentStore!['_id'],
      );

      if (result['success']) {
        _cache.invalidatePattern('customers:');
        await loadCustomersForCurrentStore(forceRefresh: true);
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error creando cliente',
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

  Future<bool> updateCustomer({
    required String id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
  }) async {
    _initCustomerProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _customerProvider.updateCustomer(
        id: id,
        name: name,
        phone: phone,
        email: email,
        address: address,
        notes: notes,
      );

      if (result['success']) {
        _cache.invalidatePattern('customers:');
        await loadCustomersForCurrentStore(forceRefresh: true);
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error actualizando cliente',
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

  Future<bool> deleteCustomer(String id) async {
    _initCustomerProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _customerProvider.deleteCustomer(id);

      if (result['success']) {
        _cache.invalidatePattern('customers:');
        await loadCustomersForCurrentStore(forceRefresh: true);
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error eliminando cliente',
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

  void clearCustomers() {
    state = CustomerState();
  }
}

final customerProvider = StateNotifierProvider<CustomerNotifier, CustomerState>((ref) {
  return CustomerNotifier(ref);
});
