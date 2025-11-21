import 'package:flutter_riverpod/flutter_riverpod.dart';

class LocationDetailState {
  final Map<String, dynamic>? location;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const LocationDetailState({
    this.location,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  LocationDetailState copyWith({
    Map<String, dynamic>? location,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) =>
      LocationDetailState(
        location: location ?? this.location,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

class LocationDetailNotifier extends StateNotifier<LocationDetailState> {
  LocationDetailNotifier() : super(const LocationDetailState());

  Future<void> load(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final location = {'id': id, 'name': 'Location $id'};
      state = state.copyWith(
        location: location,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final locationDetailProvider = StateNotifierProvider.family<
    LocationDetailNotifier,
    LocationDetailState,
    String>(
  (ref, id) => LocationDetailNotifier(),
);
