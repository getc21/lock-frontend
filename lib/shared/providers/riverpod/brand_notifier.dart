import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../brand_provider.dart' as brand_api;
import 'auth_notifier.dart';

// Estado de marcas
class BrandState {
  final List<Map<String, dynamic>> brands;
  final Map<String, dynamic>? selectedBrand;
  final Map<String, dynamic>? brandStats;
  final bool isLoading;
  final String errorMessage;
  final String successMessage;

  BrandState({
    this.brands = const [],
    this.selectedBrand,
    this.brandStats,
    this.isLoading = false,
    this.errorMessage = '',
    this.successMessage = '',
  });

  BrandState copyWith({
    List<Map<String, dynamic>>? brands,
    Map<String, dynamic>? selectedBrand,
    Map<String, dynamic>? brandStats,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return BrandState(
      brands: brands ?? this.brands,
      selectedBrand: selectedBrand ?? this.selectedBrand,
      brandStats: brandStats ?? this.brandStats,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}

class BrandNotifier extends StateNotifier<BrandState> {
  final Ref ref;
  brand_api.BrandProvider? _brandProvider;

  BrandNotifier(this.ref) : super(BrandState());

  void _initProvider() {
    final token = ref.read(authProvider).token;
    if (token.isNotEmpty) {
      _brandProvider = brand_api.BrandProvider(token);
    }
  }

  /// Cargar todas las marcas
  Future<void> loadBrands() async {
    _initProvider();
    if (_brandProvider == null) return;

    state = state.copyWith(isLoading: true, errorMessage: '', successMessage: '');

    try {
      final result = await _brandProvider!.getBrands();
      if (result['success']) {
        final brands = List<Map<String, dynamic>>.from(result['data'] ?? []);
        state = state.copyWith(brands: brands, isLoading: false);
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error al cargar marcas',
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error: $e');
    }
  }

  /// Obtener estadísticas de una marca
  Future<void> loadBrandStats(String brandId) async {
    _initProvider();
    if (_brandProvider == null) return;

    try {
      final result = await _brandProvider!.getBrandStats(brandId);
      if (result['success']) {
        state = state.copyWith(brandStats: result['data']);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('Error loading brand stats: $e');
    }
  }

  /// Crear marca + admin
  Future<bool> createBrand({
    required Map<String, dynamic> brandData,
    required Map<String, dynamic> adminData,
    dynamic imageFile,
    String? imageBytes,
  }) async {
    _initProvider();
    if (_brandProvider == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: '', successMessage: '');

    try {
      final result = await _brandProvider!.createBrand(
        brandData: brandData,
        adminData: adminData,
        imageFile: imageFile,
        imageBytes: imageBytes,
      );

      if (result['success']) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Marca creada exitosamente',
        );
        await loadBrands();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error al crear marca',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error: $e');
      return false;
    }
  }

  /// Actualizar marca
  Future<bool> updateBrand(String id, Map<String, dynamic> data, {
    dynamic imageFile,
    String? imageBytes,
  }) async {
    _initProvider();
    if (_brandProvider == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: '', successMessage: '');

    try {
      final result = await _brandProvider!.updateBrand(id, data,
        imageFile: imageFile,
        imageBytes: imageBytes,
      );
      if (result['success']) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Marca actualizada exitosamente',
        );
        await loadBrands();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error al actualizar marca',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error: $e');
      return false;
    }
  }

  /// Desactivar marca (soft delete)
  Future<bool> deleteBrand(String id) async {
    _initProvider();
    if (_brandProvider == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: '', successMessage: '');

    try {
      final result = await _brandProvider!.deleteBrand(id);
      if (result['success']) {
        state = state.copyWith(
          isLoading: false,
          successMessage: 'Marca desactivada exitosamente',
        );
        await loadBrands();
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error al desactivar marca',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: 'Error: $e');
      return false;
    }
  }

  void selectBrand(Map<String, dynamic> brand) {
    state = state.copyWith(selectedBrand: brand);
  }

  void clearMessages() {
    state = state.copyWith(errorMessage: '', successMessage: '');
  }
}

final brandProvider = StateNotifierProvider<BrandNotifier, BrandState>((ref) {
  return BrandNotifier(ref);
});
