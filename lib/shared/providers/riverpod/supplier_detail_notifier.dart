import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Estado para supplier detail
class SupplierDetailState {
  final Map<String, dynamic>? supplier;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const SupplierDetailState({
    this.supplier,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  SupplierDetailState copyWith({
    Map<String, dynamic>? supplier,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) =>
      SupplierDetailState(
        supplier: supplier ?? this.supplier,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

/// Notifier para supplier detail
class SupplierDetailNotifier extends StateNotifier<SupplierDetailState> {
  SupplierDetailNotifier() : super(const SupplierDetailState());

  Future<void> load(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // TODO: Reemplazar con API call real
      final supplier = {'id': id, 'name': 'Supplier $id'};
      state = state.copyWith(
        supplier: supplier,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

/// Provider con .family para lazy loading
final supplierDetailProvider = StateNotifierProvider.family<
    SupplierDetailNotifier,
    SupplierDetailState,
    String>(
  (ref, id) => SupplierDetailNotifier(),
);
