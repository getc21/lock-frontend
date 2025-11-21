import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

/// Estado del formulario de creación de órdenes
class OrderFormState {
  final List<Map<String, dynamic>> filteredProducts;
  final List<Map<String, dynamic>> cartItems;
  final Map<String, dynamic>? selectedCustomer;
  final String paymentMethod;
  final bool hasSearchText;
  final bool isCreatingOrder;
  final String searchQuery;

  OrderFormState({
    this.filteredProducts = const [],
    this.cartItems = const [],
    this.selectedCustomer,
    this.paymentMethod = 'efectivo',
    this.hasSearchText = false,
    this.isCreatingOrder = false,
    this.searchQuery = '',
  });

  OrderFormState copyWith({
    List<Map<String, dynamic>>? filteredProducts,
    List<Map<String, dynamic>>? cartItems,
    Map<String, dynamic>? selectedCustomer,
    String? paymentMethod,
    bool? hasSearchText,
    bool? isCreatingOrder,
    String? searchQuery,
  }) {
    return OrderFormState(
      filteredProducts: filteredProducts ?? this.filteredProducts,
      cartItems: cartItems ?? this.cartItems,
      selectedCustomer: selectedCustomer ?? this.selectedCustomer,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      hasSearchText: hasSearchText ?? this.hasSearchText,
      isCreatingOrder: isCreatingOrder ?? this.isCreatingOrder,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Validar si se puede crear la orden
  bool get canSubmit {
    return selectedCustomer != null &&
        cartItems.isNotEmpty &&
        cartItems.every((item) => (item['quantity'] as num?)?.toInt() ?? 0 > 0);
  }

  /// Obtener el total de la orden
  double get total {
    return cartItems.fold<double>(
      0.0,
      (sum, item) {
        final price = (item['price'] as num?)?.toDouble() ?? 0.0;
        final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
        return sum + (price * quantity);
      },
    );
  }
}

/// Notifier para manejar el estado del formulario de órdenes
class OrderFormNotifier extends StateNotifier<OrderFormState> {
  OrderFormNotifier() : super(OrderFormState());

  /// Actualizar productos filtrados
  void setFilteredProducts(List<Map<String, dynamic>> products) {
    state = state.copyWith(filteredProducts: products);
  }

  /// Agregar producto al carrito
  void addToCart(Map<String, dynamic> product) {
    final productId = product['id'] ?? product['_id'] ?? '';
    final existingIndex = state.cartItems.indexWhere(
      (item) => (item['id'] ?? item['_id']) == productId,
    );

    List<Map<String, dynamic>> updatedCart = [...state.cartItems];
    if (existingIndex >= 0) {
      // Incrementar cantidad si ya existe
      updatedCart[existingIndex] = {
        ...updatedCart[existingIndex],
        'quantity': ((updatedCart[existingIndex]['quantity'] as num?)?.toInt() ?? 0) + 1,
      };
    } else {
      // Agregar nuevo producto
      updatedCart.add({...product, 'quantity': 1});
    }

    state = state.copyWith(cartItems: updatedCart);
  }

  /// Remover producto del carrito
  void removeFromCart(String productId) {
    state = state.copyWith(
      cartItems: state.cartItems
          .where((item) => (item['id'] ?? item['_id']) != productId)
          .toList(),
    );
  }

  /// Actualizar cantidad de un producto en el carrito
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    state = state.copyWith(
      cartItems: state.cartItems.map((item) {
        if ((item['id'] ?? item['_id']) == productId) {
          return {...item, 'quantity': quantity};
        }
        return item;
      }).toList(),
    );
  }

  /// Seleccionar cliente
  void setSelectedCustomer(Map<String, dynamic>? customer) {
    state = state.copyWith(selectedCustomer: customer);
  }

  /// Cambiar método de pago
  void setPaymentMethod(String method) {
    state = state.copyWith(paymentMethod: method);
  }

  /// Actualizar búsqueda
  void setSearchQuery(String query) {
    state = state.copyWith(
      searchQuery: query,
      hasSearchText: query.isNotEmpty,
    );
  }

  /// Establecer estado de creación
  void setIsCreatingOrder(bool isCreating) {
    state = state.copyWith(isCreatingOrder: isCreating);
  }

  /// Limpiar carrito
  void clearCart() {
    state = state.copyWith(
      cartItems: [],
      selectedCustomer: null,
      paymentMethod: 'efectivo',
      searchQuery: '',
    );
  }
}

/// Provider del formulario de órdenes
final orderFormProvider =
    StateNotifierProvider<OrderFormNotifier, OrderFormState>((ref) {
  return OrderFormNotifier();
});
