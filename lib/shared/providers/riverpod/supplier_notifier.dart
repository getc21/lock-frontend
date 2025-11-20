import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../supplier_provider.dart' as supplier_api;

class SupplierState {
  final List<Map<String, dynamic>> suppliers;
  final bool isLoading;
  final String errorMessage;

  SupplierState({
    this.suppliers = const [],
    this.isLoading = false,
    this.errorMessage = '',
  });

  SupplierState copyWith({
    List<Map<String, dynamic>>? suppliers,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SupplierState(
      suppliers: suppliers ?? this.suppliers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class SupplierNotifier extends StateNotifier<SupplierState> {
  final Ref ref;

  SupplierNotifier(this.ref) : super(SupplierState());

  late supplier_api.SupplierProvider _supplierProvider;

  void _initSupplierProvider() {
    _supplierProvider = supplier_api.SupplierProvider();
  }

  Future<void> loadSuppliers() async {
    _initSupplierProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _supplierProvider.getSuppliers();

      if (result['success']) {
        final suppliers = List<Map<String, dynamic>>.from(result['data'] ?? []);
        state = state.copyWith(suppliers: suppliers);
      } else {
        state = state.copyWith(
          errorMessage: result['message'] ?? 'Error cargando proveedores',
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error de conexión: $e',
      );
    }
    
    state = state.copyWith(isLoading: false);
  }

  Future<Map<String, dynamic>?> getSupplierById(String id) async {
    _initSupplierProvider();

    try {
      final result = await _supplierProvider.getSupplierById(id);

      if (result['success']) {
        return result['data'];
      } else {
        state = state.copyWith(
          errorMessage: result['message'] ?? 'Error obteniendo proveedor',
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

  Future<bool> createSupplier({
    required String name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    dynamic imageFile,
    String? imageBytes,
  }) async {
    _initSupplierProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _supplierProvider.createSupplier(
        name,
        contactPerson,
        phone,
        email,
        address,
        imageFile,
        imageBytes,
      );

      if (result['success']) {
        await loadSuppliers();
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error creando proveedor',
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

  Future<bool> updateSupplier({
    required String id,
    required String name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    dynamic imageFile,
    String? imageBytes,
  }) async {
    _initSupplierProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _supplierProvider.updateSupplier(
        id,
        name,
        contactPerson,
        phone,
        email,
        address,
        imageFile,
        imageBytes,
      );

      if (result['success']) {
        await loadSuppliers();
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error actualizando proveedor',
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

  Future<bool> deleteSupplier(String id) async {
    _initSupplierProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _supplierProvider.deleteSupplier(id);

      if (result['success']) {
        state = state.copyWith(
          suppliers: state.suppliers.where((s) => s['_id'] != id).toList(),
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error eliminando proveedor',
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

  void clearSuppliers() {
    state = SupplierState();
  }
}

final supplierProvider = StateNotifierProvider<SupplierNotifier, SupplierState>((ref) {
  return SupplierNotifier(ref);
});
