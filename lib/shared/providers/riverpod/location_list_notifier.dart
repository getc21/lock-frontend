import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/cache_service.dart';

class LocationListState {
  final List<Map<String, dynamic>>? locations;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const LocationListState({
    this.locations,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  LocationListState copyWith({
    List<Map<String, dynamic>>? locations,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) =>
      LocationListState(
        locations: locations ?? this.locations,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

class LocationListNotifier extends StateNotifier<LocationListState> {
  final CacheService _cache = CacheService();

  LocationListNotifier() : super(const LocationListState());

  Future<void> loadLocations({bool forceRefresh = false}) async {
    const cacheKey = 'location_list';

    if (!forceRefresh) {
      final cached = _cache.get<List<Map<String, dynamic>>>(cacheKey);
      if (cached != null) {
        if (kDebugMode) print('✅ Locations obtenidas del caché');
        state = state.copyWith(locations: cached);
        return;
      }
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final locations = <Map<String, dynamic>>[
        {'id': '1', 'name': 'Location 1', 'city': 'Madrid'},
      ];

      _cache.set(cacheKey, locations, ttl: const Duration(minutes: 5));

      if (kDebugMode) print('✅ ${locations.length} locations cacheadas');

      state = state.copyWith(locations: locations, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void invalidateLocationList() {
    _cache.invalidate('location_list');
    if (kDebugMode) print('🗑️ Cache de locations invalidado');
  }
}

final locationListProvider =
    StateNotifierProvider<LocationListNotifier, LocationListState>(
  (ref) => LocationListNotifier(),
);
