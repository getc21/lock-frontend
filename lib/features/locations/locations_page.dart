import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/providers/riverpod/location_notifier.dart';
import '../../shared/providers/riverpod/store_notifier.dart';
import '../../shared/providers/riverpod/product_notifier.dart';

class LocationsPage extends ConsumerStatefulWidget {
  const LocationsPage({super.key});

  @override
  ConsumerState<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends ConsumerState<LocationsPage> {
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized && mounted) {
        _hasInitialized = true;
        ref.read(locationProvider.notifier).loadLocationsForCurrentStore();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(locationProvider);
    final storeState = ref.watch(storeProvider);
    
    // Recargar ubicaciones cuando cambie la tienda
    ref.listen(storeProvider, (previous, next) {
      if (previous?.currentStore?['_id'] != next.currentStore?['_id']) {
        ref.read(locationProvider.notifier).loadLocationsForCurrentStore();
      }
    });

    return DashboardLayout(
      title: 'Ubicaciones',
      currentRoute: '/locations',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con botón de agregar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gestión de Ubicaciones',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tienda: ${storeState.currentStore?['name'] ?? 'Sin tienda'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showLocationDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Nueva Ubicación'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing20,
                    vertical: AppSizes.spacing12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing24),

          // Tabla de ubicaciones
          SizedBox(
            height: 600,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacing16),
                child: locationState.isLoading
                    ? LoadingIndicator(
                        message: 'Cargando ubicaciones...',
                      )
                    : locationState.locations.isEmpty
                        ? const Center(
                            child: Text('No hay ubicaciones registradas para esta tienda'),
                          )
                        : DataTable2(
                            columnSpacing: 12,
                            horizontalMargin: 12,
                            minWidth: 600,
                            columns: const [
                              DataColumn2(
                                label: Text('Nombre'),
                                size: ColumnSize.L,
                              ),
                              DataColumn2(
                                label: Text('Descripción'),
                                size: ColumnSize.L,
                              ),
                              DataColumn2(
                                label: Text('Acciones'),
                                size: ColumnSize.S,
                              ),
                            ],
                            rows: locationState.locations.map((location) {
                              final locationName = location['name'] ?? '';
                              final locationDescription = location['description'] ?? '-';
                              
                              return DataRow2(
                                onTap: () => _showLocationProducts(location),
                                cells: [
                                  DataCell(Text(locationName)),
                                  DataCell(Text(locationDescription)),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit_outlined, size: 18),
                                          color: AppColors.textPrimary,
                                          onPressed: () => _showLocationDialog(location: location),
                                          tooltip: 'Editar',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete_outline, size: 18),
                                          color: AppColors.textPrimary,
                                          onPressed: () => _confirmDelete(location),
                                          tooltip: 'Eliminar',
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationDialog({Map<String, dynamic>? location}) {
    final nameController = TextEditingController(text: location?['name'] ?? '');
    final descriptionController = TextEditingController(text: location?['description'] ?? '');
    final isEditing = location != null;
    final isLoading = ValueNotifier<bool>(false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEditing ? 'Editar Ubicación' : 'Nueva Ubicación'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  hintText: 'Ej: Estante A1, Vitrina Principal, Bodega',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: AppSizes.spacing16),
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descripción',
                  hintText: 'Detalles adicionales de la ubicación',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isLoading,
            builder: (context, loading, _) => ElevatedButton(
              onPressed: loading ? null : () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('El nombre es requerido'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                if (context.mounted) {
                  isLoading.value = true;
                }
                try {
                  bool success;
                  if (isEditing) {
                    success = await ref.read(locationProvider.notifier).updateLocation(
                      id: location['_id'],
                      name: nameController.text,
                      description: descriptionController.text.isEmpty ? null : descriptionController.text,
                    );
                  } else {
                    success = await ref.read(locationProvider.notifier).createLocation(
                      name: nameController.text,
                      description: descriptionController.text.isEmpty ? null : descriptionController.text,
                    );
                  }

                  if (success && context.mounted) {
                    Navigator.pop(context);
                  }
                } finally {
                  if (context.mounted) {
                    isLoading.value = false;
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: Text(isEditing ? 'Actualizar' : 'Crear'),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> location) {
    final locationName = location['name'] ?? 'esta ubicación';
    final locationId = location['_id'];
    final isDeleting = ValueNotifier<bool>(false);
    
    if (locationId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('ID de ubicación no válido'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar la ubicación "$locationName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ValueListenableBuilder<bool>(
            valueListenable: isDeleting,
            builder: (context, deleting, _) => ElevatedButton(
              onPressed: deleting ? null : () async {
                if (context.mounted) {
                  isDeleting.value = true;
                }
                try {
                  final success = await ref.read(locationProvider.notifier).deleteLocation(locationId);
                  if (success && context.mounted) {
                    Navigator.pop(context);
                  }
                } finally {
                  if (context.mounted) {
                    isDeleting.value = false;
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: const Text('Eliminar'),
            ),
          ),
        ],
      ),
    );
  }

  void _showLocationProducts(Map<String, dynamic> location) {
    // Get products from current Riverpod state
    final locationName = location['name'] ?? 'Ubicación';
    final locationId = location['_id'];
    
    // Access the product state that we read in build
    final products = ref.read(productProvider).products;
    
    final locationProducts = products.where((product) {
      final productLocationId = product['locationId'] is Map 
          ? product['locationId']['_id'] 
          : product['locationId'];
      return productLocationId == locationId;
    }).toList();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(AppSizes.spacing24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Productos en: $locationName',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${locationProducts.length} producto(s) encontrado(s)',
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Cerrar',
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.spacing16),
              const Divider(),
              const SizedBox(height: AppSizes.spacing16),
              
              // Lista de productos
              Expanded(
                child: locationProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: AppColors.textSecondary.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay productos en esta ubicación',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: locationProducts.length,
                        itemBuilder: (context, index) {
                          final product = locationProducts[index];
                          final stock = product['stock'] ?? 0;
                          final isOutOfStock = stock == 0;
                          final isLowStock = stock > 0 && stock < 10;
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: AppSizes.spacing12),
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
                                            Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            color: AppColors.gray100,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Icon(Icons.inventory_2_outlined),
                                        ),
                                      ),
                                    )
                                  : Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: AppColors.gray100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.inventory_2_outlined),
                                    ),
                              title: Text(
                                product['name'] ?? 'Sin nombre',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (product['description'] != null)
                                    Text(
                                      product['description'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        'Stock: ',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isOutOfStock
                                              ? AppColors.error.withOpacity(0.1)
                                              : isLowStock
                                                  ? AppColors.warning.withOpacity(0.1)
                                                  : AppColors.success.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          '$stock',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: isOutOfStock
                                                ? AppColors.error
                                                : isLowStock
                                                    ? AppColors.warning
                                                    : AppColors.success,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Text(
                                        'Precio: \$${(product['salePrice'] as num).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (product['categoryId'] != null && 
                                      product['categoryId'] is Map)
                                    Chip(
                                      label: Text(
                                        product['categoryId']['name'] ?? 'Sin categoría',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                      padding: EdgeInsets.zero,
                                    ),
                                ],
                              ),
                            ),
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
}

