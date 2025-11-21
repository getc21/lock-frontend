import 'package:flutter_riverpod/flutter_riverpod.dart';

class ReportDetailState {
  final Map<String, dynamic>? report;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const ReportDetailState({
    this.report,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  ReportDetailState copyWith({
    Map<String, dynamic>? report,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) =>
      ReportDetailState(
        report: report ?? this.report,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

class ReportDetailNotifier extends StateNotifier<ReportDetailState> {
  ReportDetailNotifier() : super(const ReportDetailState());

  Future<void> load(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final report = {'id': id, 'name': 'Report $id'};
      state = state.copyWith(
        report: report,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final reportDetailProvider = StateNotifierProvider.family<
    ReportDetailNotifier,
    ReportDetailState,
    String>(
  (ref, id) => ReportDetailNotifier(),
);
