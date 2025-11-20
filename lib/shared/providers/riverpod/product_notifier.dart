import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../product_provider.dart' as product_api;
import 'auth_notifier.dart';
import 'store_notifier.dart';

// Estado de productos
class ProductState {
  final List<Map<String, dynamic>> products;
  final bool isLoading;
  final String errorMessage;

  ProductState({
    this.products = const [],
    this.isLoading = false,
    this.errorMessage = '',
  });

  ProductState copyWith({
    List<Map<String, dynamic>>? products,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ProductState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// Notifier para productos
class ProductNotifier extends StateNotifier<ProductState> {
  final Ref ref;

  ProductNotifier(this.ref) : super(ProductState());

  late product_api.ProductProvider _productProvider;

  void _initProductProvider() {
    final authState = ref.read(authProvider);
    _productProvider = product_api.ProductProvider(authState.token);
  }

  // Cargar productos
  Future<void> loadProducts({
    String? storeId,
    String? categoryId,
    String? supplierId,
    String? locationId,
    bool? lowStock,
  }) async {
    _initProductProvider();

    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final effectiveStoreId = storeId ?? ref.read(storeProvider).currentStore?['_id'];

      if (effectiveStoreId == null) {
        state = state.copyWith(products: [], isLoading: false);
        return;
      }

      if (kDebugMode) {
        print('=== ProductNotifier: loadProducts ===');
        print('effectiveStoreId: $effectiveStoreId');
      }

      final result = await _productProvider.getProducts(
        storeId: effectiveStoreId,
        categoryId: categoryId,
        supplierId: supplierId,
        locationId: locationId,
        lowStock: lowStock,
      );

      if (result['success']) {
        final products = List<Map<String, dynamic>>.from(result['data']);
        state = state.copyWith(products: products);
      } else {
        state = state.copyWith(
          errorMessage: result['message'] ?? 'Error cargando productos',
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error de conexión: $e',
      );
    }
    
    state = state.copyWith(isLoading: false);
  }

  // Cargar productos de la tienda actual
  Future<void> loadProductsForCurrentStore() async {
    _initProductProvider();
    final storeState = ref.read(storeProvider);

    if (storeState.currentStore != null) {
      await loadProducts(storeId: storeState.currentStore!['_id']);
    } else {
      state = state.copyWith(products: []);
    }
  }

  // Crear producto
  Future<bool> createProduct({
    required String storeId,
    required String name,
    required double purchasePrice,
    required double salePrice,
    required String categoryId,
    required String supplierId,
    required String locationId,
    required int stock,
    required DateTime expiryDate,
    String? description,
    double? weight,
    dynamic imageFile,
    String? imageBytes,
  }) async {
    _initProductProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _productProvider.createProduct(
        storeId: storeId,
        name: name,
        description: description,
        purchasePrice: purchasePrice,
        salePrice: salePrice,
        weight: weight,
        categoryId: categoryId,
        supplierId: supplierId,
        locationId: locationId,
        stock: stock,
        expiryDate: expiryDate,
        imageFile: imageFile,
        imageBytes: imageBytes,
      );

      if (result['success']) {
        await loadProducts(storeId: storeId);
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error creando producto',
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

  // Actualizar producto
  Future<bool> updateProduct({
    required String id,
    String? name,
    String? description,
    double? purchasePrice,
    double? salePrice,
    double? weight,
    String? categoryId,
    String? supplierId,
    String? locationId,
    DateTime? expiryDate,
    dynamic imageFile,
    String? imageBytes,
  }) async {
    _initProductProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _productProvider.updateProduct(
        id: id,
        name: name,
        description: description,
        purchasePrice: purchasePrice,
        salePrice: salePrice,
        weight: weight,
        categoryId: categoryId,
        supplierId: supplierId,
        locationId: locationId,
        expiryDate: expiryDate,
        imageFile: imageFile,
        imageBytes: imageBytes,
      );

      if (result['success']) {
        await loadProductsForCurrentStore();
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error actualizando producto',
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

  // Eliminar producto
  Future<bool> deleteProduct(String id) async {
    _initProductProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _productProvider.deleteProduct(id);

      if (result['success']) {
        state = state.copyWith(
          products: state.products.where((p) => p['_id'] != id).toList(),
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error eliminando producto',
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

  void clearProducts() {
    state = ProductState();
  }
}

// Provider
final productProvider = StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  return ProductNotifier(ref);
});
