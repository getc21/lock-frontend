import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
            Expanded(
              child: Card(
                child: Center(
                  child: LoadingIndicator(
                    message: 'Cargando clientes...',
                  ),
                ),
              ),
            )
          else if (customerState.customers.isEmpty)
            Expanded(
              child: Card(
                child: Center(
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
                ),
              ),
            )
          else
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.spacing16),
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
    final orderState = ref.watch(orderProvider);
    
    return customers
        .where((c) =>
            _searchQuery.isEmpty ||
            (c['name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (c['email'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList()
        .map((customer) {
      // Calcular puntos dinámicamente basados en órdenes
      final customerId = customer['_id'];
      final customerOrders = orderState.orders
          .where((order) {
            final orderId = order['customerId'] is Map
                ? (order['customerId'] as Map)['_id']
                : order['customerId'];
            return orderId == customerId;
          })
          .toList();
      
      // Calcular puntos: 1 punto por cada $1 gastado
      final points = customerOrders.fold<int>(0, (sum, order) {
        final total = (order['total'] as num? ?? order['totalOrden'] as num? ?? 0).toInt();
        return sum + total;
      });
      
      final isVIP = points >= 2000;
      final fullName = customer['name']?.toString() ?? 'Sin nombre';
      return DataRow2(
        cells: [
          DataCell(
            Row(
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
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
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing8,
                    vertical: AppSizes.spacing4,
                  ),
                  decoration: BoxDecoration(
                    color: points >= 2000
                        ? AppColors.warning.withValues(alpha: 0.1)
                        : AppColors.info.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                  ),
                  child: Text(
                    '$points pts',
                    style: TextStyle(
                      color: points >= 2000 ? AppColors.warning : AppColors.info,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${customerOrders.length} compras',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
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
      builder: (dialogContext) => ValueListenableBuilder<bool>(
        valueListenable: isLoading,
        builder: (ctx, loading, _) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 500,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // HEADER
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSizes.spacing20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          isEditing ? 'Editar Cliente: ${customer['name']}' : 'Nuevo Cliente',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: loading ? null : () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // CONTENT
                Padding(
                  padding: const EdgeInsets.all(AppSizes.spacing20),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: nameController,
                          enabled: !loading,
                          decoration: const InputDecoration(
                            labelText: 'Nombre *',
                            hintText: 'Ingrese el nombre completo',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          textCapitalization: TextCapitalization.words,
                        ),
                        const SizedBox(height: AppSizes.spacing16),
                        TextField(
                          controller: emailController,
                          enabled: !loading,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'ejemplo@correo.com',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: AppSizes.spacing16),
                        TextField(
                          controller: phoneController,
                          enabled: !loading,
                          decoration: const InputDecoration(
                            labelText: 'Teléfono',
                            hintText: '591-XXXXXXXX',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: AppSizes.spacing16),
                        TextField(
                          controller: addressController,
                          enabled: !loading,
                          decoration: const InputDecoration(
                            labelText: 'Dirección',
                            hintText: 'Dirección del cliente',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on_outlined),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: AppSizes.spacing16),
                        TextField(
                          controller: notesController,
                          enabled: !loading,
                          decoration: const InputDecoration(
                            labelText: 'Notas',
                            hintText: 'Información adicional',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note_outlined),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
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
                      TextButton(
                        onPressed: loading ? null : () {
                          nameController.dispose();
                          emailController.dispose();
                          phoneController.dispose();
                          addressController.dispose();
                          notesController.dispose();
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: AppSizes.spacing12),
                      ElevatedButton.icon(
                        icon: loading
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Icon(isEditing ? Icons.update_outlined : Icons.add_rounded),
                        label: Text(isEditing ? 'Actualizar' : 'Crear'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
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
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
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
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 600,
          constraints: const BoxConstraints(maxHeight: 800),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).scaffoldBackgroundColor,
          ),
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

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // HEADER con avatar y nombre
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withValues(alpha: .7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    padding: const EdgeInsets.all(AppSizes.spacing20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: AppColors.white.withValues(alpha: 0.2),
                                child: Text(
                                  fullName.isNotEmpty ? fullName[0].toUpperCase() : 'C',
                                  style: const TextStyle(
                                    fontSize: 32,
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
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: AppColors.warning,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.star,
                                      color: AppColors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSizes.spacing16),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (isVIP)
                                Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(alpha: 0.3),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Cliente VIP',
                                    style: TextStyle(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.white),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                      ],
                    ),
                  ),

                  // CONTENT - Información del cliente
                  Expanded(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.spacing20),
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
                            const SizedBox(height: AppSizes.spacing20),

                            // Información de contacto
                            Text(
                              'Información de Contacto',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSizes.spacing12),
                            _buildDetailRow('Email', email, Icons.email),
                            const SizedBox(height: AppSizes.spacing12),
                            _buildDetailRow('Teléfono', phone, Icons.phone),
                            const SizedBox(height: AppSizes.spacing12),
                            _buildDetailRow('Dirección', address, Icons.location_on),
                            const SizedBox(height: AppSizes.spacing20),

                            // Información adicional
                            Text(
                              'Información Adicional',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: AppSizes.spacing12),
                            _buildDetailRow(
                              'Cliente desde',
                              '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                              Icons.calendar_today,
                            ),
                            const SizedBox(height: AppSizes.spacing12),
                            if (lastPurchase != null)
                              _buildDetailRow(
                                'Última compra',
                                '${lastPurchase.day}/${lastPurchase.month}/${lastPurchase.year}',
                                Icons.shopping_cart,
                              ),
                            if (notes.isNotEmpty) ...[
                              const SizedBox(height: AppSizes.spacing12),
                              _buildDetailRow('Notas', notes, Icons.note),
                            ],
                          ],
                        ),
                      ),
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
                        TextButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                          ),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
        builder: (ctx, loading, _) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                    border: Border(
                      bottom: BorderSide(color: AppColors.error.withValues(alpha: 0.2)),
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSizes.spacing20),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.warning_rounded, color: AppColors.error, size: 20),
                      ),
                      const SizedBox(width: AppSizes.spacing12),
                      Expanded(
                        child: Text(
                          'Eliminar Cliente',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(AppSizes.spacing20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '¿Estás seguro de que deseas eliminar a $customerName?',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: AppSizes.spacing16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outlined, color: AppColors.error, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Esta acción no se puede deshacer',
                                style: TextStyle(fontSize: 12, color: AppColors.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Footer
                Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border, width: 1)),
                  ),
                  padding: const EdgeInsets.all(AppSizes.spacing16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: loading ? null : () => Navigator.of(dialogContext).pop(),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: AppSizes.spacing12),
                      ElevatedButton.icon(
                        icon: loading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(Icons.delete_outlined),
                        label: const Text('Eliminar Permanentemente'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
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

                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                  if (success) {
                                    if (mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('$customerName eliminado correctamente'),
                                          backgroundColor: Colors.green,
                                        ),
                                      );
                                    }
                                  } else {
                                    if (mounted) {
                                      final errorMsg = ref.read(customerProvider).errorMessage;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(errorMsg.isNotEmpty ? errorMsg : 'Error al eliminar cliente'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                }
                              } finally {
                                if (dialogContext.mounted) {
                                  isLoading.value = false;
                                }
                              }
                            },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

