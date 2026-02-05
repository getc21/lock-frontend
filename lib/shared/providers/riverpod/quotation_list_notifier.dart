import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bellezapp_web/shared/models/quotation.dart';
import 'package:bellezapp_web/shared/providers/quotation_api.dart';

// State class
class QuotationListState {
  final List<Quotation> quotations;
  final bool isLoading;
  final String? error;
  final String? statusFilter; // 'pending', 'converted', 'expired', 'cancelled', null for all
  final DateTime? startDate;
  final DateTime? endDate;
  final int currentPage;
  final int pageSize;
  final int totalItems;

  const QuotationListState({
    this.quotations = const [],
    this.isLoading = false,
    this.error,
    this.statusFilter,
    this.startDate,
    this.endDate,
    this.currentPage = 1,
    this.pageSize = 10,
    this.totalItems = 0,
  });

  QuotationListState copyWith({
    List<Quotation>? quotations,
    bool? isLoading,
    String? error,
    String? statusFilter,
    DateTime? startDate,
    DateTime? endDate,
    int? currentPage,
    int? pageSize,
    int? totalItems,
  }) {
    return QuotationListState(
      quotations: quotations ?? this.quotations,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      statusFilter: statusFilter ?? this.statusFilter,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      totalItems: totalItems ?? this.totalItems,
    );
  }
}

// Notifier
class QuotationListNotifier extends StateNotifier<QuotationListState> {
  final QuotationApi quotationApi;
  final String? storeId;

  QuotationListNotifier({
    required this.quotationApi,
    required this.storeId,
  }) : super(const QuotationListState());

  Future<void> loadQuotations({
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final quotations = await quotationApi.getQuotations(
        storeId: storeId,
        status: status,
        startDate: startDate,
        endDate: endDate,
        page: state.currentPage,
        limit: state.pageSize,
      );

      state = state.copyWith(
        quotations: quotations,
        isLoading: false,
        statusFilter: status,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> setStatusFilter(String? status) async {
    state = state.copyWith(currentPage: 1);
    await loadQuotations(
      status: status,
      startDate: state.startDate,
      endDate: state.endDate,
    );
  }

  Future<void> setDateRange(DateTime? start, DateTime? end) async {
    state = state.copyWith(currentPage: 1);
    await loadQuotations(
      status: state.statusFilter,
      startDate: start,
      endDate: end,
    );
  }

  Future<void> goToPage(int page) async {
    state = state.copyWith(currentPage: page);
    await loadQuotations(
      status: state.statusFilter,
      startDate: state.startDate,
      endDate: state.endDate,
    );
  }

  Future<void> refreshQuotations() async {
    await loadQuotations(
      status: state.statusFilter,
      startDate: state.startDate,
      endDate: state.endDate,
    );
  }

  Future<void> deleteQuotation(String quotationId) async {
    try {
      await quotationApi.deleteQuotation(quotationId);
      state = state.copyWith(
        quotations: state.quotations
            .where((q) => q.id != quotationId)
            .toList(),
      );
    } catch (e) {
      state = state.copyWith(error: 'No se pudo eliminar la cotización');
    }
  }

  Future<bool> createQuotation({
    required String storeId,
    required List<Map<String, dynamic>> items,
    String? customerId,
  }) async {
    try {
      await quotationApi.createQuotation(
        storeId: storeId,
        customerId: customerId,
        items: items,
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: 'No se pudo crear la cotización: $e');
      return false;
    }
  }
}

// Provider
final quotationListProvider = StateNotifierProvider.family<
    QuotationListNotifier,
    QuotationListState,
    String?>((ref, storeId) {
  final quotationApi = ref.watch(quotationApiProvider);
  
  final notifier = QuotationListNotifier(
    quotationApi: quotationApi,
    storeId: storeId,
  );

  // Auto-load on first creation
  Future.microtask(() async {
    await notifier.loadQuotations();
  });

  return notifier;
});
