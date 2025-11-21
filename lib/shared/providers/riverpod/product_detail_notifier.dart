import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../product_provider.dart' as product_api;
import 'auth_notifier.dart';
import '../../services/cache_service.dart';

/// Estado para un detalle individual de producto
class ProductDetailState {
  final Map<String, dynamic>? product;
  final bool isLoading;
  final String? error;

  const ProductDetailState({
    this.product,
    this.isLoading = false,
    this.error,
  });

  ProductDetailState copyWith({
    Map<String, dynamic>? product,
    bool? isLoading,
    String? error,
  }) =>
      ProductDetailState(
        product: product ?? this.product,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
      );
}

/// Notifier para un producto específico (lazy loading con .family)
class ProductDetailNotifier extends StateNotifier<ProductDetailState> {
  final Ref ref;
  final String productId;
  final CacheService _cache = CacheService();
  late product_api.ProductProvider _productProvider;

  ProductDetailNotifier(this.ref, this.productId)
      : super(const ProductDetailState());

  /// Inicializar el provider con el token del auth
  void _initProductProvider() {
    final authState = ref.read(authProvider);
    _productProvider = product_api.ProductProvider(authState.token);
  }

  /// Cargar detalle de un producto específico
  Future<void> loadProductDetail({bool forceRefresh = false}) async {
    _initProductProvider();

    try {
      if (kDebugMode) {
        print('=== ProductDetailNotifier: loadProductDetail ===');
        print('productId: $productId');
        print('forceRefresh: $forceRefresh');
      }

      // Intentar obtener del caché si no es forzado
      if (!forceRefresh) {
        final cacheKey = 'product_detail:$productId';
        final cached = _cache.get<Map<String, dynamic>>(cacheKey);
        if (cached != null) {
          if (kDebugMode) {
            print('✅ Producto obtenido del caché');
          }
          state = state.copyWith(product: cached, isLoading: false);
          return;
        }
      }

      // Marcar como cargando
      if (!state.isLoading) {
        state = state.copyWith(isLoading: true, error: null);
      }

      // Petición al servidor
      final result = await _productProvider.getProductById(productId);

      if (result['success']) {
        final product = result['data'] as Map<String, dynamic>;

        // Almacenar en caché con 15 minutos de TTL
        final cacheKey = 'product_detail:$productId';
        _cache.set(
          cacheKey,
          product,
          ttl: const Duration(minutes: 15),
        );

        if (kDebugMode) {
          print('✅ Producto cargado del servidor');
        }

        state = state.copyWith(product: product, isLoading: false);
      } else {
        state = state.copyWith(
          error: result['message'] ?? 'Error obteniendo producto',
          isLoading: false,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error en loadProductDetail: $e');
      }
      state = state.copyWith(
        error: 'Error de conexión: $e',
        isLoading: false,
      );
    }
  }

  /// Actualizar el precio de un producto
  Future<bool> updatePrice({required double newPrice}) async {
    _initProductProvider();
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _productProvider.updateProduct(
        id: productId,
        data: {'price': newPrice},
      );

      if (result['success']) {
        // Actualizar el producto local
        final updatedProduct = {...?state.product, 'price': newPrice};

        // Invalidar caché de este producto
        final cacheKey = 'product_detail:$productId';
        _cache.invalidate(cacheKey);

        state = state.copyWith(
          product: updatedProduct,
          isLoading: false,
        );

        return true;
      } else {
        state = state.copyWith(
          error: result['message'] ?? 'Error actualizando precio',
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

  /// Actualizar el stock de un producto
  Future<bool> updateStock({required int newStock}) async {
    _initProductProvider();
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await _productProvider.updateProduct(
        id: productId,
        data: {'stock': newStock},
      );

      if (result['success']) {
        // Actualizar el producto local
        final updatedProduct = {...?state.product, 'stock': newStock};

        // Invalidar caché de este producto
        final cacheKey = 'product_detail:$productId';
        _cache.invalidate(cacheKey);

        state = state.copyWith(
          product: updatedProduct,
          isLoading: false,
        );

        return true;
      } else {
        state = state.copyWith(
          error: result['message'] ?? 'Error actualizando stock',
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

  /// Invalidar caché de este producto
  void invalidateCache() {
    final cacheKey = 'product_detail:$productId';
    _cache.invalidate(cacheKey);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider con .family para lazy loading de detalles de productos
/// Uso: ref.watch(productDetailProvider('product_id_123'))
final productDetailProvider = StateNotifierProvider.family<
    ProductDetailNotifier,
    ProductDetailState,
    String // El ID del producto
>(
  (ref, productId) => ProductDetailNotifier(ref, productId),
);
