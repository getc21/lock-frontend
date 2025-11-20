import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../discount_provider.dart' as discount_api;
import 'auth_notifier.dart';
import 'store_notifier.dart';

class DiscountState {
  final List<Map<String, dynamic>> discounts;
  final bool isLoading;
  final String errorMessage;

  DiscountState({
    this.discounts = const [],
    this.isLoading = false,
    this.errorMessage = '',
  });

  DiscountState copyWith({
    List<Map<String, dynamic>>? discounts,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DiscountState(
      discounts: discounts ?? this.discounts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class DiscountNotifier extends StateNotifier<DiscountState> {
  final Ref ref;

  DiscountNotifier(this.ref) : super(DiscountState());

  late discount_api.DiscountProvider _discountProvider;

  void _initDiscountProvider() {
    final authState = ref.read(authProvider);
    _discountProvider = discount_api.DiscountProvider(authState.token);
  }

  Future<void> loadDiscounts({String? storeId}) async {
    _initDiscountProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final effectiveStoreId = storeId ?? ref.read(storeProvider).currentStore?['_id'];

      final result = await _discountProvider.getDiscounts(
        storeId: effectiveStoreId,
      );

      if (result['success']) {
        final discounts = List<Map<String, dynamic>>.from(result['data'] ?? []);
        state = state.copyWith(discounts: discounts);
      } else {
        state = state.copyWith(
          errorMessage: result['message'] ?? 'Error cargando descuentos',
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error de conexión: $e',
      );
    }
    
    state = state.copyWith(isLoading: false);
  }

  Future<void> loadDiscountsForCurrentStore() async {
    _initDiscountProvider();
    final storeState = ref.read(storeProvider);

    if (storeState.currentStore != null) {
      await loadDiscounts(storeId: storeState.currentStore!['_id']);
    } else {
      state = state.copyWith(discounts: []);
    }
  }

  Future<Map<String, dynamic>?> getDiscountById(String id) async {
    _initDiscountProvider();

    try {
      final result = await _discountProvider.getDiscountById(id);

      if (result['success']) {
        return result['data'];
      } else {
        state = state.copyWith(
          errorMessage: result['message'] ?? 'Error obteniendo descuento',
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error de conexión: $e',
      );
      return null;
    }
  }

  Future<bool> createDiscount({
    required String name,
    String? description,
    required String type,
    required double value,
    double? minimumAmount,
    double? maximumDiscount,
    String? startDate,
    String? endDate,
    bool? active,
  }) async {
    _initDiscountProvider();
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

      final result = await _discountProvider.createDiscount(
        name: name,
        description: description,
        type: type,
        value: value,
        minimumAmount: minimumAmount,
        maximumDiscount: maximumDiscount,
        startDate: startDate,
        endDate: endDate,
        active: active,
        storeId: storeState.currentStore!['_id'],
      );

      if (result['success']) {
        await loadDiscountsForCurrentStore();
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error creando descuento',
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

  Future<bool> updateDiscount({
    required String id,
    String? name,
    String? description,
    String? type,
    double? value,
    double? minimumAmount,
    double? maximumDiscount,
    String? startDate,
    String? endDate,
    bool? active,
  }) async {
    _initDiscountProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _discountProvider.updateDiscount(
        id: id,
        name: name,
        description: description,
        type: type,
        value: value,
        minimumAmount: minimumAmount,
        maximumDiscount: maximumDiscount,
        startDate: startDate,
        endDate: endDate,
        active: active,
      );

      if (result['success']) {
        await loadDiscountsForCurrentStore();
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error actualizando descuento',
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

  Future<bool> deleteDiscount(String id) async {
    _initDiscountProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _discountProvider.deleteDiscount(id);

      if (result['success']) {
        state = state.copyWith(
          discounts: state.discounts.where((d) => d['_id'] != id).toList(),
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error eliminando descuento',
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

  void clearDiscounts() {
    state = DiscountState();
  }
}

final discountProvider = StateNotifierProvider<DiscountNotifier, DiscountState>((ref) {
  return DiscountNotifier(ref);
});
