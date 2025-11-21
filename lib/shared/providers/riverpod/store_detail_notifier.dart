import 'package:flutter_riverpod/flutter_riverpod.dart';

class StoreDetailState {
  final Map<String, dynamic>? store;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const StoreDetailState({
    this.store,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  StoreDetailState copyWith({
    Map<String, dynamic>? store,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) =>
      StoreDetailState(
        store: store ?? this.store,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

class StoreDetailNotifier extends StateNotifier<StoreDetailState> {
  StoreDetailNotifier() : super(const StoreDetailState());

  Future<void> load(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final store = {'id': id, 'name': 'Store $id'};
      state = state.copyWith(
        store: store,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final storeDetailProvider = StateNotifierProvider.family<
    StoreDetailNotifier,
    StoreDetailState,
    String>(
  (ref, id) => StoreDetailNotifier(),
);
