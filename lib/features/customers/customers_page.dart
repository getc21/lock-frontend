import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/controllers/customer_controller.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final _searchController = TextEditingController();
  final CustomerController _customerController = Get.find<CustomerController>();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _customerController.loadCustomers();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Clientes',
      currentRoute: '/customers',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Actions
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
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Cliente'),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing24),
          
          // Customers Table
          Obx(() {
            if (_customerController.isLoading) {
              return const Card(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSizes.spacing24),
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }

            if (_customerController.customers.isEmpty) {
              return Card(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.spacing24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: AppSizes.spacing16),
                        const Text(
                          'No hay clientes disponibles',
                          style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSizes.spacing8),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar Primer Cliente'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Card(
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
                    rows: _buildCustomerRows(),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  List<DataRow2> _buildCustomerRows() {
    final filteredCustomers = _customerController.customers
        .where((c) => _searchQuery.isEmpty || 
                     (c['name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
                     (c['email'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return filteredCustomers.map((customer) {
      final points = customer['loyaltyPoints'] as int? ?? 0;
      final isVIP = points >= 100;
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
                      backgroundColor: AppColors.primary.withOpacity(0.2),
                      child: Text(
                        fullName.isNotEmpty ? fullName[0].toUpperCase() : 'C',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
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
                  onPressed: () {},
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

  void _showCustomerDetails(Map<String, dynamic> customer) {
    final fullName = customer['name']?.toString() ?? 'Sin nombre';
    
    Get.dialog(
      AlertDialog(
        title: Text(fullName),
        content: SizedBox(
          width: 400,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Email: ${customer['email'] ?? 'N/A'}'),
              Text('Teléfono: ${customer['phone'] ?? 'N/A'}'),
              Text('Dirección: ${customer['address'] ?? 'N/A'}'),
              const SizedBox(height: 8),
              Text('Puntos de lealtad: ${customer['loyaltyPoints'] ?? 0}'),
              Text('Total gastado: \$${(customer['totalSpent'] as num? ?? 0).toStringAsFixed(2)}'),
              Text('Total de órdenes: ${customer['totalOrders'] ?? 0}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCustomer(Map<String, dynamic> customer) {
    final customerName = customer['name']?.toString() ?? 'este cliente';
    
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar a "$customerName"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _customerController.deleteCustomer(customer['_id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
