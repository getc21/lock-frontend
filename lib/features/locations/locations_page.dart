import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/controllers/location_controller.dart';
import '../../shared/controllers/store_controller.dart';
import '../../shared/controllers/product_controller.dart';

class LocationsPage extends StatefulWidget {
  const LocationsPage({super.key});

  @override
  State<LocationsPage> createState() => _LocationsPageState();
}

class _LocationsPageState extends State<LocationsPage> {
  late final LocationController _locationController;
  final StoreController _storeController = Get.find<StoreController>();
  final ProductController _productController = Get.find<ProductController>();
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    _locationController = Get.find<LocationController>();
    
    // Cargar ubicaciones después de que el widget esté montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized && mounted) {
        _hasInitialized = true;
        // Solo cargar si no hay datos
        if (_locationController.locations.isEmpty) {
          _locationController.loadLocationsForCurrentStore();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                  Obx(() {
                    final storeName = _storeController.currentStore?['name'] ?? 'Sin tienda';
                    return Text(
                      'Tienda: $storeName',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    );
                  }),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => _showLocationDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Nueva Ubicación'),
                style: ElevatedButton.styleFrom(
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
                child: Obx(() {
                  if (_locationController.isLoading) {
                    return LoadingIndicator(
                      message: 'Cargando ubicaciones...',
                    );
                  }

                  if (_locationController.locations.isEmpty) {
                    return const Center(
                      child: Text('No hay ubicaciones registradas para esta tienda'),
                    );
                  }

                  return DataTable2(
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
                    rows: _locationController.locations.map((location) {
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
                  );
                }),
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
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                Get.snackbar(
                  'Error',
                  'El nombre es requerido',
                  snackPosition: SnackPosition.TOP,
                  backgroundColor: Colors.red,
                  colorText: Colors.white,
                );
                return;
              }

              bool success;
              if (isEditing) {
                success = await _locationController.updateLocation(
                  id: location['_id'],
                  name: nameController.text,
                  description: descriptionController.text.isEmpty ? null : descriptionController.text,
                );
              } else {
                success = await _locationController.createLocation(
                  name: nameController.text,
                  description: descriptionController.text.isEmpty ? null : descriptionController.text,
                );
              }

              if (success && context.mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(isEditing ? 'Actualizar' : 'Crear'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> location) {
    final locationName = location['name'] ?? 'esta ubicación';
    final locationId = location['_id'];
    
    if (locationId == null) {
      Get.snackbar(
        'Error',
        'ID de ubicación no válido',
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
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
          ElevatedButton(
            onPressed: () async {
              final success = await _locationController.deleteLocation(locationId);
              if (success && context.mounted) {
                Navigator.pop(context);
              }
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

  void _showLocationProducts(Map<String, dynamic> location) {
    final locationName = location['name'] ?? 'Ubicación';
    final locationId = location['_id'];
    
    // Filtrar productos por ubicación
    final locationProducts = _productController.products.where((product) {
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
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
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
                                      backgroundColor: AppColors.primary.withOpacity(0.1),
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
