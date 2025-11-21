import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/providers/riverpod/customer_notifier.dart';
import '../../shared/providers/riverpod/order_notifier.dart';
import '../../shared/providers/riverpod/store_notifier.dart';

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized && mounted) {
        _hasInitialized = true;
        
        // PARALLEL LOADING: Load customers and orders simultaneously
        // Both are needed for displaying customer stats and order history
        final futures = <Future>[];
        
        final customerState = ref.read(customerProvider);
        if (customerState.customers.isEmpty) {
          futures.add(ref.read(customerProvider.notifier).loadCustomersForCurrentStore());
        }
        
        final orderState = ref.read(orderProvider);
        if (orderState.orders.isEmpty) {
          futures.add(ref.read(orderProvider.notifier).loadOrdersForCurrentStore());
        }
        
        // Execute both in parallel
        if (futures.isNotEmpty) {
          Future.wait(futures);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final customerState = ref.watch(customerProvider);
    
    // Recargar clientes cuando cambie la tienda
    ref.listen(storeProvider, (previous, next) {
      if (previous?.currentStore?['_id'] != next.currentStore?['_id']) {
        ref.read(customerProvider.notifier).loadCustomersForCurrentStore();
        ref.read(orderProvider.notifier).loadOrdersForCurrentStore();
      }
    });
    
    return DashboardLayout(
      title: 'Clientes',
      currentRoute: '/customers',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!customerState.isLoading) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar clientes...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.spacing16),
                ElevatedButton.icon(
                  onPressed: () => _showCustomerDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Nuevo Cliente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing24),
          ],
          if (customerState.isLoading)
            SizedBox(
              height: 600,
              child: Card(
                child: Center(
                  child: LoadingIndicator(message: 'Cargando clientes...'),
                ),
              ),
            )
          else if (customerState.customers.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacing24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
                    const SizedBox(height: AppSizes.spacing16),
                    const Text('No hay clientes disponibles', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                    const SizedBox(height: AppSizes.spacing8),
                    ElevatedButton.icon(
                      onPressed: () => _showCustomerDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar Primer Cliente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacing16),
                child: SizedBox(
                  height: 600,
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 1000,
                    columns: const [
                      DataColumn2(label: Text('Cliente'), size: ColumnSize.L),
                      DataColumn2(label: Text('Email'), size: ColumnSize.L),
                      DataColumn2(label: Text('Teléfono'), size: ColumnSize.M),
                      DataColumn2(label: Text('Puntos'), size: ColumnSize.S),
                      DataColumn2(label: Text('Acciones'), size: ColumnSize.M),
                    ],
                    rows: _buildCustomerRows(customerState.customers),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<DataRow2> _buildCustomerRows(List<dynamic> customers) {
    return customers
        .where((c) =>
            _searchQuery.isEmpty ||
            (c['name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (c['email'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList()
        .map((customer) {
      final points = customer['loyaltyPoints'] as int? ?? 0;
      final isVIP = points >= 100;
      final fullName = customer['name']?.toString() ?? 'Sin nombre';
      return DataRow2(
        onTap: () => context.go('/customers/${customer['_id']}'),
        cells: [
          DataCell(
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                      child: Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'C',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                    if (isVIP)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: AppColors.warning,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.star,
                            size: 12,
                            color: AppColors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: AppSizes.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        fullName,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      if (isVIP)
                        const Text(
                          'Cliente VIP',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.warning,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          DataCell(Text(customer['email'] ?? 'Sin email')),
          DataCell(Text(customer['phone'] ?? 'Sin teléfono')),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing8,
                vertical: AppSizes.spacing4,
              ),
              decoration: BoxDecoration(
                color: AppColors.info.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: Text(
                '$points pts',
                style: const TextStyle(
                  color: AppColors.info,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, size: 20),
                  onPressed: () => _showCustomerDetails(customer),
                  tooltip: 'Ver detalles',
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _showCustomerDialog(customer: customer),
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _confirmDeleteCustomer(customer),
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  void _showCustomerDialog({Map<String, dynamic>? customer}) {
    final isEditing = customer != null;
    final nameController = TextEditingController(text: customer?['name'] ?? '');
    final emailController = TextEditingController(text: customer?['email'] ?? '');
    final phoneController = TextEditingController(text: customer?['phone'] ?? '');
    final addressController = TextEditingController(text: customer?['address'] ?? '');
    final notesController = TextEditingController(text: customer?['notes'] ?? '');
    final isLoading = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isEditing ? 'Editar Cliente: ${customer['name']}' : 'Nuevo Cliente'),
        content: SizedBox(
          width: 500,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    hintText: 'Ingrese el nombre completo',
                    border: OutlineInputBorder(),
                  ),
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AppSizes.spacing16),
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'ejemplo@correo.com',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: AppSizes.spacing16),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono',
                    hintText: '591-XXXXXXXX',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: AppSizes.spacing16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    hintText: 'Dirección del cliente',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: AppSizes.spacing16),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notas',
                    hintText: 'Información adicional',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              nameController.dispose();
              emailController.dispose();
              phoneController.dispose();
              addressController.dispose();
              notesController.dispose();
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancelar'),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isLoading,
            builder: (ctx, loading, _) => ElevatedButton(
              onPressed: loading
                  ? null
                  : () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          const SnackBar(
                            content: Text('El nombre es requerido'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      if (dialogContext.mounted) {
                        isLoading.value = true;
                      }

                      try {
                        bool success;
                        if (isEditing) {
                          success = await ref
                              .read(customerProvider.notifier)
                              .updateCustomer(
                                id: customer['_id'],
                                name: name,
                                email: emailController.text.trim().isNotEmpty
                                    ? emailController.text.trim()
                                    : null,
                                phone: phoneController.text.trim().isNotEmpty
                                    ? phoneController.text.trim()
                                    : null,
                                address:
                                    addressController.text.trim().isNotEmpty
                                        ? addressController.text.trim()
                                        : null,
                                notes: notesController.text.trim().isNotEmpty
                                    ? notesController.text.trim()
                                    : null,
                              );
                        } else {
                          success = await ref
                              .read(customerProvider.notifier)
                              .createCustomer(
                                name: name,
                                email: emailController.text.trim().isNotEmpty
                                    ? emailController.text.trim()
                                    : null,
                                phone: phoneController.text.trim().isNotEmpty
                                    ? phoneController.text.trim()
                                    : null,
                                address:
                                    addressController.text.trim().isNotEmpty
                                        ? addressController.text.trim()
                                        : null,
                                notes: notesController.text.trim().isNotEmpty
                                    ? notesController.text.trim()
                                    : null,
                              );
                        }

                        if (success) {
                          nameController.dispose();
                          emailController.dispose();
                          phoneController.dispose();
                          addressController.dispose();
                          notesController.dispose();

                          if (dialogContext.mounted) {
                            Navigator.of(dialogContext).pop();
                          }
                        }
                      } finally {
                        if (dialogContext.mounted) {
                          isLoading.value = false;
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(dialogContext).primaryColor,
              ),
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(isEditing ? 'Actualizar' : 'Crear'),
            ),
          ),
        ],
      ),
    );
  }

  void _showCustomerDetails(Map<String, dynamic> customer) {
    final fullName = customer['name']?.toString() ?? 'Sin nombre';
    final customerId = customer['_id']?.toString() ?? customer['id']?.toString();
    final email = customer['email']?.toString() ?? 'Sin email';
    final phone = customer['phone']?.toString() ?? 'Sin teléfono';
    final address = customer['address']?.toString() ?? 'No especificada';
    final notes = customer['notes']?.toString() ?? '';
    final createdAt = customer['createdAt'] != null
        ? DateTime.parse(customer['createdAt'].toString())
        : DateTime.now();
    final lastPurchase = customer['lastPurchase'] != null
        ? DateTime.parse(customer['lastPurchase'].toString())
        : null;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: null,
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: 600,
          height: 700,
          child: Consumer(
            builder: (ctx, ref, child) {
              // Obtener órdenes cargadas
              final orderState = ref.watch(orderProvider);
              
              // Inicializar carga de órdenes si no están cargadas
              if (orderState.orders.isEmpty) {
                ref.read(orderProvider.notifier).loadOrdersForCurrentStore();
              }
              
              // Filtrar órdenes del cliente actual
              // El customerId en la orden es un objeto con _id, name, phone
              final customerOrders = orderState.orders
                  .where((order) {
                    final orderCustomerId = order['customerId']?['_id'];
                    return orderCustomerId == customerId;
                  })
                  .toList();
              
              // Calcular estadísticas
              double totalSpent = 0.0;
              for (var order in customerOrders) {
                // El campo del monto es 'totalOrden' 
                final total = order['totalOrden'] ?? 0.0;
                totalSpent += (total is String ? double.tryParse(total) : total as double?) ?? 0.0;
              }
              
              final totalOrders = customerOrders.length;
              
              // Intentar obtener loyaltyPoints del cliente
              dynamic loyaltyPointsVal = customer['loyaltyPoints'] ?? customer['loyalty_points'] ?? 0;
              final loyaltyPoints = (loyaltyPointsVal is String ? int.tryParse(loyaltyPointsVal) : loyaltyPointsVal as int?) ?? 0;
              
              final isVIP = loyaltyPoints >= 100;

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header con avatar y nombre
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).primaryColor,
                            Theme.of(context).primaryColor.withOpacity(0.7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        children: [
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundColor: AppColors.white.withOpacity(0.2),
                                child: Text(
                                  fullName.isNotEmpty ? fullName[0].toUpperCase() : 'C',
                                  style: const TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.white,
                                  ),
                                ),
                              ),
                              if (isVIP)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AppColors.warning,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.star,
                                      color: AppColors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            fullName,
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                          if (isVIP)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Cliente VIP',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Contenido principal
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Estadísticas
                          Row(
                            children: [
                              Expanded(
                                child: _buildStatCard(
                                  'Total Gastado',
                                  '\$${totalSpent.toStringAsFixed(2)}',
                                  Icons.shopping_bag,
                                  AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Compras',
                                  totalOrders.toString(),
                                  Icons.receipt,
                                  AppColors.info,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildStatCard(
                                  'Puntos',
                                  loyaltyPoints.toString(),
                                  Icons.card_giftcard,
                                  AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Información de contacto
                          Text(
                            'Información de Contacto',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow('Email', email, Icons.email),
                          const SizedBox(height: 12),
                          _buildDetailRow('Teléfono', phone, Icons.phone),
                          const SizedBox(height: 12),
                          _buildDetailRow('Dirección', address, Icons.location_on),
                          const SizedBox(height: 24),

                          // Información adicional
                          Text(
                            'Información Adicional',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildDetailRow(
                            'Cliente desde',
                            '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                            Icons.calendar_today,
                          ),
                          const SizedBox(height: 12),
                          if (lastPurchase != null)
                            _buildDetailRow(
                              'Última compra',
                              '${lastPurchase.day}/${lastPurchase.month}/${lastPurchase.year}',
                              Icons.shopping_cart,
                            ),
                          if (notes.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildDetailRow('Notas', notes, Icons.note),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Theme.of(context).primaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _confirmDeleteCustomer(Map<String, dynamic> customer) {
    final customerName = customer['name']?.toString() ?? 'el cliente';
    final isLoading = ValueNotifier<bool>(false);
    
    showDialog(
      context: context,
      builder: (dialogContext) => ValueListenableBuilder<bool>(
        valueListenable: isLoading,
        builder: (ctx, loading, _) => AlertDialog(
          title: const Text('Confirmar eliminación'),
          content: Text(
            '¿Estás seguro de que deseas eliminar a $customerName? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: loading
                  ? null
                  : () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              onPressed: loading
                  ? null
                  : () async {
                if (dialogContext.mounted) {
                  isLoading.value = true;
                }

                try {
                  final success = await ref
                      .read(customerProvider.notifier)
                      .deleteCustomer(customer['_id']);

                  if (success && dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                    
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('$customerName eliminado correctamente'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                } finally {
                  if (dialogContext.mounted) {
                    isLoading.value = false;
                  }
                }
                    },
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Eliminar'),
            ),
          ],
        ),
      ),
    );
  }
}

