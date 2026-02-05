import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bellezapp_web/shared/models/quotation.dart';
import 'package:bellezapp_web/shared/providers/quotation_api.dart';

// Form state
class QuotationFormState {
  final QuotationItem? selectedCustomer;
  final List<QuotationItem> items;
  final double discountAmount;
  final String? notes;
  final bool isLoading;
  final String? error;
  final String? successMessage;

  const QuotationFormState({
    this.selectedCustomer,
    this.items = const [],
    this.discountAmount = 0,
    this.notes,
    this.isLoading = false,
    this.error,
    this.successMessage,
  });

  QuotationFormState copyWith({
    QuotationItem? selectedCustomer,
    List<QuotationItem>? items,
    double? discountAmount,
    String? notes,
    bool? isLoading,
    String? error,
    String? successMessage,
  }) {
    return QuotationFormState(
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      items: items ?? this.items,
      discountAmount: discountAmount ?? this.discountAmount,
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      successMessage: successMessage,
    );
  }

  double get subtotal => items.fold<double>(
    0,
    (sum, item) => sum + (item.quantity * item.price),
  );

  double get total => (subtotal - discountAmount).clamp(0, double.infinity);
}

// Notifier
class QuotationFormNotifier extends StateNotifier<QuotationFormState> {
  final QuotationApi quotationApi;
  final String? storeId;

  QuotationFormNotifier({
    required this.quotationApi,
    required this.storeId,
  }) : super(const QuotationFormState());

  void addItem(QuotationItem item) {
    final items = [...state.items];
    
    // Check if item already exists
    final existingIndex = items.indexWhere((i) => i.productId == item.productId);
    
    if (existingIndex >= 0) {
      // Update quantity if product already exists
      items[existingIndex] = QuotationItem(
        productId: item.productId,
        productName: item.productName,
        quantity: items[existingIndex].quantity + item.quantity,
        price: item.price,
      );
    } else {
      items.add(item);
    }

    state = state.copyWith(items: items, error: null);
  }

  void removeItem(String productId) {
    final items = state.items
        .where((item) => item.productId != productId)
        .toList();
    state = state.copyWith(items: items);
  }

  void updateItemQuantity(String productId, double quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final items = state.items.map((item) {
      if (item.productId == productId) {
        return QuotationItem(
          productId: item.productId,
          productName: item.productName,
          quantity: quantity.toInt(),
          price: item.price,
        );
      }
      return item;
    }).toList();

    state = state.copyWith(items: items);
  }

  void setDiscountAmount(double discount) {
    if (discount >= 0 && discount <= state.subtotal) {
      state = state.copyWith(discountAmount: discount);
    }
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void clearForm() {
    state = const QuotationFormState();
  }

  Future<Quotation?> submitQuotation({
    required String customerId,
    required String customerName,
  }) async {
    if (state.items.isEmpty) {
      state = state.copyWith(error: 'La cotización debe tener al menos un artículo');
      return null;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final quotation = await quotationApi.createQuotation(
        storeId: storeId ?? 'default',
        customerId: customerId,
        items: state.items
            .map((item) => {
              'productId': item.productId,
              'productName': item.productName,
              'quantity': item.quantity,
              'price': item.price,
            })
            .toList(),
        discountAmount: state.discountAmount,
        notes: state.notes,
      );

      state = state.copyWith(
        isLoading: false,
        successMessage: 'Cotización creada exitosamente',
      );

      clearForm();
      return quotation;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error al crear la cotización: ${e.toString()}',
      );
      return null;
    }
  }
}

// Provider
final quotationFormProvider = StateNotifierProvider.family<
    QuotationFormNotifier,
    QuotationFormState,
    String?>((ref, storeId) {
  final quotationApi = ref.watch(quotationApiProvider);
  
  return QuotationFormNotifier(
    quotationApi: quotationApi,
    storeId: storeId,
  );
});
