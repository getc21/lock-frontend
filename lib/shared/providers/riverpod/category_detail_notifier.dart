import 'package:flutter_riverpod/flutter_riverpod.dart';

class CategoryDetailState {
  final Map<String, dynamic>? category;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const CategoryDetailState({
    this.category,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  CategoryDetailState copyWith({
    Map<String, dynamic>? category,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) =>
      CategoryDetailState(
        category: category ?? this.category,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

class CategoryDetailNotifier extends StateNotifier<CategoryDetailState> {
  CategoryDetailNotifier() : super(const CategoryDetailState());

  Future<void> load(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final category = {'id': id, 'name': 'Category $id'};
      state = state.copyWith(
        category: category,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final categoryDetailProvider = StateNotifierProvider.family<
    CategoryDetailNotifier,
    CategoryDetailState,
    String>(
  (ref, id) => CategoryDetailNotifier(),
);
