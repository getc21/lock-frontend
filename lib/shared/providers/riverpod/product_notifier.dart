import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../product_provider.dart' as product_api;
import 'auth_notifier.dart';
import 'store_notifier.dart';
import '../../services/cache_service.dart';

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
  final CacheService _cache = CacheService();

  ProductNotifier(this.ref) : super(ProductState());

  late product_api.ProductProvider _productProvider;

  void _initProductProvider() {
    final authState = ref.read(authProvider);
    _productProvider = product_api.ProductProvider(authState.token);
  }

  String _getCacheKey(String storeId, {String? categoryId, String? supplierId, String? locationId, bool? lowStock}) {
    return 'products:$storeId:$categoryId:$supplierId:$locationId:$lowStock';
  }

  // Cargar productos con caché
  Future<void> loadProducts({
    String? storeId,
    String? categoryId,
    String? supplierId,
    String? locationId,
    bool? lowStock,
    bool forceRefresh = false,
  }) async {
    _initProductProvider();

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

      final cacheKey = _getCacheKey(
        effectiveStoreId,
        categoryId: categoryId,
        supplierId: supplierId,
        locationId: locationId,
        lowStock: lowStock,
      );

      // SIEMPRE intentar obtener del caché primero (incluso si forceRefresh)
      final cached = _cache.get<List<Map<String, dynamic>>>(cacheKey);
      if (cached != null && !state.isLoading) {
        // Mostrar datos en caché inmediatamente
        state = state.copyWith(products: cached, isLoading: false, errorMessage: '');
        // Si no es forzado, terminar aquí
        if (!forceRefresh) {
          return;
        }
        // Si es forzado, continuar cargando en background pero sin mostrar loading
      } else if (!state.isLoading && cached == null) {
        // Solo mostrar loading si no hay caché
        state = state.copyWith(isLoading: true, errorMessage: '');
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
        _cache.set(cacheKey, products, ttl: const Duration(minutes: 10));
        state = state.copyWith(products: products, isLoading: false);
      } else {
        state = state.copyWith(
          errorMessage: result['message'] ?? 'Error cargando productos',
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

  // Cargar productos de la tienda actual
  Future<void> loadProductsForCurrentStore({bool forceRefresh = false}) async {
    _initProductProvider();
    final storeState = ref.read(storeProvider);

    if (storeState.currentStore != null) {
      await loadProducts(storeId: storeState.currentStore!['_id'], forceRefresh: forceRefresh);
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
        _cache.invalidatePattern('products:$storeId');
        await loadProducts(storeId: storeId, forceRefresh: true);
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
        _cache.invalidatePattern('products:');
        await loadProductsForCurrentStore(forceRefresh: true);
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
        _cache.invalidatePattern('products:');
        await loadProductsForCurrentStore(forceRefresh: true);
        state = state.copyWith(isLoading: false);
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

  // Ajustar stock de producto
  Future<bool> adjustStock({
    required String productId,
    required int adjustment,
  }) async {
    _initProductProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _productProvider.adjustStock(
        productId: productId,
        adjustment: adjustment,
      );

      if (result['success']) {
        _cache.invalidatePattern('products:');
        await loadProductsForCurrentStore(forceRefresh: true);
        state = state.copyWith(isLoading: false);
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

