import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/providers/product_provider.dart';
import '../../shared/providers/customer_provider.dart';
import '../../shared/providers/order_provider.dart';
import '../../shared/providers/store_provider.dart';
import '../../shared/widgets/dashboard_layout.dart';

class CreateOrderPage extends ConsumerStatefulWidget {
  const CreateOrderPage({super.key});

  @override
  ConsumerState<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends ConsumerState<CreateOrderPage> {
  late ValueNotifier<List<Map<String, dynamic>>> _filteredProducts;
  late ValueNotifier<List<Map<String, dynamic>>> _cartItems;
  late ValueNotifier<Map<String, dynamic>?> _selectedCustomer;
  late ValueNotifier<String> _paymentMethod;
  late ValueNotifier<bool> _hasSearchText;

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Initialize ValueNotifiers
    _filteredProducts = ValueNotifier<List<Map<String, dynamic>>>([]);
    _cartItems = ValueNotifier<List<Map<String, dynamic>>>([]);
    _selectedCustomer = ValueNotifier<Map<String, dynamic>?>(null);
    _paymentMethod = ValueNotifier<String>('efectivo');
    _hasSearchText = ValueNotifier<bool>(false);
    
    // Load initial data using Riverpod
    Future.microtask(() {
      final productNotifier = ref.read(productProvider.notifier);
      final customerNotifier = ref.read(customerProvider.notifier);
      
      productNotifier.loadProductsForCurrentStore();
      customerNotifier.loadCustomers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Nueva Orden',
      currentRoute: '/orders',
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Panel izquierdo - Búsqueda y selección de productos
            Expanded(
              flex: 3,
              child: _buildProductSearch(),
            ),
            
            const SizedBox(width: AppSizes.spacing16),
            
            // Panel derecho - Carrito y resumen
            Expanded(
              flex: 2,
              child: _buildCartAndCheckout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductSearch() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Buscar Productos',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacing16),
            
            // Buscador de productos
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar por nombre del producto...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: ValueListenableBuilder<bool>(
                  valueListenable: _hasSearchText,
                  builder: (context, hasText, _) => hasText
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filteredProducts.value = [];
                          _hasSearchText.value = false;
                        },
                      )
                    : const SizedBox.shrink(),
                ),
              ),
              onChanged: _searchProducts,
            ),
            const SizedBox(height: AppSizes.spacing16),
            
