import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/providers/riverpod/product_notifier.dart';
import '../../shared/providers/riverpod/customer_notifier.dart';
import '../../shared/providers/riverpod/order_notifier.dart';
import '../../shared/providers/riverpod/quotation_list_notifier.dart';
import '../../shared/providers/riverpod/store_notifier.dart';
import '../../shared/providers/riverpod/currency_notifier.dart';
import '../../shared/providers/riverpod/order_form_notifier.dart';
import '../../shared/widgets/dashboard_layout.dart';

class CreateOrderPage extends ConsumerStatefulWidget {
  final bool isQuotation;
  
  const CreateOrderPage({
    super.key,
    this.isQuotation = false,
  });

  @override
  ConsumerState<CreateOrderPage> createState() => _CreateOrderPageState();
}

class _CreateOrderPageState extends ConsumerState<CreateOrderPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    // Load initial data using Riverpod
    Future.microtask(() {
      final productNotifier = ref.read(productProvider.notifier);
      final customerNotifier = ref.read(customerProvider.notifier);
      final formNotifier = ref.read(orderFormProvider.notifier);
      
      productNotifier.loadProductsForCurrentStore();
      customerNotifier.loadCustomers();
      
      // Limpiar el formulario completo para nueva orden
      formNotifier.clearCart();
      formNotifier.setSelectedCustomer(null);
      formNotifier.setFilteredProducts([]);
      formNotifier.setSearchQuery('');
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(currencyProvider); // Permite reconstruir cuando cambia la moneda
    
    return DashboardLayout(
      title: widget.isQuotation ? 'Nueva Cotización' : 'Nueva Orden',
      currentRoute: '/orders',
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
            Consumer(
              builder: (context, consumerRef, _) {
                final formState = consumerRef.watch(orderFormProvider);
                return TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre del producto...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: formState.hasSearchText
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            consumerRef.read(orderFormProvider.notifier).setFilteredProducts([]);
                            consumerRef.read(orderFormProvider.notifier).setSearchQuery('');
                          },
                        )
                      : const SizedBox.shrink(),
                  ),
                  onChanged: _searchProducts,
                );
              },
            ),
            const SizedBox(height: AppSizes.spacing16),
            
            // Lista de productos encontrados o todos los productos
            Expanded(
              child: _buildProductList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return Consumer(
      builder: (context, consumerRef, _) {
        final formState = consumerRef.watch(orderFormProvider);
        final productState = consumerRef.watch(productProvider);
        
        // Si hay búsqueda activa, mostrar productos filtrados
        // Si no, mostrar todos los productos disponibles
        final products = formState.hasSearchText 
            ? formState.filteredProducts 
            : productState.products;

        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(height: AppSizes.spacing16),
                Text(
                  formState.hasSearchText 
                      ? 'No hay productos que coincidan con tu búsqueda'
                      : 'No hay productos disponibles',
                  style: const TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
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
                leading: product['foto'] != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product['foto'],
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
                      'Stock: $stock | Precio: ${_formatCurrency((product['salePrice'] ?? product['price'] ?? 0) as num)}',
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
                        color: Theme.of(context).primaryColor,
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
      children: [
        // Selección de cliente
        _buildCustomerSelector(),
        
        const SizedBox(height: AppSizes.spacing16),
        
        // Carrito de compras
        Expanded(
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
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Cliente',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.spacing8),
            Consumer(
              builder: (context, consumerRef, _) {
                final formState = consumerRef.watch(orderFormProvider);
                final customer = formState.selectedCustomer;
                final allCustomers = consumerRef.watch(customerProvider).customers;

                if (customer != null) {
                  return Container(
                    padding: const EdgeInsets.all(AppSizes.spacing12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                      border: Border.all(color: Theme.of(context).primaryColor),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.person, color: Theme.of(context).primaryColor),
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
                          onPressed: () {
                            consumerRef.read(orderFormProvider.notifier).setSelectedCustomer(null);
                          },
                        ),
                      ],
                    ),
                  );
                }

                return Autocomplete<Map<String, dynamic>>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return allCustomers;
                    }
                    final query = textEditingValue.text.toLowerCase();
                    return allCustomers.where((c) {
                      final name = (c['name'] as String? ?? '').toLowerCase();
                      final phone = (c['phone'] as String? ?? '').toLowerCase();
                      final email = (c['email'] as String? ?? '').toLowerCase();
                      return name.contains(query) ||
                          phone.contains(query) ||
                          email.contains(query);
                    });
                  },
                  displayStringForOption: (option) => option['name'] as String,
                  onSelected: (option) {
                    consumerRef.read(orderFormProvider.notifier).setSelectedCustomer(option);
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: const InputDecoration(
                        hintText: 'Buscar cliente por nombre o teléfono...',
                        prefixIcon: Icon(Icons.search),
                      ),
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 200),
                          child: ListView.builder(
                            shrinkWrap: true,
                            padding: EdgeInsets.zero,
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options.elementAt(index);
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                  child: Icon(Icons.person, size: 16, color: Theme.of(context).primaryColor),
                                ),
                                title: Text(option['name'] as String),
                                subtitle: Text(option['phone'] as String? ?? ''),
                                dense: true,
                                onTap: () => onSelected(option),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
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
              child: Consumer(
                builder: (context, consumerRef, _) {
                  final formState = consumerRef.watch(orderFormProvider);
                  final items = formState.cartItems;

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
                                      '${_formatCurrency((item['price'] as num))} c/u',
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
                                  _formatCurrency(((item['price'] as num) * (item['quantity'] as int))),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
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
            // Solo mostrar método de pago si NO es cotización
            if (!widget.isQuotation)
              Consumer(
                builder: (context, consumerRef, _) {
                  final formState = consumerRef.watch(orderFormProvider);
                  final paymentMethod = formState.paymentMethod;

                  return Row(
                    children: [
                      const Text(
                        'Método de pago:',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(width: AppSizes.spacing8),
                      Expanded(
                        child: DropdownButton<String>(
                          value: paymentMethod,
                          isExpanded: true,
                          items: const [
                            DropdownMenuItem(value: 'efectivo', child: Text('Efectivo')),
                            DropdownMenuItem(value: 'tarjeta', child: Text('Tarjeta')),
                            DropdownMenuItem(value: 'qr', child: Text('Pago por QR')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              consumerRef.read(orderFormProvider.notifier).setPaymentMethod(value);
                            }
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            if (!widget.isQuotation)
            // Descuento
            Consumer(
              builder: (context, consumerRef, _) {
                final formState = consumerRef.watch(orderFormProvider);
                final discountType = formState.discountType;
                final discountValue = formState.discountValue;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Descuento:',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(width: AppSizes.spacing8),
                        ToggleButtons(
                          isSelected: [
                            discountType == null,
                            discountType == 'percent',
                            discountType == 'fixed',
                          ],
                          onPressed: (index) {
                            final notifier = consumerRef.read(orderFormProvider.notifier);
                            if (index == 0) {
                              notifier.setDiscount(type: null, value: 0.0);
                            } else if (index == 1) {
                              notifier.setDiscount(type: 'percent', value: discountType == 'percent' ? discountValue : 0.0);
                            } else {
                              notifier.setDiscount(type: 'fixed', value: discountType == 'fixed' ? discountValue : 0.0);
                            }
                          },
                          borderRadius: BorderRadius.circular(6),
                          constraints: const BoxConstraints(minHeight: 32, minWidth: 48),
                          textStyle: const TextStyle(fontSize: 12),
                          fillColor: Theme.of(context).primaryColor,
                          selectedColor: Colors.white,
                          selectedBorderColor: Theme.of(context).primaryColor,
                          children: const [
                            Text('Sin'),
                            Text('%'),
                            Text('\$'),
                          ],
                        ),
                        if (discountType != null) ...[
                          const SizedBox(width: AppSizes.spacing8),
                          SizedBox(
                            width: 90,
                            child: TextFormField(
                              key: ValueKey(discountType),
                              initialValue: discountValue > 0 ? discountValue.toStringAsFixed(discountType == 'percent' ? 0 : 2) : '',
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: InputDecoration(
                                hintText: discountType == 'percent' ? '0–100' : '0.00',
                                suffixText: discountType == 'percent' ? '%' : null,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                              ),
                              onChanged: (val) {
                                final parsed = double.tryParse(val) ?? 0.0;
                                consumerRef.read(orderFormProvider.notifier).setDiscount(type: discountType, value: parsed);
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSizes.spacing8),
                  ],
                );
              },
            ),
            Consumer(
              builder: (context, consumerRef, _) {
                // Watch orderFormProvider para que se reconstruya cuando cambien los items
                final formState = consumerRef.watch(orderFormProvider);
                final subtotal = formState.subtotal;
                final discountAmount = formState.discountAmount;
                final total = formState.total;

                return Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:'),
                        Text(_formatCurrency(subtotal)),
                      ],
                    ),
                    if (discountAmount > 0) ...[
                      const SizedBox(height: AppSizes.spacing4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            formState.discountType == 'percent'
                                ? 'Descuento (${formState.discountValue.toStringAsFixed(0)}%):' 
                                : 'Descuento:',
                            style: const TextStyle(color: Colors.green),
                          ),
                          Text(
                            '- ${_formatCurrency(discountAmount)}',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ],
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
                          _formatCurrency(total),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSizes.spacing16),
            Consumer(
              builder: (context, consumerRef, _) {
                final formState = consumerRef.watch(orderFormProvider);
                final items = formState.cartItems;
                final isCreating = formState.isCreatingOrder;

                return Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.go('/orders'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                        child: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacing8),
                    if (!widget.isQuotation)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: (items.isEmpty || isCreating) ? null : _createQuotation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[600],
                          ),
                          child: isCreating
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text('Realizar Cotización'),
                        ),
                      ),
                    if (!widget.isQuotation)
                      const SizedBox(width: AppSizes.spacing8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: (items.isEmpty || isCreating) ? null : _createOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        child: isCreating
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(widget.isQuotation ? 'Realizar Cotización' : 'Realizar Venta'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _searchProducts(String query) {
    final formNotifier = ref.read(orderFormProvider.notifier);
    formNotifier.setSearchQuery(query);
    
    if (query.trim().isEmpty) {
      formNotifier.setFilteredProducts([]);
      return;
    }

    final lowerQuery = query.toLowerCase();
    final productState = ref.read(productProvider);
    final products = productState.products;
    
    final filtered = products
        .where((product) {
          final name = (product['name'] as String).toLowerCase();
          final description = (product['description'] as String? ?? '').toLowerCase();
          return name.contains(lowerQuery) || description.contains(lowerQuery);
        })
        .toList();
    
    formNotifier.setFilteredProducts(filtered);
  }

  String _formatCurrency(num value) {
    final currencyNotifier = ref.read(currencyProvider.notifier);
    return '${currencyNotifier.symbol}${(value as double).toStringAsFixed(2)}';
  }

  void _addToCart(Map<String, dynamic> product) {
    final formNotifier = ref.read(orderFormProvider.notifier);
    final formState = ref.read(orderFormProvider);
    final currentItems = formState.cartItems;
    
    // Verificar si el producto ya está en el carrito
    final productId = product['_id'] ?? product['id'];
    final existingIndex = currentItems.indexWhere(
      (item) => (item['_id'] ?? item['id']) == productId,
    );

    if (existingIndex >= 0) {
      // Si ya existe, incrementar cantidad
      _increaseQuantity(existingIndex);
    } else {
      // Si no existe, agregarlo con cantidad 1
      final price = (product['salePrice'] ?? product['price'] ?? 0) as num;
      final stock = (product['stock'] ?? 0) as int;
      
      // Crear item para el carrito con ambas claves para compatibilidad
      final cartItem = {
        '_id': product['_id'],
        'id': product['_id'],
        'name': product['name'],
        'price': price.toDouble(),
        'stock': stock,
      };
      
      formNotifier.addToCart(cartItem);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product['name']} añadido al carrito'),
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _increaseQuantity(int index) {
    final formState = ref.read(orderFormProvider);
    final items = formState.cartItems;
    final item = items[index];
    final currentQuantity = item['quantity'] as int;
    final stock = item['stock'] as int;

    if (currentQuantity < stock) {
      final formNotifier = ref.read(orderFormProvider.notifier);
      formNotifier.updateQuantity(item['_id'] as String, currentQuantity + 1);
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
    final formState = ref.read(orderFormProvider);
    final items = formState.cartItems;
    final item = items[index];
    final currentQuantity = item['quantity'] as int;

    if (currentQuantity > 1) {
      final formNotifier = ref.read(orderFormProvider.notifier);
      formNotifier.updateQuantity(item['_id'] as String, currentQuantity - 1);
    } else {
      _removeFromCart(index);
    }
  }

  void _removeFromCart(int index) {
    final formState = ref.read(orderFormProvider);
    final items = formState.cartItems;
    final item = items[index];
    
    final formNotifier = ref.read(orderFormProvider.notifier);
    formNotifier.removeFromCart(item['_id'] as String);
  }

  Future<void> _createQuotation() async {
    final formState = ref.read(orderFormProvider);
    final cartItems = formState.cartItems;
    
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega productos antes de crear la cotización'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final formNotifier = ref.read(orderFormProvider.notifier);
    formNotifier.setIsCreatingOrder(true);

    try {
      // Preparar los items de la cotización
      final items = cartItems.map((item) {
        return {
          'productId': item['_id'],
          'quantity': item['quantity'],
          'price': item['price'],
        };
      }).toList();

      // Obtener el ID de la tienda actual
      final storeState = ref.read(storeProvider);
      final currentStoreId = storeState.currentStore?['_id'] as String?;
      
      if (currentStoreId == null) {
        throw Exception('No hay tienda seleccionada');
      }

      // Crear la cotización
      final quotationNotifier = ref.read(quotationListProvider(currentStoreId).notifier);
      final customerId = formState.selectedCustomer != null 
        ? formState.selectedCustomer!['_id'] as String 
        : null;
      
      final success = await quotationNotifier.createQuotation(
        storeId: currentStoreId,
        items: items,
        customerId: customerId,
        discountAmount: formState.discountAmount,
      );

      // Verificar que el widget todavía está montado antes de actualizar UI
      if (!mounted) return;

      if (success) {
        // Mostrar mensaje de éxito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cotización creada exitosamente!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Redirigir a la página de cotizaciones
        // (la lista ya se actualizó directamente en el notifier)
        if (mounted) {
          context.go('/quotations');
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo crear la cotización'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Verificar que el widget todavía está montado antes de mostrar error
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo crear la cotización: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      formNotifier.setIsCreatingOrder(false);
    }
  }

  Future<void> _createOrder() async {
    final formState = ref.read(orderFormProvider);
    final cartItems = formState.cartItems;
    
    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega productos antes de crear la orden'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final formNotifier = ref.read(orderFormProvider.notifier);
    formNotifier.setIsCreatingOrder(true);

    try {
      // Preparar los items de la orden
      final items = cartItems.map((item) {
        return {
          'productId': item['_id'],
          'quantity': item['quantity'],
          'price': item['price'],
        };
      }).toList();

      // Obtener el ID de la tienda actual
      final storeState = ref.read(storeProvider);
      final currentStoreId = storeState.currentStore?['_id'] as String?;
      
      if (currentStoreId == null) {
        throw Exception('No hay tienda seleccionada');
      }

      // Crear la orden
      final orderNotifier = ref.read(orderProvider.notifier);
      final createdOrder = await orderNotifier.createOrder(
        storeId: currentStoreId,
        items: items,
        paymentMethod: formState.paymentMethod,
        customerId: formState.selectedCustomer?['_id'] as String?,
        discountType: formState.discountType,
        discountValue: formState.discountValue,
      );

      // Verificar que el widget todavía está montado antes de actualizar UI
      if (!mounted) return;

      if (createdOrder != null) {
        final receiptNumber = createdOrder['receiptNumber'] as String? ?? 'N/A';
        
        // Mostrar diálogo con número de comprobante
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: 450,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // HEADER
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    padding: const EdgeInsets.all(AppSizes.spacing20),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: AppSizes.spacing12),
                        const Expanded(
                          child: Text(
                            '✓ Orden Creada Exitosamente',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // CONTENT
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.spacing20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Tu orden ha sido creada correctamente.'),
                        const SizedBox(height: AppSizes.spacing20),
                        Container(
                          padding: const EdgeInsets.all(AppSizes.spacing12),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Número de Comprobante:',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: AppSizes.spacing8),
                              Text(
                                receiptNumber,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                  fontFamily: 'Courier',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // FOOTER
                  Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.border, width: 1)),
                    ),
                    padding: const EdgeInsets.all(AppSizes.spacing16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        // Esperar a que se cierre el diálogo
        await Future.delayed(const Duration(milliseconds: 500));

        // Recargar productos para actualizar el stock (FORZAR recarga desde servidor)
        final productNotifier = ref.read(productProvider.notifier);
        await productNotifier.loadProductsForCurrentStore(forceRefresh: true);

        // Redirigir a la página de órdenes
        if (mounted) {
          context.go('/orders');
        }
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
    } finally {
      formNotifier.setIsCreatingOrder(false);
    }
  }
}

