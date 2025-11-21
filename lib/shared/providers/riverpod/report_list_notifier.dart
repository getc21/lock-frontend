import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/cache_service.dart';

class ReportListState {
  final List<Map<String, dynamic>>? reports;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const ReportListState({
    this.reports,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  ReportListState copyWith({
    List<Map<String, dynamic>>? reports,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) =>
      ReportListState(
        reports: reports ?? this.reports,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

class ReportListNotifier extends StateNotifier<ReportListState> {
  final CacheService _cache = CacheService();

  ReportListNotifier() : super(const ReportListState());

  Future<void> loadReports({bool forceRefresh = false}) async {
    const cacheKey = 'report_list';

    if (!forceRefresh) {
      final cached = _cache.get<List<Map<String, dynamic>>>(cacheKey);
      if (cached != null) {
        if (kDebugMode) print('✅ Reports obtenidos del caché');
        state = state.copyWith(reports: cached);
        return;
      }
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final reports = <Map<String, dynamic>>[
        {'id': '1', 'name': 'Report 1', 'type': 'Sales'},
      ];

      _cache.set(cacheKey, reports, ttl: const Duration(minutes: 5));

      if (kDebugMode) print('✅ ${reports.length} reports cacheados');

      state = state.copyWith(reports: reports, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void invalidateReportList() {
    _cache.invalidate('report_list');
    if (kDebugMode) print('🗑️ Cache de reports invalidado');
  }
}

final reportListProvider =
    StateNotifierProvider<ReportListNotifier, ReportListState>(
  (ref) => ReportListNotifier(),
);