            // Lista de productos encontrados
            SizedBox(
              height: 400,
              child: _buildProductList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: _filteredProducts,
      builder: (context, products, _) {
        if (products.isEmpty) {
          return const Center(
            child: Text(
              'Busca productos por nombre para agregarlos a la orden',
              style: TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          );
        }

        return ListView.builder(
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            final stock = product['stock'] as int? ?? 0;
            final isOutOfStock = stock <= 0;

            return Card(
              margin: const EdgeInsets.only(bottom: AppSizes.spacing8),
              child: ListTile(
                leading: product['image'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product['image'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.inventory_2_outlined, size: 50),
                        ),
                      )
                    : const Icon(Icons.inventory_2_outlined, size: 50),
                title: Text(
                  product['name'] as String,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isOutOfStock ? AppColors.textSecondary : AppColors.textPrimary,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product['description'] != null)
                      Text(
                        product['description'] as String,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      'Stock: $stock | Precio: \$${((product['salePrice'] ?? product['price'] ?? 0) as num).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isOutOfStock ? Colors.red : AppColors.textSecondary,
                        fontWeight: isOutOfStock ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                trailing: isOutOfStock
                    ? const Chip(
                        label: Text('Sin stock'),
                        backgroundColor: Colors.red,
                        labelStyle: TextStyle(color: Colors.white),
                      )
                    : IconButton(
                        icon: const Icon(Icons.add_shopping_cart),
                        color: AppColors.primary,
                        onPressed: () => _addToCart(product),
                      ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCartAndCheckout() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selección de cliente
        _buildCustomerSelector(),
        
        const SizedBox(height: AppSizes.spacing16),
        
        // Carrito de compras
        SizedBox(
          height: 300,
          child: _buildCart(),
        ),
        
        const SizedBox(height: AppSizes.spacing16),
        
        // Método de pago y total
        _buildCheckoutSummary(),
      ],
    );
  }

  Widget _buildCustomerSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Cliente',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  icon: const Icon(Icons.search),
                  label: const Text('Buscar'),
                  onPressed: _showCustomerSearch,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing8),
            ValueListenableBuilder<Map<String, dynamic>?>(
              valueListenable: _selectedCustomer,
              builder: (context, customer, _) {
                if (customer == null) {
                  return Container(
                    padding: const EdgeInsets.all(AppSizes.spacing12),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.person_outline, color: AppColors.textSecondary),
                        SizedBox(width: AppSizes.spacing8),
                        Text(
                          'Cliente general',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  padding: const EdgeInsets.all(AppSizes.spacing12),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                    border: Border.all(color: AppColors.primary),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person, color: AppColors.primary),
                      const SizedBox(width: AppSizes.spacing8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer['name'] as String,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            if (customer['phone'] != null)
                              Text(
                                customer['phone'] as String,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        iconSize: 20,
                        onPressed: () => _selectedCustomer.value = null,
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Carrito',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            
            Expanded(
              child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: _cartItems,
                builder: (context, items, _) {
                  if (items.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 64,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(height: AppSizes.spacing16),
                          Text(
                            'Carrito vacío',
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: AppSizes.spacing8),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.spacing8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['name'] as String,
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      '\$${(item['price'] as num).toStringAsFixed(2)} c/u',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.remove_circle_outline),
                                    onPressed: () => _decreaseQuantity(index),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      '${item['quantity']}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.add_circle_outline),
                                    onPressed: () => _increaseQuantity(index),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              ),
                              const SizedBox(width: AppSizes.spacing8),
                              SizedBox(
                                width: 80,
                                child: Text(
                                  '\$${((item['price'] as num) * (item['quantity'] as int)).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline),
                                color: Colors.red,
                                onPressed: () => _removeFromCart(index),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutSummary() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Método de pago:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: AppSizes.spacing8),
                Expanded(
                  child: ValueListenableBuilder<String>(
                    valueListenable: _paymentMethod,
                    builder: (context, paymentMethod, _) => DropdownButton<String>(
                      value: paymentMethod,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                        DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                        DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
                      ],
                      onChanged: (value) {
                        if (value != null) _paymentMethod.value = value;
                      },
                    ),
                  ),
                ),
              ],
            ),
            const Divider(),
            ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: _cartItems,
              builder: (context, items, _) {
                final subtotal = _calculateSubtotal();
                final total = subtotal;

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:'),
                        Text('\$${subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: AppSizes.spacing8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total:',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '\$${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSizes.spacing16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _clearCart,
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: AppSizes.spacing8),
                Expanded(
                  child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                    valueListenable: _cartItems,
                    builder: (context, items, _) => ElevatedButton(
                      onPressed: items.isEmpty ? null : _createOrder,
                      child: const Text('Crear Orden'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _searchProducts(String query) {
    _hasSearchText.value = query.trim().isNotEmpty;
    
    if (query.trim().isEmpty) {
      _filteredProducts.value = [];
      return;
    }

    final lowerQuery = query.toLowerCase();
    final productState = ref.read(productProvider);
    final products = productState.maybeWhen(
      data: (products) => products,
      orElse: () => [],
    );
    
    _filteredProducts.value = products
        .where((product) {
          final name = (product['name'] as String).toLowerCase();
          final description = (product['description'] as String? ?? '').toLowerCase();
          return name.contains(lowerQuery) || description.contains(lowerQuery);
        })
        .toList();
  }

  void _addToCart(Map<String, dynamic> product) {
    // Verificar si el producto ya está en el carrito
    final currentItems = _cartItems.value;
    final existingIndex = currentItems.indexWhere(
      (item) => item['_id'] == product['_id'],
    );

    if (existingIndex >= 0) {
      // Si ya existe, incrementar cantidad
      _increaseQuantity(existingIndex);
    } else {
      // Si no existe, agregarlo con cantidad 1
      final price = (product['salePrice'] ?? product['price'] ?? 0) as num;
      final stock = (product['stock'] ?? 0) as int;
      
      final newItems = [...currentItems];
      newItems.add({
        '_id': product['_id'],
        'name': product['name'],
        'price': price.toDouble(),
        'quantity': 1,
        'stock': stock,
      });
      _cartItems.value = newItems;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product['name']} añadido al carrito'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _increaseQuantity(int index) {
    final items = _cartItems.value;
    final item = items[index];
    final currentQuantity = item['quantity'] as int;
    final stock = item['stock'] as int;

    if (currentQuantity < stock) {
      final newItems = [...items];
      newItems[index] = {...item, 'quantity': currentQuantity + 1};
      _cartItems.value = newItems;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay más unidades disponibles de ${item['name']}'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  void _decreaseQuantity(int index) {
    final items = _cartItems.value;
    final item = items[index];
    final currentQuantity = item['quantity'] as int;

    if (currentQuantity > 1) {
      final newItems = [...items];
      newItems[index] = {...item, 'quantity': currentQuantity - 1};
      _cartItems.value = newItems;
    } else {
      _removeFromCart(index);
    }
  }

  void _removeFromCart(int index) {
    final items = _cartItems.value;
    final newItems = [...items];
    newItems.removeAt(index);
    _cartItems.value = newItems;
  }

  void _clearCart() {
    _cartItems.value = [];
    _selectedCustomer.value = null;
    _paymentMethod.value = 'efectivo';
  }

  double _calculateSubtotal() {
    return _cartItems.value.fold(0.0, (sum, item) {
      return sum + ((item['price'] as num) * (item['quantity'] as int));
    });
  }

  void _showCustomerSearch() {
    final customerSearchController = TextEditingController();
    final filteredCustomers = ValueNotifier<List<Map<String, dynamic>>>([]);

    void searchCustomers(String query) {
      if (query.trim().isEmpty) {
        filteredCustomers.value = [];
        return;
      }

      final lowerQuery = query.toLowerCase();
      final customerState = ref.read(customerProvider);
      final customers = customerState.maybeWhen(
        data: (customers) => customers,
        orElse: () => [],
      );
      
      filteredCustomers.value = customers
          .where((customer) {
            final name = (customer['name'] as String).toLowerCase();
            final phone = (customer['phone'] as String? ?? '').toLowerCase();
            final email = (customer['email'] as String? ?? '').toLowerCase();
            return name.contains(lowerQuery) || 
                   phone.contains(lowerQuery) || 
                   email.contains(lowerQuery);
          })
          .toList();
    }

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        child: Container(
          width: 500,
          padding: const EdgeInsets.all(AppSizes.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Buscar Cliente',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(dialogContext).pop(),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spacing16),
              TextField(
                controller: customerSearchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar por nombre, teléfono o email...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: searchCustomers,
                autofocus: true,
              ),
              const SizedBox(height: AppSizes.spacing16),
              SizedBox(
                height: 300,
                child: ValueListenableBuilder<List<Map<String, dynamic>>>(
                  valueListenable: filteredCustomers,
                  builder: (context, customers, _) {
                    if (customers.isEmpty) {
                      return const Center(
                        child: Text(
                          'Busca clientes por nombre, teléfono o email',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: customers.length,
                      itemBuilder: (context, index) {
                        final customer = customers[index];
                        return ListTile(
                          leading: const CircleAvatar(
                            child: Icon(Icons.person),
                          ),
                          title: Text(customer['name'] as String),
                          subtitle: Text(
                            customer['phone'] as String? ?? 'Sin teléfono',
                          ),
                          onTap: () {
                            _selectedCustomer.value = customer;
                            Navigator.of(dialogContext).pop();
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createOrder() async {
    if (_cartItems.value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega productos antes de crear la orden'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Preparar los items de la orden
      final items = _cartItems.value.map((item) {
        return {
          'productId': item['_id'],
          'quantity': item['quantity'],
          'price': item['price'],
        };
      }).toList();

      // Obtener el ID de la tienda actual
      final storeState = ref.read(storeProvider);
      final currentStoreId = storeState.maybeWhen(
        data: (store) => store?['_id'] as String?,
        orElse: () => null,
      );
      
      if (currentStoreId == null) {
        throw Exception('No hay tienda seleccionada');
      }

      // Crear la orden
      final orderNotifier = ref.read(orderProvider.notifier);
      final success = await orderNotifier.createOrder(
        storeId: currentStoreId,
        items: items,
        paymentMethod: _paymentMethod.value,
        customerId: _selectedCustomer.value?['_id'] as String?,
      );

      // Verificar que el widget todavía está montado antes de actualizar UI
      if (!mounted) return;

      if (success) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Orden creada exitosamente! Puedes crear otra orden inmediatamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Limpiar el carrito para crear una nueva orden
        _clearCart();
        
        // Recargar productos para actualizar el stock
        final productNotifier = ref.read(productProvider.notifier);
        await productNotifier.loadProductsForCurrentStore();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo crear la orden'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Verificar que el widget todavía está montado antes de mostrar error
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo crear la orden: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
