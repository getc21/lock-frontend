import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../category_provider.dart' as category_api;
import 'auth_notifier.dart';
import '../../services/cache_service.dart';

class CategoryState {
  final List<Map<String, dynamic>> categories;
  final bool isLoading;
  final String errorMessage;

  CategoryState({
    this.categories = const [],
    this.isLoading = false,
    this.errorMessage = '',
  });

  CategoryState copyWith({
    List<Map<String, dynamic>>? categories,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class CategoryNotifier extends StateNotifier<CategoryState> {
  final Ref ref;
  final CacheService _cache = CacheService();

  CategoryNotifier(this.ref) : super(CategoryState());

  late category_api.CategoryProvider _categoryProvider;

  String _getCacheKey() => 'categories:all';

  void _initCategoryProvider() {
    final authState = ref.read(authProvider);
    _categoryProvider = category_api.CategoryProvider(authState.token);
  }

  Future<void> loadCategories({bool forceRefresh = false}) async {
    _initCategoryProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final cacheKey = _getCacheKey();

      // Intentar obtener del caché si no es forzado
      if (!forceRefresh) {
        final cachedCategories = _cache.get<List<Map<String, dynamic>>>(cacheKey);
        if (cachedCategories != null) {
          state = state.copyWith(categories: cachedCategories, isLoading: false);
          return;
        }
      }

      final result = await _categoryProvider.getCategories();

      if (result['success']) {
        final categories = List<Map<String, dynamic>>.from(result['data'] ?? []);
        _cache.set(
          cacheKey,
          categories,
          ttl: const Duration(minutes: 15),
        );
        state = state.copyWith(categories: categories);
      } else {
        state = state.copyWith(
          errorMessage: result['message'] ?? 'Error cargando categorías',
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error de conexión: $e',
      );
    }
    
    state = state.copyWith(isLoading: false);
  }

  Future<Map<String, dynamic>?> getCategoryById(String id) async {
    _initCategoryProvider();

    try {
      final result = await _categoryProvider.getCategoryById(id);

      if (result['success']) {
        return result['data'];
      } else {
        state = state.copyWith(
          errorMessage: result['message'] ?? 'Error obteniendo categoría',
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

  Future<bool> createCategory({
    required String name,
    String? description,
    dynamic imageFile,
    String? imageBytes,
  }) async {
    _initCategoryProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _categoryProvider.createCategory(
        name: name,
        description: description,
        imageFile: imageFile,
        imageBytes: imageBytes,
      );

      if (result['success']) {
        _cache.invalidatePattern('categories:');
        await loadCategories(forceRefresh: true);
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error creando categoría',
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

  Future<bool> updateCategory({
    required String id,
    String? name,
    String? description,
    dynamic imageFile,
    String? imageBytes,
  }) async {
    _initCategoryProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _categoryProvider.updateCategory(
        id: id,
        name: name,
        description: description,
        imageFile: imageFile,
        imageBytes: imageBytes,
      );

      if (result['success']) {
        _cache.invalidatePattern('categories:');
        await loadCategories(forceRefresh: true);
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error actualizando categoría',
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

  Future<bool> deleteCategory(String id) async {
    _initCategoryProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _categoryProvider.deleteCategory(id);

      if (result['success']) {
        _cache.invalidatePattern('categories:');
        await loadCategories(forceRefresh: true);
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error eliminando categoría',
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

  void clearCategories() {
    state = CategoryState();
  }
}

final categoryProvider = StateNotifierProvider<CategoryNotifier, CategoryState>((ref) {
  return CategoryNotifier(ref);
});
