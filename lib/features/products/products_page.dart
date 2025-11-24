import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/widgets/professional_loading.dart';
import '../../shared/providers/riverpod/product_notifier.dart';
import '../../shared/providers/riverpod/category_notifier.dart';
import '../../shared/providers/riverpod/location_notifier.dart';
import '../../shared/providers/riverpod/store_notifier.dart';
import '../../shared/providers/riverpod/supplier_notifier.dart';
import '../../shared/providers/riverpod/currency_notifier.dart';
import '../../shared/services/pdf_service.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _hasInitialized = false;
  int _currentPage = 0;
  static const int _itemsPerPage = 25;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
      if (kDebugMode) debugPrint(' ProductsPage: _loadData called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitialized) {
        _hasInitialized = true;
      if (kDebugMode) debugPrint(' ProductsPage: Loading data in optimized sequence');
        final productState = ref.read(productProvider);
        final supplierState = ref.read(supplierProvider);
        final categoryState = ref.read(categoryProvider);
        final locationState = ref.read(locationProvider);
        
        // CRITICAL: Load categories and suppliers (needed for dropdowns)
        final criticalFutures = <Future>[];
        if (categoryState.categories.isEmpty) {
          criticalFutures.add(ref.read(categoryProvider.notifier).loadCategories());
        }
        if (supplierState.suppliers.isEmpty) {
          criticalFutures.add(ref.read(supplierProvider.notifier).loadSuppliers());
        }
        
        // PARALLEL: Load products and locations
        final parallelFutures = <Future>[];
        if (productState.products.isEmpty) {
          parallelFutures.add(ref.read(productProvider.notifier).loadProductsForCurrentStore());
        }
        if (locationState.locations.isEmpty) {
          parallelFutures.add(ref.read(locationProvider.notifier).loadLocations());
        }
        
        // Execute critical first, then parallel
        if (criticalFutures.isNotEmpty) {
          Future.wait(criticalFutures).then((_) {
            if (mounted && parallelFutures.isNotEmpty) {
              Future.wait(parallelFutures);
            }
          });
        } else if (parallelFutures.isNotEmpty) {
          Future.wait(parallelFutures);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(currencyProvider); // Permite reconstruir cuando cambia la moneda
    
    return DashboardLayout(
      title: 'Productos',
      currentRoute: '/products',
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
                    hintText: 'Buscar productos...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                      _currentPage = 0; // Reset to first page
                    });
                  },
                ),
              ),
              const SizedBox(width: AppSizes.spacing16),
              ElevatedButton.icon(
                onPressed: () => _showAddProductDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Nuevo Producto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing24),
          
          Consumer(
            builder: (context, ref, child) {
              final productState = ref.watch(productProvider);
              
      if (kDebugMode) debugPrint(' ProductsPage: Consumer rebuilding...');
      if (kDebugMode) debugPrint('   - isLoading: ${productState.isLoading}');
      if (kDebugMode) debugPrint('   - products length: ${productState.products.length}');
              
              if (productState.isLoading) {
                return Card(
                  child: SizedBox(
                    height: 600,
                    child: ProfessionalLoading(
                      message: 'Cargando productos...',
                      rowCount: 8,
                      columnCount: 7,
                    ),
                  ),
                );
              }

              if (productState.products.isEmpty) {
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
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              return Card(
                child: SizedBox(
                  height: 600,
                  child: Column(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSizes.spacing16),
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
                            rows: _buildProductRows(productState.products),
                          ),
                        ),
                      ),
                      // Pagination Controls
                      _buildProductPagination(productState.products),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatCurrency(num value) {
    final currencyNotifier = ref.read(currencyProvider.notifier);
    return '${currencyNotifier.symbol}${(value as double).toStringAsFixed(2)}';
  }

  Widget _buildProductPagination(List<dynamic> products) {
    // Calcular páginas basado en búsqueda
    final filteredProducts = products
        .where((p) => _searchQuery.isEmpty || 
                     (p['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
    
    final totalPages = (filteredProducts.length / _itemsPerPage).ceil().clamp(1, double.infinity).toInt();
    
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing16,
        vertical: AppSizes.spacing12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total: ${filteredProducts.length} productos',
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage--)
                    : null,
              ),
              Text(
                'Página ${_currentPage + 1} de $totalPages',
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < totalPages - 1
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<DataRow2> _buildProductRows(List<dynamic> products) {
      if (kDebugMode) debugPrint(' ProductsPage: _buildProductRows called');
      if (kDebugMode) debugPrint('   - Total products: ${products.length}');
      if (kDebugMode) debugPrint('   - Search query: "$_searchQuery"');
    
    final filteredProducts = products
        .where((p) => _searchQuery.isEmpty || 
                     (p['name'] as String).toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

      if (kDebugMode) debugPrint('   - Filtered products: ${filteredProducts.length}');
    
    // Paginación
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, filteredProducts.length);
    final paginatedProducts = startIndex < filteredProducts.length 
        ? filteredProducts.sublist(startIndex, endIndex)
        : [];

    return paginatedProducts.map((product) {
      final stock = product['stock'] as int;
      final isLowStock = stock > 0 && stock < 10;
      final isOutOfStock = stock == 0;

      return DataRow2(
        cells: [
          DataCell(
            GestureDetector(
              onTap: () => _showProductPreview(product),
              child: Row(
                children: [
                  // Lazy-load image: only cache the thumbnail path, don't load full image yet
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
                            cacheHeight: 40,
                            cacheWidth: 40,
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
                        // Only show description if exists - no extra API calls
                        if (product['description'] != null && (product['description'] as String).isNotEmpty)
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
          ),
          DataCell(
            Text(
              _getCategoryName(product['categoryId']),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing8,
                vertical: AppSizes.spacing4,
              ),
              decoration: BoxDecoration(
                color: isOutOfStock ? AppColors.error.withValues(alpha: 0.1) :
                       isLowStock ? AppColors.warning.withValues(alpha: 0.1) :
                       AppColors.success.withValues(alpha: 0.1),
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
            _formatCurrency((product['purchasePrice'] as num)),
            style: const TextStyle(fontWeight: FontWeight.w600),
          )),
          DataCell(Text(
            _formatCurrency((product['salePrice'] as num)),
            style: TextStyle(fontWeight: FontWeight.w600, color: Theme.of(context).primaryColor),
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
                  icon: const Icon(Icons.qr_code_2, size: 18),
                  onPressed: () => _generateQrLabels(product),
                  tooltip: 'Descargar QR (10 etiquetas)',
                  color: AppColors.textPrimary,
                ),
                IconButton(
                  icon: const Icon(Icons.add_shopping_cart, size: 18),
                  onPressed: () => _showAdjustStockDialog(product),
                  tooltip: 'Ajustar Stock',
                  color: AppColors.textPrimary,
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  onPressed: () => _showEditProductDialog(product),
                  tooltip: 'Editar',
                  color: AppColors.textPrimary,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _confirmDeleteProduct(product),
                  tooltip: 'Eliminar',
                  color: AppColors.textPrimary,
                ),
              ],
            ),
          ),
        ],
      );
    }).toList();
  }

  /// Helper: Get category name from populated categoryId or fallback
  String _getCategoryName(dynamic categoryId) {
    if (categoryId == null) return 'Sin categoría';
    if (categoryId is Map) return categoryId['name']?.toString() ?? 'Sin categoría';
    return 'Sin categoría';
  }

  /// Show product preview with full details (lazy-loaded)
  void _showProductPreview(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(product['name'] ?? 'Producto'),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (product['foto'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product['foto'],
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => 
                        Container(
                          height: 200,
                          color: AppColors.gray100,
                          child: const Icon(Icons.inventory_2_outlined, size: 64),
                        ),
                    ),
                  ),
                const SizedBox(height: 16),
                Text(
                  'Stock: ${product['stock']}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Precio Compra: ${_formatCurrency((product['purchasePrice'] as num))}'),
                Text('Precio Venta: ${_formatCurrency((product['salePrice'] as num))}'),
                if (product['description'] != null && (product['description'] as String).isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Descripción:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(product['description'] as String),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Color _getExpirationColor(String? expirationDate) {
    if (expirationDate == null) return Colors.grey;
    
    try {
      final expDate = DateTime.parse(expirationDate);
      final now = DateTime.now();
      final difference = expDate.difference(now).inDays;
      
      if (difference < 0) {
        return AppColors.error;
      } else if (difference <= 30) {
        return AppColors.warning;
      } else {
        return AppColors.success;
      }
    } catch (e) {
      return Colors.grey;
    }
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    _showProductDialog(product: product);
  }

  void _confirmDeleteProduct(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text('¿Estás seguro de eliminar "${product['name']}"?'),
        actions: [
          TextButton(
            onPressed: () {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (context.mounted) {
                Navigator.of(context).pop();
              }
              await ref.read(productProvider.notifier).deleteProduct(product['_id']);
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
    _showProductDialog();
  }

  void _showProductDialog({Map<String, dynamic>? product}) {
    final categoryState = ref.read(categoryProvider);
    final locationState = ref.read(locationProvider);
    final storeState = ref.read(storeProvider);
    final supplierState = ref.read(supplierProvider);
    
    final isEditing = product != null;
    final nameController = TextEditingController(text: product?['name'] ?? '');
    final descriptionController = TextEditingController(text: product?['description'] ?? '');
    final purchasePriceController = TextEditingController(
      text: product?['purchasePrice']?.toString() ?? ''
    );
    final salePriceController = TextEditingController(
      text: product?['salePrice']?.toString() ?? ''
    );
    final stockController = TextEditingController(
      text: product?['stock']?.toString() ?? '0'
    );
    final weightController = TextEditingController(
      text: product?['weight']?.toString() ?? ''
    );
    
    var selectedImage = <XFile>[];
    var imageBytes = '';
    var imagePreview = product?['foto'] ?? '';
    final ImagePicker picker = ImagePicker();
    var isLoading = false;
    
    var selectedCategoryId = product?['categoryId']?['_id'] as String?;
    var selectedSupplierId = product?['supplierId']?['_id'] as String?;
    var selectedLocationId = product?['locationId']?['_id'] as String?;
    var selectedExpiryDate = product?['expiryDate'] != null 
        ? DateTime.parse(product!['expiryDate']) 
        : null;

    Future<void> pickImage() async {
      try {
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 800,
          maxHeight: 800,
          imageQuality: 85,
        );
        
        if (image != null) {
          selectedImage = [image];
          final bytes = await image.readAsBytes();
          imageBytes = 'data:image/jpeg;base64,${base64Encode(bytes)}';
          imagePreview = imageBytes;
      if (kDebugMode) debugPrint(' Image selected: ${image.name}');
        }
      } catch (e) {
      if (kDebugMode) debugPrint(' Error picking image: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al seleccionar imagen')),
          );
        }
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto'),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () async {
                      await pickImage();
                      setState(() {});
                    },
                    child: Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(dialogContext).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(dialogContext).primaryColor.withValues(alpha: 0.3),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: imagePreview.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.network(
                                imagePreview,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_photo_alternate, size: 40, color: Theme.of(dialogContext).primaryColor),
                                      const SizedBox(height: 8),
                                      const Text('Seleccionar imagen', style: TextStyle(fontSize: 12)),
                                    ],
                                  );
                                },
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_photo_alternate, size: 40, color: Theme.of(dialogContext).primaryColor),
                                const SizedBox(height: 8),
                                const Text('Seleccionar imagen', style: TextStyle(fontSize: 12)),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing24),
                  
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del Producto *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing16),

                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSizes.spacing16),

                  DropdownButtonFormField<String>(
                    value: selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Categoría *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: categoryState.categories.map((category) {
                      final id = category['_id']?.toString() ?? category['id']?.toString() ?? '''''' '';
                      final name = category['name']?.toString() ?? 'Sin nombre';
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(name),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => selectedCategoryId = value),
                  ),
                  const SizedBox(height: AppSizes.spacing16),

                  DropdownButtonFormField<String>(
                    value: selectedSupplierId,
                    decoration: const InputDecoration(
                      labelText: 'Proveedor *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_shipping_outlined),
                    ),
                    items: supplierState.suppliers.map((supplier) {
                      final id = supplier['_id']?.toString() ?? supplier['id']?.toString() ?? '''''' '';
                      final name = supplier['name']?.toString() ?? 'Sin nombre';
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(name),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => selectedSupplierId = value),
                  ),
                  const SizedBox(height: AppSizes.spacing16),

                  DropdownButtonFormField<String>(
                    value: selectedLocationId,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    items: locationState.locations.map((location) {
                      final id = location['_id']?.toString() ?? location['id']?.toString() ?? '''''' '';
                      final name = location['name']?.toString() ?? 'Sin nombre';
                      return DropdownMenuItem<String>(
                        value: id,
                        child: Text(name),
                      );
                    }).toList(),
                    onChanged: (value) => setState(() => selectedLocationId = value),
                  ),
                  const SizedBox(height: AppSizes.spacing16),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: purchasePriceController,
                          decoration: const InputDecoration(
                            labelText: 'Precio Compra *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.attach_money),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacing16),
                      Expanded(
                        child: TextField(
                          controller: salePriceController,
                          decoration: const InputDecoration(
                            labelText: 'Precio Venta *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.sell_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacing16),

                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: stockController,
                          decoration: const InputDecoration(
                            labelText: 'Stock Inicial *',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.inventory_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          enabled: !isEditing,
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacing16),
                      Expanded(
                        child: TextField(
                          controller: weightController,
                          decoration: const InputDecoration(
                            labelText: 'Peso (kg)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.scale_outlined),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.spacing16),

                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedExpiryDate ?? DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 3650)),
                      );
                      if (date != null) {
                        setState(() => selectedExpiryDate = date);
                      }
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha de Caducidad *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.event_outlined),
                      ),
                      child: Text(
                        selectedExpiryDate != null
                            ? DateFormat('dd/MM/yyyy').format(selectedExpiryDate!)
                            : 'Seleccionar fecha',
                        style: TextStyle(
                          color: selectedExpiryDate != null
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing8),

                  const Text(
                    '* Campos requeridos',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                  if (isEditing) ...[
                    const SizedBox(height: AppSizes.spacing8),
                    const Text(
                      'Nota: El stock no se puede editar aquí. Use la función de ajuste de inventario.',
                      style: TextStyle(fontSize: 12, color: AppColors.warning),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El nombre es requerido')),
                  );
                  return;
                }
                if (selectedCategoryId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Seleccione una categoría')),
                  );
                  return;
                }
                if (selectedSupplierId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Seleccione un proveedor')),
                  );
                  return;
                }
                if (selectedLocationId == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Seleccione una ubicación')),
                  );
                  return;
                }
                if (purchasePriceController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El precio de compra es requerido')),
                  );
                  return;
                }
                if (salePriceController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El precio de venta es requerido')),
                  );
                  return;
                }
                if (!isEditing && stockController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El stock inicial es requerido')),
                  );
                  return;
                }
                if (selectedExpiryDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Seleccione la fecha de caducidad')),
                  );
                  return;
                }

                setState(() => isLoading = true);
                final purchasePrice = double.tryParse(purchasePriceController.text.trim());
                final salePrice = double.tryParse(salePriceController.text.trim());
                
                if (purchasePrice == null || salePrice == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Los precios deben ser números válidos')),
                  );
                  setState(() => isLoading = false);
                  return;
                }

                if (salePrice <= purchasePrice) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El precio de venta debe ser mayor al precio de compra')),
                  );
                  setState(() => isLoading = false);
                  return;
                }

                bool success;
                if (isEditing) {
                  success = await ref.read(productProvider.notifier).updateProduct(
                    id: product['_id'],
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim().isEmpty 
                        ? null 
                        : descriptionController.text.trim(),
                    categoryId: selectedCategoryId,
                    locationId: selectedLocationId,
                    purchasePrice: purchasePrice,
                    salePrice: salePrice,
                    weight: weightController.text.trim().isEmpty 
                        ? null 
                        : double.tryParse(weightController.text.trim()),
                    expiryDate: selectedExpiryDate,
                    imageFile: selectedImage.isNotEmpty ? selectedImage[0] : null,
                    imageBytes: imageBytes.isNotEmpty ? imageBytes : null,
                  );
                } else {
                  final stock = int.tryParse(stockController.text.trim()) ?? 0;
                  final currentStore = storeState.currentStore;
                  
                  if (currentStore == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No hay tienda seleccionada')),
                    );
                    setState(() => isLoading = false);
                    return;
                  }

                  success = await ref.read(productProvider.notifier).createProduct(
                    storeId: currentStore['_id'],
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim().isEmpty 
                        ? null 
                        : descriptionController.text.trim(),
                    categoryId: selectedCategoryId!,
                    supplierId: selectedSupplierId!,
                    locationId: selectedLocationId!,
                    purchasePrice: purchasePrice,
                    salePrice: salePrice,
                    stock: stock,
                    weight: weightController.text.trim().isEmpty 
                        ? null 
                        : double.tryParse(weightController.text.trim()),
                    expiryDate: selectedExpiryDate!,
                    imageFile: selectedImage.isNotEmpty ? selectedImage[0] : null,
                    imageBytes: imageBytes.isNotEmpty ? imageBytes : null,
                  );
                }

                setState(() => isLoading = false);
                if (success) {
      if (kDebugMode) debugPrint(' ProductsPage: Product ${isEditing ? "updated" : "created"} successfully');
                  if (context.mounted) {
                    Navigator.of(context).pop();
                  }
                  await Future.delayed(const Duration(milliseconds: 300));
                  await ref.read(productProvider.notifier).loadProductsForCurrentStore();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(isEditing ? 'Actualizar' : 'Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdjustStockDialog(Map<String, dynamic> product) {
    final productName = product['name'] ?? 'Producto';
    final productId = product['_id'];
    final currentStock = product['stock'] ?? 0;
    final adjustmentController = TextEditingController();
    var isLoading = false;
    var isAdding = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Ajustar Stock - $productName'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Stock actual: $currentStock',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment<bool>(
                      value: true,
                      label: Text('Agregar'),
                      icon: Icon(Icons.add),
                    ),
                    ButtonSegment<bool>(
                      value: false,
                      label: Text('Quitar'),
                      icon: Icon(Icons.remove),
                    ),
                  ],
                  selected: {isAdding},
                  onSelectionChanged: (Set<bool> newSelection) {
                    setState(() => isAdding = newSelection.first);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: adjustmentController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Cantidad',
                    border: const OutlineInputBorder(),
                    prefixIcon: Icon(
                      isAdding ? Icons.add_circle_outline : Icons.remove_circle_outline,
                      color: isAdding ? Colors.green : AppColors.error,
                    ),
                  ),
                  autofocus: true,
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final adjustment = int.tryParse(adjustmentController.text.trim()) ?? 0;
                    final newStock = isAdding 
                        ? currentStock + adjustment 
                        : currentStock - adjustment;
                    
                    return Text(
                      'Nuevo stock: $newStock',
                      style: TextStyle(
                        fontSize: 14,
                        color: newStock < 0 ? AppColors.error : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                final adjustment = int.tryParse(adjustmentController.text.trim());
                
                if (adjustment == null || adjustment <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ingresa una cantidad válida')),
                  );
                  return;
                }

                final newStock = isAdding 
                    ? currentStock + adjustment 
                    : currentStock - adjustment;

                if (newStock < 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('El stock no puede ser negativo')),
                  );
                  return;
                }

                setState(() => isLoading = true);
                final success = await ref.read(productProvider.notifier).adjustStock(
                  productId: productId,
                  adjustment: isAdding ? adjustment : -adjustment,
                );
                setState(() => isLoading = false);

                if (success && context.mounted) {
                  Navigator.of(context).pop();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generateQrLabels(Map<String, dynamic> product) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generando PDF con QRs...'),
          duration: Duration(seconds: 2),
        ),
      );

      await PdfService.generateProductQrLabels(product: product);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF con 10 QRs descargado correctamente'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      String errorMessage = 'Error al generar PDF';
      
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('path') || errorStr.contains('storage')) {
        errorMessage = 'No se pudo acceder al almacenamiento. Verifica los permisos.';
      } else if (errorStr.contains('permission')) {
        errorMessage = 'Permiso denegado. Habilita permisos de almacenamiento.';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            duration: const Duration(seconds: 4),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

