import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/providers/riverpod/product_notifier.dart';
import '../../shared/providers/riverpod/category_notifier.dart';
import '../../shared/providers/riverpod/location_notifier.dart';
import '../../shared/providers/riverpod/store_notifier.dart';
import '../../shared/providers/riverpod/supplier_notifier.dart';
import '../../shared/providers/riverpod/currency_notifier.dart';
import '../../shared/providers/riverpod/auth_notifier.dart';
import 'package:barcode_widget/barcode_widget.dart';
import '../../shared/services/pdf_service.dart';
import '../../shared/services/web_image_compression_service.dart';

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
  bool _filterLowStock = false;
  bool _filterExpiringSoon = false;

  @override
  void initState() {
    super.initState();
    // Cargar datos en primer acceso
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cada vez que la página se reconstruye, recargar productos
    // Esto es importante para reflejar cambios de otras páginas (como devoluciones)
    // IMPORTANT: Use addPostFrameCallback to delay provider modification
    // until after the widget tree is done building (required by Riverpod)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(productProvider.notifier).loadProductsForCurrentStore(forceRefresh: true);
      }
    });
  }

  void _loadData() {
    if (kDebugMode) debugPrint('ProductsPage: _loadData called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_hasInitialized) {
        _hasInitialized = true;
        if (kDebugMode) debugPrint('ProductsPage: Loading data in optimized sequence');
        final supplierState = ref.read(supplierProvider);
        final categoryState = ref.read(categoryProvider);
        
        // CRITICAL: Load categories and suppliers (needed for dropdowns)
        final criticalFutures = <Future>[];
        if (categoryState.categories.isEmpty) {
          criticalFutures.add(ref.read(categoryProvider.notifier).loadCategories());
        }
        if (supplierState.suppliers.isEmpty) {
          criticalFutures.add(ref.read(supplierProvider.notifier).loadSuppliers());
        }
        
        // PARALLEL: Load locations only (always reload to pick up new locations)
        final parallelFutures = <Future>[];
        parallelFutures.add(ref.read(locationProvider.notifier).loadLocations());
        
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
              const SizedBox(width: AppSizes.spacing8),
              IconButton(
                icon: const Icon(Icons.warning, color: Colors.white),
                tooltip: 'Stock bajo (≤3 unidades)',
                isSelected: _filterLowStock,
                onPressed: () {
                  setState(() {
                    _filterLowStock = !_filterLowStock;
                    _currentPage = 0;
                  });
                },
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: AppSizes.spacing8),
              IconButton(
                icon: const Icon(Icons.event_busy, color: Colors.white),
                tooltip: 'Caducidad próxima (<60 días)',
                isSelected: _filterExpiringSoon,
                onPressed: () {
                  setState(() {
                    _filterExpiringSoon = !_filterExpiringSoon;
                    _currentPage = 0;
                  });
                },
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing24),
          
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
              final productState = ref.watch(productProvider);
              final authState = ref.watch(authProvider);
              final userRole = authState.currentUser?['role'] ?? '';
              final canSeePurchasePrice = userRole == 'admin' || userRole == 'manager';
              final canAdjustStock = userRole == 'admin' || userRole == 'manager' || userRole == 'employee';
              
      if (kDebugMode) debugPrint(' ProductsPage: Consumer rebuilding...');
      if (kDebugMode) debugPrint('   - isLoading: ${productState.isLoading}');
      if (kDebugMode) debugPrint('   - products length: ${productState.products.length}');
              
              if (productState.isLoading) {
                return Card(
                  child: Center(
                    child: LoadingIndicator(
                      message: 'Cargando productos...',
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
                child: Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.spacing16),
                        child: DataTable2(
                          columnSpacing: 12,
                          horizontalMargin: 12,
                          minWidth: canSeePurchasePrice ? 1100 : 1000,
                          columns: [
                            const DataColumn2(label: Text('Producto'), size: ColumnSize.L),
                            const DataColumn2(label: Text('Categoría'), size: ColumnSize.M),
                            const DataColumn2(label: Text('Stock'), size: ColumnSize.S),
                            if (canSeePurchasePrice)
                              const DataColumn2(label: Text('Precio Compra'), size: ColumnSize.S),
                            const DataColumn2(label: Text('Precio Venta'), size: ColumnSize.S),
                            const DataColumn2(label: Text('F. Caducidad'), size: ColumnSize.M),
                            const DataColumn2(label: Text('Acciones'), size: ColumnSize.M),
                          ],
                          rows: _buildProductRows(productState.products, canSeePurchasePrice, canAdjustStock),
                        ),
                      ),
                    ),
                    // Pagination Controls
                    _buildProductPagination(productState.products),
                  ],
                ),
              );
            },
            ),
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
    // Calcular páginas basado en búsqueda y filtros
    final filteredProducts = products
        .where((p) {
          // Filtro de búsqueda
          final name = p['name']?.toString() ?? '';
          final description = p['description']?.toString() ?? '';
          final matchesSearch = _searchQuery.isEmpty || 
                         name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                         description.toLowerCase().contains(_searchQuery.toLowerCase());
          
          // Filtro de stock bajo
          final stock = (p['stock'] as int?) ?? 0;
          final matchesLowStock = !_filterLowStock || stock <= 3;
          
          // Filtro de caducidad próxima
          final expiryDate = p['expiryDate'];
          bool matchesExpiringSoon = true;
          if (_filterExpiringSoon && expiryDate != null) {
            try {
              final expDate = DateTime.parse(expiryDate);
              final now = DateTime.now();
              final difference = expDate.difference(now).inDays;
              matchesExpiringSoon = difference < 60;
            } catch (e) {
              matchesExpiringSoon = false;
            }
          }
          
          return matchesSearch && matchesLowStock && matchesExpiringSoon;
        })
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

  List<DataRow2> _buildProductRows(List<dynamic> products, bool canSeePurchasePrice, bool canAdjustStock) {
      if (kDebugMode) debugPrint(' ProductsPage: _buildProductRows called');
      if (kDebugMode) debugPrint('   - Total products: ${products.length}');
      if (kDebugMode) debugPrint('   - Search query: "$_searchQuery"');
      if (kDebugMode) debugPrint('   - canAdjustStock: $canAdjustStock');
    
    final filteredProducts = products
        .where((p) {
          // Filtro de búsqueda
          final name = p['name']?.toString() ?? '';
          final description = p['description']?.toString() ?? '';
          final matchesSearch = _searchQuery.isEmpty || 
                         name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                         description.toLowerCase().contains(_searchQuery.toLowerCase());
          
          // Filtro de stock bajo
          final stock = (p['stock'] as int?) ?? 0;
          final matchesLowStock = !_filterLowStock || stock <= 3;
          
          // Filtro de caducidad próxima
          final expiryDate = p['expiryDate'];
          bool matchesExpiringSoon = true;
          if (_filterExpiringSoon && expiryDate != null) {
            try {
              final expDate = DateTime.parse(expiryDate);
              final now = DateTime.now();
              final difference = expDate.difference(now).inDays;
              matchesExpiringSoon = difference < 60;
            } catch (e) {
              matchesExpiringSoon = false;
            }
          }
          
          return matchesSearch && matchesLowStock && matchesExpiringSoon;
        })
        .toList();

      if (kDebugMode) debugPrint('   - Filtered products: ${filteredProducts.length}');
    
    // Paginación
    final startIndex = _currentPage * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, filteredProducts.length);
    final paginatedProducts = startIndex < filteredProducts.length 
        ? filteredProducts.sublist(startIndex, endIndex)
        : [];

    return paginatedProducts
        .where((product) {
          // Filter out deleted/incomplete products
          final name = product['name']?.toString() ?? '';
          return name.isNotEmpty;
        })
        .map((product) {
      final stock = (product['stock'] as int?) ?? 0;
      final isLowStock = stock > 3 && stock < 10;
      final isOutOfStock = stock <= 3;

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
                          product['name']?.toString() ?? 'Sin nombre',
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
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => _showMultiStoreStockDialog(product),
                child: Container(
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
            ),
          ),
          if (canSeePurchasePrice)
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
                color: _getExpirationColor(product['expiryDate']?.toString()),
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
                  onPressed: canAdjustStock ? () => _showAdjustStockDialog(product) : null,
                  tooltip: canAdjustStock ? 'Ajustar Stock' : 'Solo admin/gerente puede ajustar stock',
                  color: canAdjustStock ? AppColors.textPrimary : AppColors.textSecondary,
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
      builder: (context) => Dialog(
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
              // Header
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryColor,
                      Theme.of(context).primaryColor.withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.all(AppSizes.spacing16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      product['name'] ?? 'Producto',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(AppSizes.spacing20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (product['foto'] != null)
                        Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              product['foto'],
                              height: 240,
                              width: 240,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => 
                                Container(
                                  height: 240,
                                  width: 240,
                                  decoration: BoxDecoration(
                                    color: AppColors.gray100,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.inventory_2_outlined, size: 64),
                                ),
                            ),
                          ),
                        ),
                      if (product['foto'] != null)
                        const SizedBox(height: AppSizes.spacing20),
                      
                      // Stock info
                      GestureDetector(
                        onTap: () => _showMultiStoreStockDialog(product),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.inventory_2_outlined,
                                  color: Theme.of(context).primaryColor,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Stock: ${product['stock']}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '(ver por sucursal)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing16),
                      
                      // Precios
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.gray50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Precio Compra',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatCurrency((product['purchasePrice'] as num)),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Precio Venta',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context).primaryColor.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _formatCurrency((product['salePrice'] as num)),
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      if (product['description'] != null && (product['description'] as String).isNotEmpty) ...[
                        const SizedBox(height: AppSizes.spacing16),
                        Text(
                          'Descripción',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.gray50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            product['description'] as String,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              
              // Actions
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.border,
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(AppSizes.spacing16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spacing20,
                          vertical: AppSizes.spacing12,
                        ),
                      ),
                      child: const Text('Cerrar'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getExpirationColor(String? expirationDate) {
    if (expirationDate == null) return Colors.grey;
    
    try {
      final expDate = DateTime.parse(expirationDate);
      final now = DateTime.now();
      final difference = expDate.difference(now).inDays;
      
      if (difference < 60) {
        return AppColors.error;
      } else if (difference < 90) {
        return AppColors.warning;
      } else {
        return Colors.grey;
      }
    } catch (e) {
      return Colors.grey;
    }
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    final authState = ref.read(authProvider);
    final userRole = authState.currentUser?['role'] ?? '';
    _showProductDialog(product: product, userRole: userRole);
  }

  void _confirmDeleteProduct(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
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
                    bottom: BorderSide(
                      color: AppColors.error.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(AppSizes.spacing20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.warning_rounded, color: AppColors.error, size: 24),
                    ),
                    const SizedBox(width: AppSizes.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Confirmar Eliminación',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Esta acción no se puede deshacer',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.error.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
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
                      '¿Estás seguro de que deseas eliminar "${product['name']}"?',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacing16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outlined, color: AppColors.error, size: 18),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Este producto se eliminará de todas las sucursales de forma permanente.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Actions
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: AppColors.border,
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.all(AppSizes.spacing16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spacing20,
                          vertical: AppSizes.spacing12,
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: AppSizes.spacing12),
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.of(dialogContext).pop();
                        await ref.read(productProvider.notifier).deleteProduct(product['_id']);
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Eliminar Permanentemente'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSizes.spacing20,
                          vertical: AppSizes.spacing12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddProductDialog() {
    _showProductDialog();
  }

  void _showProductDialog({Map<String, dynamic>? product, String userRole = ''}) {
    final categoryState = ref.read(categoryProvider);
    final storeState = ref.read(storeProvider);
    final supplierState = ref.read(supplierProvider);
    
    // Helper function to validate if a value exists in a list
    String? getValidInitialValue(String? value, List<dynamic> items) {
      if (value == null || value.isEmpty) return null;
      final trimmedValue = value.trim();
      
      if (kDebugMode) {
        debugPrint('🔍 Validando valor: "$trimmedValue"');
        debugPrint('   Items disponibles: ${items.length}');
        for (var item in items) {
          final id = (item['_id']?.toString() ?? item['id']?.toString() ?? '').trim();
          final name = item['name']?.toString() ?? 'Sin nombre';
          debugPrint('   - ID: "$id", Nombre: "$name"');
        }
      }
      
      final exists = items.any((item) {
        final id = (item['_id']?.toString() ?? item['id']?.toString() ?? '').trim();
        return id == trimmedValue;
      });
      
      if (kDebugMode) {
        debugPrint('   ✓ Encontrado: $exists');
      }
      
      return exists ? trimmedValue : null;
    }
    
    final isEditing = product != null;
    
    // Role-based field access control for employees
    final isEmployee = userRole == 'employee';
    final isEditingAsEmployee = isEditing && isEmployee;
    final canEditBasicFields = !isEditingAsEmployee;
    final canEditPrice = !isEditingAsEmployee;
    final canEditImage = !isEditingAsEmployee;
    final canEditCategory = !isEditingAsEmployee;
    final canEditSupplier = !isEditingAsEmployee;
    final canEditLocation = !isEditingAsEmployee;
    final canEditWeight = !isEditingAsEmployee;
    
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
    
    var selectedCategoryId = product?['categoryId'] is Map 
        ? (product?['categoryId']?['_id'] as String?)
        : (product?['categoryId'] as String?);
    var selectedSupplierId = product?['supplierId'] is Map 
        ? (product?['supplierId']?['_id'] as String?)
        : (product?['supplierId'] as String?);
    var selectedLocationId = product?['locationId'] is Map 
        ? (product?['locationId']?['_id'] as String?)
        : (product?['locationId'] as String?);
    
    if (kDebugMode) {
      debugPrint('📦 Editando producto: ${product?['name']}');
      debugPrint('   locationId raw: ${product?['locationId']}');
      debugPrint('   selectedLocationId antes de validar: "$selectedLocationId"');
    }
    
    // Ensure IDs are clean (no null or empty values) and exist in current data
    selectedCategoryId = getValidInitialValue(selectedCategoryId, categoryState.categories);
    selectedSupplierId = getValidInitialValue(selectedSupplierId, supplierState.suppliers);
    // Note: selectedLocationId validation is handled by _LocationDropdownField
    
    var selectedExpiryDate = product?['expiryDate'] != null 
        ? DateTime.parse(product!['expiryDate']) 
        : null;

    var isPickingImage = false;

    Future<void> pickImage() async {
      if (isPickingImage) return;
      isPickingImage = true;
      try {
        final XFile? image = await picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1200,
          maxHeight: 1200,
          imageQuality: 85,
        );
        
        if (image != null) {
          // Comprimir imagen usando WebImageCompressionService
          final compressedResult = await WebImageCompressionService.compressImage(
            imageFile: image,
            quality: 0.85,
            width: 1200,
            height: 1200,
          );

          selectedImage = [image];
          imageBytes = compressedResult['base64'] as String;
          imagePreview = imageBytes;
          if (kDebugMode) debugPrint(' Image selected and compressed: ${image.name}');
        }
      } catch (e) {
        if (kDebugMode) debugPrint(' Error picking image: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al seleccionar imagen')),
          );
        }
      } finally {
        isPickingImage = false;
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: 650,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header mejorado con gradiente
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    padding: const EdgeInsets.all(AppSizes.spacing24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isEditing ? 'Editar Producto' : 'Crear Nuevo Producto',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                isEditing 
                                  ? 'Actualiza los detalles del producto'
                                  : 'Completa la información del nuevo producto',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  
                  // Contenido
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.spacing24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sección de Imagen
                        Text(
                          'Imagen del Producto',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacing12),
                        GestureDetector(
                          onTap: canEditImage ? () async {
                            await pickImage();
                            setState(() {});
                          } : null,
                          child: Center(
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                color: Theme.of(dialogContext).primaryColor.withValues(alpha: canEditImage ? 0.1 : 0.05),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Theme.of(dialogContext).primaryColor.withValues(alpha: canEditImage ? 0.4 : 0.2),
                                  width: 2,
                                  style: BorderStyle.solid,
                                ),
                              ),
                              child: imagePreview.isNotEmpty
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Stack(
                                        children: [
                                          Image.network(
                                            imagePreview,
                                            width: 160,
                                            height: 160,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.add_photo_alternate, size: 48, color: Theme.of(dialogContext).primaryColor),
                                                  const SizedBox(height: 8),
                                                  const Text('Seleccionar imagen', style: TextStyle(fontSize: 12)),
                                                ],
                                              );
                                            },
                                          ),
                                          if (canEditImage)
                                            Positioned(
                                              bottom: 8,
                                              right: 8,
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context).primaryColor,
                                                  borderRadius: BorderRadius.circular(8),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.2),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                padding: const EdgeInsets.all(6),
                                                child: const Icon(Icons.edit, color: Colors.white, size: 16),
                                              ),
                                            ),
                                        ],
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Theme.of(dialogContext).primaryColor.withValues(alpha: 0.2),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Icon(Icons.add_photo_alternate, size: 48, color: Theme.of(dialogContext).primaryColor),
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Seleccionar imagen',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacing32),
                        
                        // Sección de Información Básica
                        Text(
                          'Información Básica',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacing12),
                        
                        TextField(
                          controller: nameController,
                          enabled: canEditBasicFields,
                          decoration: InputDecoration(
                            labelText: 'Nombre del Producto *',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.inventory_2_outlined),
                            filled: true,
                            fillColor: canEditBasicFields ? Colors.transparent : AppColors.gray50,
                            helperText: !canEditBasicFields ? 'Solo admin/gerente puede editar' : null,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacing12),

                        TextField(
                          controller: descriptionController,
                          enabled: canEditBasicFields,
                          decoration: InputDecoration(
                            labelText: 'Descripción',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            prefixIcon: const Icon(Icons.description_outlined),
                            filled: true,
                            fillColor: canEditBasicFields ? Colors.transparent : AppColors.gray50,
                            helperText: !canEditBasicFields ? 'Solo admin/gerente puede editar' : null,
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: AppSizes.spacing32),
                        
                        // Sección de Categoría y Proveedor
                        Text(
                          'Clasificación',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacing12),
                        Row(
                          children: [
                            Expanded(
                              child: AbsorbPointer(
                                absorbing: !canEditCategory,
                                child: Opacity(
                                  opacity: canEditCategory ? 1.0 : 0.6,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: selectedCategoryId,
                                    decoration: InputDecoration(
                                      labelText: 'Categoría *',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      prefixIcon: const Icon(Icons.category_outlined),
                                      filled: true,
                                      fillColor: canEditCategory ? Colors.transparent : AppColors.gray50,
                                      helperText: !canEditCategory ? 'Solo admin/gerente' : null,
                                      helperMaxLines: 1,
                                    ),
                                    items: categoryState.categories.map((category) {
                                      final id = (category['_id']?.toString() ?? category['id']?.toString() ?? '').trim();
                                      final name = category['name']?.toString() ?? 'Sin nombre';
                                      return DropdownMenuItem<String>(
                                        value: id,
                                        child: Text(name),
                                      );
                                    }).toList(),
                                    onChanged: canEditCategory ? (value) => setState(() => selectedCategoryId = value) : null,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSizes.spacing12),
                            Expanded(
                              child: AbsorbPointer(
                                absorbing: !canEditSupplier,
                                child: Opacity(
                                  opacity: canEditSupplier ? 1.0 : 0.6,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: selectedSupplierId,
                                    decoration: InputDecoration(
                                      labelText: 'Proveedor *',
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      prefixIcon: const Icon(Icons.local_shipping_outlined),
                                      filled: true,
                                      fillColor: canEditSupplier ? Colors.transparent : AppColors.gray50,
                                      helperText: !canEditSupplier ? 'Solo admin/gerente' : null,
                                      helperMaxLines: 1,
                                    ),
                                    items: supplierState.suppliers.map((supplier) {
                                      final id = (supplier['_id']?.toString() ?? supplier['id']?.toString() ?? '').trim();
                                      final name = supplier['name']?.toString() ?? 'Sin nombre';
                                      return DropdownMenuItem<String>(
                                        value: id,
                                        child: Text(name),
                                      );
                                    }).toList(),
                                    onChanged: canEditSupplier ? (value) => setState(() => selectedSupplierId = value) : null,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.spacing12),

                        AbsorbPointer(
                          absorbing: !canEditLocation,
                          child: Opacity(
                            opacity: canEditLocation ? 1.0 : 0.6,
                            child: _LocationDropdownField(
                              selectedValue: selectedLocationId,
                              onChanged: canEditLocation ? (value) => setState(() => selectedLocationId = value) : (_) {},
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacing32),
                        
                        // Sección de Precios
                        Text(
                          'Precios y Valores',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacing12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: purchasePriceController,
                                enabled: canEditPrice,
                                decoration: InputDecoration(
                                  labelText: 'Precio Compra *',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.attach_money),
                                  filled: true,
                                  fillColor: canEditPrice ? Colors.transparent : AppColors.gray50,
                                  helperText: !canEditPrice ? 'Solo admin' : null,
                                  helperMaxLines: 1,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSizes.spacing12),
                            Expanded(
                              child: TextField(
                                controller: salePriceController,
                                enabled: true,
                                decoration: InputDecoration(
                                  labelText: 'Precio Venta *',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.sell_outlined),
                                  filled: true,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.spacing12),

                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: stockController,
                                decoration: InputDecoration(
                                  labelText: 'Stock Inicial *',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.inventory_outlined),
                                  filled: true,
                                  fillColor: isEditing ? AppColors.gray50 : Colors.transparent,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                enabled: !isEditing,
                              ),
                            ),
                            const SizedBox(width: AppSizes.spacing12),
                            Expanded(
                              child: TextField(
                                controller: weightController,
                                enabled: canEditWeight,
                                decoration: InputDecoration(
                                  labelText: 'Peso (kg)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                  prefixIcon: const Icon(Icons.scale_outlined),
                                  filled: true,
                                  fillColor: canEditWeight ? Colors.transparent : AppColors.gray50,
                                  helperText: !canEditWeight ? 'Solo admin' : null,
                                  helperMaxLines: 1,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSizes.spacing32),
                        
                        // Sección de Caducidad
                        Text(
                          'Vencimiento',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSizes.spacing12),
                        InkWell(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: selectedExpiryDate ?? DateTime.now().add(const Duration(days: 30)),
                              firstDate: DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 3650)),
                            );
                            if (date != null) {
                              setState(() => selectedExpiryDate = date);
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Fecha de Caducidad *',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              prefixIcon: const Icon(Icons.event_outlined),
                              filled: true,
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
                        const SizedBox(height: AppSizes.spacing16),

                        // Notas informativas
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.info_outlined, size: 16, color: AppColors.info),
                                  SizedBox(width: 8),
                                  Text(
                                    'Campos requeridos: * ',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              if (isEditing) ...[
                                const SizedBox(height: 8),
                                const Row(
                                  children: [
                                    Icon(Icons.warning_amber, size: 16, color: AppColors.warning),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'El stock se ajusta en inventario',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.warning,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Botones de acción mejorados
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: AppColors.border,
                          width: 1,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.all(AppSizes.spacing16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            if (context.mounted) {
                              Navigator.of(context).pop();
                            }
                          },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.spacing24,
                              vertical: AppSizes.spacing12,
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSizes.spacing12),
                        ElevatedButton.icon(
                          onPressed: isLoading ? null : () async {
                // For employees editing existing products, validate only editable fields
                if (isEditingAsEmployee) {
                  if (salePriceController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('El precio de venta es requerido')),
                    );
                    return;
                  }
                  if (selectedExpiryDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Seleccione la fecha de caducidad')),
                    );
                    return;
                  }
                  
                  final salePrice = double.tryParse(salePriceController.text.trim());
                  if (salePrice == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('El precio de venta debe ser un número válido')),
                    );
                    return;
                  }
                } else {
                  // For admins/managers creating or editing products
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
                  if (selectedLocationId == null || selectedLocationId!.isEmpty) {
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
                  if (isEditingAsEmployee) {
                    // Employees can only update sale price and expiry date
                    success = await ref.read(productProvider.notifier).updateProduct(
                      id: product['_id'],
                      salePrice: salePrice,
                      expiryDate: selectedExpiryDate,
                    );
                  } else {
                    // Admins/managers can update all fields
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
                  }
                } else {
                  final stock = int.tryParse(stockController.text.trim()) ?? 0;
                  final currentStore = storeState.currentStore;
                  
                  if (currentStore == null) {
                    if (!context.mounted) {
                      setState(() => isLoading = false);
                      return;
                    }
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
                  if (!context.mounted) {
                    if (kDebugMode) debugPrint('⚠️ Context is not mounted after create');
                    return;
                  }
                  if (kDebugMode) debugPrint('✅ Product created successfully, closing dialog...');
                  Navigator.of(context).pop();
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (kDebugMode) debugPrint('📦 Reloading products list...');
                  try {
                    await ref.read(productProvider.notifier).loadProductsForCurrentStore();
                    if (kDebugMode) debugPrint('✅ Products list reloaded');
                  } catch (e) {
                    if (kDebugMode) {
                      debugPrint('⚠️ Error reloading products: $e');
                    }
                  }
                } else {
                  // Mostrar error si la creación falló
                  if (!context.mounted) return;
                  final errorMessage = ref.read(productProvider).errorMessage;
                  if (kDebugMode) {
                    debugPrint('❌ Product creation failed');
                    debugPrint('   errorMessage: $errorMessage');
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(errorMessage.isNotEmpty ? errorMessage : 'Error al crear el producto'),
                      duration: const Duration(seconds: 5),
                    ),
                  );
                }
              },
                          icon: isLoading 
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(isEditing ? Icons.update_outlined : Icons.add_rounded),
                          label: Text(
                            isEditing ? 'Actualizar Producto' : 'Crear Producto',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSizes.spacing24,
                              vertical: AppSizes.spacing12,
                            ),
                            elevation: isLoading ? 0 : 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
    
    final authState = ref.read(authProvider);
    final userRole = authState.currentUser?['role'] ?? '';
    final isEmployee = userRole == 'employee';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
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
                          'Ajustar Stock - $productName',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                // CONTENT
                Padding(
                  padding: const EdgeInsets.all(AppSizes.spacing20),
                  child: SizedBox(
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
                if (isEmployee)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outlined, color: Colors.blue, size: 18),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Solo puedes agregar stock',
                            style: TextStyle(fontSize: 12, color: Colors.blue),
                          ),
                        ),
                      ],
                    ),
                  )
                else
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
                if (!isEmployee)
                  const SizedBox(height: 16),
                if (isEmployee)
                  const SizedBox(height: 16),
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
                ),
                // FOOTER
                Container(
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: AppColors.border)),
                  ),
                  padding: const EdgeInsets.all(AppSizes.spacing16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: Theme.of(context).primaryColor,
                        ),
                        child: const Text('Cancelar'),
                      ),
                      const SizedBox(width: 8),
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

                          if (success) {
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _generateQrLabels(Map<String, dynamic> product) {
    final productId = product['_id']?.toString() ?? 'N/A';
    final productName = product['name']?.toString() ?? 'Producto';

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
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
                        'QR - $productName',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
              ),
              // CONTENT
              Padding(
                padding: const EdgeInsets.all(AppSizes.spacing20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
            Container(
              width: 200,
              height: 200,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
                color: Colors.white,
              ),
              child: BarcodeWidget(
                barcode: Barcode.qrCode(),
                data: productId,
                width: 184,
                height: 184,
              ),
            ),
            const SizedBox(height: 8),
                      Text(
                        productId,
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
              ),
              // FOOTER
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                padding: const EdgeInsets.all(AppSizes.spacing16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                      child: const Text('Cerrar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download),
                      label: const Text('Descargar PNG'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        try {
                          await PdfService.downloadProductQrImage(product: product);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('QR descargado correctamente'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error al descargar QR: $e')),
                            );
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
    );
  }

  void _showMultiStoreStockDialog(Map<String, dynamic> product) {
    final productName = product['name'] ?? 'Producto';
    final productId = product['_id'];
    var isLoading = true;
    List<Map<String, dynamic>> stocks = [];
    String? errorMessage;
    late StateSetter setDialogState;
    
    // Verificar si el usuario es admin o gerente
    final authState = ref.read(authProvider);
    final userRole = authState.currentUser?['role'] ?? '';
    final canSeePrices = userRole == 'admin' || userRole == 'manager';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          setDialogState = setState;
          
          // Definir columnas según el rol
          final columns = canSeePrices
              ? const [
                  DataColumn(label: Text('Sucursal')),
                  DataColumn(label: Text('Stock')),
                  DataColumn(label: Text('Precio Venta')),
                  DataColumn(label: Text('Precio Compra')),
                ]
              : const [
                  DataColumn(label: Text('Sucursal')),
                  DataColumn(label: Text('Stock')),
                ];
          
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Container(
              width: canSeePrices ? 750 : 450,
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
                            'Stock en Todas las Tiendas - $productName',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                  // CONTENT
                  Padding(
                    padding: const EdgeInsets.all(AppSizes.spacing20),
                    child: SizedBox(
                      width: canSeePrices ? 700 : 400,
                      child: isLoading
                  ? const Center(
                      child: CircularProgressIndicator(),
                    )
                  : errorMessage != null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: AppColors.error,
                              size: 48,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              errorMessage!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        )
                      : stocks.isEmpty
                          ? const Center(
                              child: Text('Sin datos de stock'),
                            )
                          : SingleChildScrollView(
                              child: DataTable(
                                columns: columns,
                                rows: stocks.map((stock) {
                                  if (canSeePrices) {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            stock['storeName'] ?? 'Sin tienda',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            stock['stock'].toString(),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: (stock['stock'] as int) <= 0 
                                                  ? AppColors.error 
                                                  : Colors.green,
                                            ),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '\$${(stock['salePrice'] ?? 0).toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            '\$${(stock['purchasePrice'] ?? 0).toStringAsFixed(2)}',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    );
                                  } else {
                                    return DataRow(
                                      cells: [
                                        DataCell(
                                          Text(
                                            stock['storeName'] ?? 'Sin tienda',
                                            style: const TextStyle(fontSize: 13),
                                          ),
                                        ),
                                        DataCell(
                                          Text(
                                            stock['stock'].toString(),
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: (stock['stock'] as int) <= 0 
                                                  ? AppColors.error 
                                                  : Colors.green,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  }
                                }).toList(),
                              ),
                            ),
                    ),
                  ),
                  // FOOTER
                  Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: AppColors.border)),
                    ),
                    padding: const EdgeInsets.all(AppSizes.spacing16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cerrar'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );

    // Cargar datos de stock después de que el diálogo esté abierto
    _loadMultiStoreStocks(
      productId,
      () {
        isLoading = false;
        setDialogState(() {});
      },
      (newStocks, error) {
        if (error != null) {
          errorMessage = error;
        } else {
          stocks = newStocks;
        }
      },
    );
  }

  Future<void> _loadMultiStoreStocks(
    String productId,
    VoidCallback onLoadComplete,
    void Function(List<Map<String, dynamic>>, String?) callback,
  ) async {
    try {
      final result = await ref.read(productProvider.notifier).getProductStocks(productId);
      
      if (result['success']) {
        final stocks = (result['data'] as List).cast<Map<String, dynamic>>();
        callback(stocks, null);
      } else {
        callback([], result['message'] ?? 'Error cargando stock');
      }
    } catch (e) {
      callback([], 'Error de conexión: $e');
    } finally {
      onLoadComplete();
    }
  }
}

/// Dropdown de ubicación que carga ubicaciones frescas cada vez que se monta
/// (es decir, cada vez que el diálogo se abre). Al usar initState + forceRefresh
/// se evita la condición de carrera entre _loadData y el diálogo.
class _LocationDropdownField extends ConsumerStatefulWidget {
  final String? selectedValue;
  final ValueChanged<String?> onChanged;

  const _LocationDropdownField({
    required this.selectedValue,
    required this.onChanged,
  });

  @override
  ConsumerState<_LocationDropdownField> createState() =>
      _LocationDropdownFieldState();
}

class _LocationDropdownFieldState extends ConsumerState<_LocationDropdownField> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref
            .read(locationProvider.notifier)
            .loadLocationsForCurrentStore(forceRefresh: true);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final locations = ref.watch(locationProvider).locations;
    final validValue = locations.any((l) =>
            (l['_id']?.toString() ?? l['id']?.toString() ?? '').trim() ==
            widget.selectedValue)
        ? widget.selectedValue
        : null;

    return DropdownButtonFormField<String>(
      initialValue: validValue,
      decoration: const InputDecoration(
        labelText: 'Ubicación *',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.location_on_outlined),
      ),
      items: locations.map((location) {
        final id =
            (location['_id']?.toString() ?? location['id']?.toString() ?? '')
                .trim();
        final name = location['name']?.toString() ?? 'Sin nombre';
        return DropdownMenuItem<String>(
          value: id,
          child: Text(name),
        );
      }).toList(),
      onChanged: widget.onChanged,
    );
  }
}

