import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/controllers/product_controller.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _searchController = TextEditingController();
  final ProductController _productController = Get.find<ProductController>();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _productController.loadProductsForCurrentStore();
  }

  @override
  Widget build(BuildContext context) {
    return DashboardLayout(
      title: 'Productos',
      currentRoute: '/products',
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
                    hintText: 'Buscar productos...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value);
                  },
                ),
              ),
              const SizedBox(width: AppSizes.spacing16),
              ElevatedButton.icon(
                onPressed: () => _showAddProductDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Producto'),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing24),
          
          // Products Table
          Obx(() {
            if (_productController.isLoading) {
              return const Card(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSizes.spacing24),
                    child: CircularProgressIndicator(),
                  ),
                ),
              );
            }

            if (_productController.products.isEmpty) {
              return Card(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.spacing24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: AppSizes.spacing16),
                        const Text(
                          'No hay productos disponibles',
                          style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSizes.spacing8),
                        ElevatedButton.icon(
                          onPressed: () => _showAddProductDialog(),
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar Primer Producto'),
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
                    minWidth: 1100,
                    columns: const [
                      DataColumn2(label: Text('Producto'), size: ColumnSize.L),
                      DataColumn2(label: Text('Categoría'), size: ColumnSize.M),
                      DataColumn2(label: Text('Stock'), size: ColumnSize.S),
                      DataColumn2(label: Text('Precio Compra'), size: ColumnSize.S),
                      DataColumn2(label: Text('Precio Venta'), size: ColumnSize.S),
                      DataColumn2(label: Text('F. Caducidad'), size: ColumnSize.M),
                      DataColumn2(label: Text('Acciones'), size: ColumnSize.M),
                    ],
                    rows: _buildProductRows(),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  List<DataRow2> _buildProductRows() {
    final filteredProducts = _productController.products
        .where((p) => _searchQuery.isEmpty || 
                     (p['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    return filteredProducts.map((product) {
      final stock = product['stock'] as int;
      final isLowStock = stock > 0 && stock < 10;
      final isOutOfStock = stock == 0;

      return DataRow2(
        cells: [
          DataCell(
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.gray100,
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  child: product['foto'] != null 
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                        child: Image.network(
                          product['foto'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.inventory_2_outlined, size: 20),
                        ),
                      )
                    : const Icon(Icons.inventory_2_outlined, size: 20),
                ),
                const SizedBox(width: AppSizes.spacing12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        product['name'] as String,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (product['description'] != null)
                        Text(
                          product['description'] as String,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          DataCell(Text(
            product['categoryId']?['name'] ?? 'Sin categoría',
          )),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing8,
                vertical: AppSizes.spacing4,
              ),
              decoration: BoxDecoration(
                color: isOutOfStock ? AppColors.error.withOpacity(0.1) :
                       isLowStock ? AppColors.warning.withOpacity(0.1) :
                       AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
              ),
              child: Text(
                '$stock',
                style: TextStyle(
                  color: isOutOfStock ? AppColors.error :
                         isLowStock ? AppColors.warning :
                         AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          DataCell(Text(
            '\$${(product['purchasePrice'] as num).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600),
          )),
          DataCell(Text(
            '\$${(product['salePrice'] as num).toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
          )),
          DataCell(
            Text(
              product['expiryDate'] != null
                  ? DateFormat('dd/MM/yyyy').format(DateTime.parse(product['expiryDate']))
                  : 'N/A',
              style: TextStyle(
                color: _getExpirationColor(product['expiryDate']),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DataCell(
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  onPressed: () => _showEditProductDialog(product),
                  tooltip: 'Editar',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  onPressed: () => _confirmDeleteProduct(product),
                  tooltip: 'Eliminar',
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  Color _getExpirationColor(String? expirationDate) {
    if (expirationDate == null) return Colors.grey;
    
    try {
      final expDate = DateTime.parse(expirationDate);
      final now = DateTime.now();
      final difference = expDate.difference(now).inDays;
      
      if (difference < 0) {
        return AppColors.error; // Vencido
      } else if (difference <= 30) {
        return AppColors.warning; // Por vencer (menos de 30 días)
      } else {
        return AppColors.success; // Vigente
      }
    } catch (e) {
      return Colors.grey;
    }
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    // TODO: Implementar diálogo de edición
    Get.snackbar(
      'Info',
      'Función de edición por implementar',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void _confirmDeleteProduct(Map<String, dynamic> product) {
    Get.dialog(
      AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar "${product['name']}"?'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Get.back();
              await _productController.deleteProduct(product['_id']);
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

  void _showAddProductDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nuevo Producto'),
        content: const SizedBox(
          width: 500,
          child: Text('Formulario de producto (por implementar)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
