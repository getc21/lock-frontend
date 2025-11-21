import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../location_provider.dart' as location_api;
import 'auth_notifier.dart';
import 'store_notifier.dart';
import '../../services/cache_service.dart';

class LocationState {
  final List<Map<String, dynamic>> locations;
  final bool isLoading;
  final String errorMessage;

  LocationState({
    this.locations = const [],
    this.isLoading = false,
    this.errorMessage = '',
  });

  LocationState copyWith({
    List<Map<String, dynamic>>? locations,
    bool? isLoading,
    String? errorMessage,
  }) {
    return LocationState(
      locations: locations ?? this.locations,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class LocationNotifier extends StateNotifier<LocationState> {
  final Ref ref;
  final CacheService _cache = CacheService();

  LocationNotifier(this.ref) : super(LocationState());

  late location_api.LocationProvider _locationProvider;

  String _getCacheKey(String storeId) => 'locations:$storeId';

  void _initLocationProvider() {
    final authState = ref.read(authProvider);
    _locationProvider = location_api.LocationProvider(authState.token);
  }

  Future<void> loadLocations({String? storeId, bool forceRefresh = false}) async {
    _initLocationProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final effectiveStoreId = storeId ?? ref.read(storeProvider).currentStore?['_id'];

      final cacheKey = _getCacheKey(effectiveStoreId ?? '');

      // Intentar obtener del caché si no es forzado
      if (!forceRefresh && effectiveStoreId != null) {
        final cachedLocations = _cache.get<List<Map<String, dynamic>>>(cacheKey);
        if (cachedLocations != null) {
          state = state.copyWith(locations: cachedLocations, isLoading: false);
          return;
        }
      }

      final result = await _locationProvider.getLocations(
        storeId: effectiveStoreId,
      );

      if (result['success']) {
        final locations = List<Map<String, dynamic>>.from(result['data'] ?? []);
        if (effectiveStoreId != null) {
          _cache.set(
            cacheKey,
            locations,
            ttl: const Duration(minutes: 10),
          );
        }
        state = state.copyWith(locations: locations);
      } else {
        state = state.copyWith(
          errorMessage: result['message'] ?? 'Error cargando ubicaciones',
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error de conexión: $e',
      );
    }
    
    state = state.copyWith(isLoading: false);
  }

  Future<void> loadLocationsForCurrentStore({bool forceRefresh = false}) async {
    _initLocationProvider();
    final storeState = ref.read(storeProvider);

    if (storeState.currentStore != null) {
      await loadLocations(storeId: storeState.currentStore!['_id'], forceRefresh: forceRefresh);
    } else {
      state = state.copyWith(locations: []);
    }
  }

  Future<Map<String, dynamic>?> getLocationById(String id) async {
    _initLocationProvider();

    try {
      final result = await _locationProvider.getLocationById(id);

      if (result['success']) {
        return result['data'];
      } else {
        state = state.copyWith(
          errorMessage: result['message'] ?? 'Error obteniendo ubicación',
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

  Future<bool> createLocation({
    required String name,
    String? description,
  }) async {
    _initLocationProvider();
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

      final result = await _locationProvider.createLocation(
        name: name,
        storeId: storeState.currentStore!['_id'],
        description: description,
      );

      if (result['success']) {
        _cache.invalidatePattern('locations:');
        await loadLocationsForCurrentStore(forceRefresh: true);
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error creando ubicación',
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

  Future<bool> updateLocation({
    required String id,
    String? name,
    String? description,
  }) async {
    _initLocationProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _locationProvider.updateLocation(
        id: id,
        name: name,
        description: description,
      );

      if (result['success']) {
        _cache.invalidatePattern('locations:');
        await loadLocationsForCurrentStore(forceRefresh: true);
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error actualizando ubicación',
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

  Future<bool> deleteLocation(String id) async {
    _initLocationProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _locationProvider.deleteLocation(id);

      if (result['success']) {
        _cache.invalidatePattern('locations:');
        await loadLocationsForCurrentStore(forceRefresh: true);
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error eliminando ubicación',
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

  void clearLocations() {
    state = LocationState();
  }
}

final locationProvider = StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier(ref);
});
