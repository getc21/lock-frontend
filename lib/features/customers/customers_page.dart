import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/providers/riverpod/customer_notifier.dart';

class CustomersPage extends ConsumerStatefulWidget {
  const CustomersPage({super.key});

  @override
  ConsumerState<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends ConsumerState<CustomersPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '''''' '';
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized && mounted) {
        _hasInitialized = true;
        final customerState = ref.read(customerProvider);
        if (customerState.customers.isEmpty) {
          ref.read(customerProvider.notifier).loadCustomersForCurrentStore();
        }
      }
    });
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
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing24),
          Consumer(
            builder: (context, ref, child) {
              final customerState = ref.watch(customerProvider);
              if (customerState.isLoading) {
                return SizedBox(
                  height: 600,
                  child: Card(child: Center(child: LoadingIndicator(message: 'Cargando clientes...'))),
                );
              }
              if (customerState.customers.isEmpty) {
                return Card(child: Center(child: Padding(padding: const EdgeInsets.all(AppSizes.spacing24), child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.people_outline, size: 64, color: AppColors.textSecondary), const SizedBox(height: AppSizes.spacing16), const Text('No hay clientes disponibles', style: TextStyle(fontSize: 18, color: AppColors.textSecondary)), const SizedBox(height: AppSizes.spacing8), ElevatedButton.icon(onPressed: () => _showCustomerDialog(), icon: const Icon(Icons.add), label: const Text('Agregar Primer Cliente'))]))));
              }
              return Card(child: Padding(padding: const EdgeInsets.all(AppSizes.spacing16), child: SizedBox(height: 600, child: DataTable2(columnSpacing: 12, horizontalMargin: 12, minWidth: 1000, columns: const [DataColumn2(label: Text('Cliente'), size: ColumnSize.L), DataColumn2(label: Text('Email'), size: ColumnSize.L), DataColumn2(label: Text('Teléfono'), size: ColumnSize.M), DataColumn2(label: Text('Puntos'), size: ColumnSize.S), DataColumn2(label: Text('Acciones'), size: ColumnSize.M)], rows: _buildCustomerRows(customerState.customers)))));
            },
          ),
        ],
      ),
    );
  }

  List<DataRow2> _buildCustomerRows(List<dynamic> customers) {
    return customers.where((c) => _searchQuery.isEmpty || (c['name'] ?? '''').toLowerCase().contains(_searchQuery.toLowerCase()) || (c['email'] ?? '''').toLowerCase().contains(_searchQuery.toLowerCase())).toList().map((customer) {
      final points = customer['loyaltyPoints'] as int? ?? 0;
      final isVIP = points >= 100;
      final fullName = customer['name']?.toString() ?? 'Sin nombre';
      return DataRow2(cells: [DataCell(Row(children: [Stack(children: [CircleAvatar(radius: 20, backgroundColor: AppColors.primary.withOpacity(0.2), child: Text(fullName.isNotEmpty ? fullName[0].toUpperCase() : 'C', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary))), if (isVIP) Positioned(right: 0, bottom: 0, child: Container(padding: const EdgeInsets.all(2), decoration: const BoxDecoration(color: AppColors.warning, shape: BoxShape.circle), child: const Icon(Icons.star, size: 12, color: AppColors.white)))]), const SizedBox(width: AppSizes.spacing12), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [Text(fullName, style: const TextStyle(fontWeight: FontWeight.w600)), if (isVIP) const Text('Cliente VIP', style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600))]))], )), DataCell(Text(customer['email'] ?? 'Sin email')), DataCell(Text(customer['phone'] ?? 'Sin teléfono')), DataCell(Container(padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing8, vertical: AppSizes.spacing4), decoration: BoxDecoration(color: AppColors.info.withOpacity(0.1), borderRadius: BorderRadius.circular(AppSizes.radiusSmall)), child: Text('$points pts', style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.w600)))), DataCell(Row(mainAxisSize: MainAxisSize.min, children: [IconButton(icon: const Icon(Icons.visibility_outlined, size: 20), onPressed: () => _showCustomerDetails(customer), tooltip: 'Ver detalles'), IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _showCustomerDialog(customer: customer), tooltip: 'Editar'), IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: () => _confirmDeleteCustomer(customer), tooltip: 'Eliminar')]))]);
    }).toList();
  }

  void _showCustomerDialog({Map<String, dynamic>? customer}) {}
  void _showCustomerDetails(Map<String, dynamic> customer) {}
  void _confirmDeleteCustomer(Map<String, dynamic> customer) {}
}
