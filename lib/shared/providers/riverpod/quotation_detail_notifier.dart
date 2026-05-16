import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bellezapp_web/shared/models/quotation.dart';
import 'package:bellezapp_web/shared/providers/quotation_api.dart';

// State class
class QuotationDetailState {
  final Quotation? quotation;
  final bool isLoading;
  final String? error;

  const QuotationDetailState({
    this.quotation,
    this.isLoading = false,
    this.error,
  });

  QuotationDetailState copyWith({
    Quotation? quotation,
    bool? isLoading,
    String? error,
  }) {
    return QuotationDetailState(
      quotation: quotation ?? this.quotation,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Notifier
class QuotationDetailNotifier extends StateNotifier<QuotationDetailState> {
  final QuotationApi quotationApi;
  final String quotationId;

  QuotationDetailNotifier({
    required this.quotationApi,
    required this.quotationId,
  }) : super(const QuotationDetailState(isLoading: true));

  Future<void> loadQuotation() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final quotation = await quotationApi.getQuotation(quotationId);
      state = state.copyWith(
        quotation: quotation,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<bool> convertToOrder() async {
    if (state.quotation == null) return false;

    state = state.copyWith(isLoading: true, error: null);
    try {
      await quotationApi.convertQuotationToOrder(
        state.quotation!.id ?? 'unknown',
      );
      // Recargar la cotización para obtener el estado actualizado (status: 'converted')
      await loadQuotation();
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'No se pudo convertir la cotización a pedido: $e',
      );
      return false;
    }
  }

  Future<void> refreshQuotation() async {
    await loadQuotation();
  }
}

// Provider
final quotationDetailProvider = StateNotifierProvider.family<
    QuotationDetailNotifier,
    QuotationDetailState,
    String>((ref, quotationId) {
  final quotationApi = ref.watch(quotationApiProvider);
  
  final notifier = QuotationDetailNotifier(
    quotationApi: quotationApi,
    quotationId: quotationId,
  );

  // Auto-load on first creation - usar .then() en lugar de Future.microtask
  notifier.loadQuotation();

  return notifier;
});
