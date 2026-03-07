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
import '../../core/utils/app_snackbar.dart';
import '../../shared/services/pdf_service.dart';
import '../../shared/services/web_image_compression_service.dart';
import '../../shared/services/input_validator.dart';
import '../../shared/services/debouncer.dart';
import '../../shared/widgets/pagination_bar.dart';
import '../../core/utils/responsive.dart';

class ProductsPage extends ConsumerStatefulWidget {
  const ProductsPage({super.key});

  @override
  ConsumerState<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends ConsumerState<ProductsPage> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer();
  String _searchQuery = '';
  bool _hasInitialized = false;
  bool _filterLowStock = false;
  bool _filterExpiringSoon = false;

  @override
  void initState() {
    super.initState();
    // Cargar datos en primer acceso
    _loadData();
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _searchController.dispose();
    super.dispose();
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
        final locationState = ref.read(locationProvider);
        
        // CRITICAL: Load categories and suppliers (needed for dropdowns)
        final criticalFutures = <Future>[];
        if (categoryState.categories.isEmpty) {
          criticalFutures.add(ref.read(categoryProvider.notifier).loadCategories());
        }
        if (supplierState.suppliers.isEmpty) {
          criticalFutures.add(ref.read(supplierProvider.notifier).loadSuppliers());
        }
        
        // PARALLEL: Load locations only
        final parallelFutures = <Future>[];
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
                    _debouncer.run(() {
                      if (mounted) {
                        setState(() {
                          _searchQuery = value;
                        });
                      }
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
                  });
                },
                style: IconButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing24),
          
          Consumer(
            builder: (context, ref, child) {
              final productState = ref.watch(productProvider);
              final authState = ref.watch(authProvider);
              final userRole = authState.currentUser?['role'] ?? '';
              final canSeePurchasePrice = userRole == 'admin' || userRole == 'manager';
              
      if (kDebugMode) debugPrint(' ProductsPage: Consumer rebuilding...');
      if (kDebugMode) debugPrint('   - isLoading: ${productState.isLoading}');
      if (kDebugMode) debugPrint('   - products length: ${productState.products.length}');
              
              final r = Responsive(context);
              if (productState.isLoading) {
                return Card(
                  child: SizedBox(
                    height: r.tableHeight(),
                    child: Center(
                      child: LoadingIndicator(
                        message: 'Cargando productos...',
                      ),
                    ),
                  ),
                );
              }

              if (productState.products.isEmpty) {
                return SizedBox(
                  height: r.tableHeight(),
                  child: Card(
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
                  ),
                );
              }

              return Card(
                child: SizedBox(
                  height: r.tableHeight(),
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
                            rows: _buildProductRows(productState.products, canSeePurchasePrice),
                          ),
                        ),
                      ),
                      // Pagination Controls (server-driven)
                      PaginationBar(
                        currentPage: productState.currentPage,
                        totalPages: productState.totalPages,
                        totalItems: productState.totalItems,
                        visibleItems: productState.products.length,
                        itemLabel: 'productos',
                        onPageChanged: (newPage) {
                          ref.read(productProvider.notifier).loadProducts(
                            page: newPage,
                            forceRefresh: true,
                          );
                        },
                      ),
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

  // _buildProductPagination removed — using PaginationBar widget instead

  List<DataRow2> _buildProductRows(List<dynamic> products, bool canSeePurchasePrice) {
      if (kDebugMode) debugPrint(' ProductsPage: _buildProductRows called');
      if (kDebugMode) debugPrint('   - Total products: ${products.length}');
      if (kDebugMode) debugPrint('   - Search query: "$_searchQuery"');
    
    // Client-side filtering (search + stock + expiry) on server-paginated data
    final filteredProducts = products
        .where((p) {
          final name = p['name']?.toString() ?? '';
          final description = p['description']?.toString() ?? '';
          final matchesSearch = _searchQuery.isEmpty || 
                         name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                         description.toLowerCase().contains(_searchQuery.toLowerCase());
          
          final stock = (p['stock'] as int?) ?? 0;
          final matchesLowStock = !_filterLowStock || stock <= 3;
          
          final expiryDate = p['expiryDate'];
          bool matchesExpiringSoon = true;
          if (_filterExpiringSoon && expiryDate != null) {
            try {
              final expDate = DateTime.parse(expiryDate);
              final difference = expDate.difference(DateTime.now()).inDays;
              matchesExpiringSoon = difference < 60;
            } catch (e) {
              matchesExpiringSoon = false;
            }
          }
          
          return matchesSearch && matchesLowStock && matchesExpiringSoon;
        })
        .toList();

      if (kDebugMode) debugPrint('   - Filtered products: ${filteredProducts.length}');

    return filteredProducts
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

  /// Show product preview with full details (modern design)
  void _showProductPreview(Map<String, dynamic> product) {
    final stock = (product['stock'] as int?) ?? 0;
    final isOutOfStock = stock <= 3;
    final isLowStock = stock > 3 && stock < 10;
    final stockColor = isOutOfStock
        ? AppColors.error
        : isLowStock
            ? AppColors.warning
            : AppColors.success;
    final stockLabel = isOutOfStock
        ? 'Stock Crítico'
        : isLowStock
            ? 'Stock Bajo'
            : 'En Stock';

    final authState = ref.read(authProvider);
    final userRole = authState.currentUser?['role'] ?? '';
    final canSeePurchasePrice = userRole == 'admin' || userRole == 'manager';

    final purchasePrice = (product['purchasePrice'] as num?) ?? 0;
    final salePrice = (product['salePrice'] as num?) ?? 0;
    final margin = purchasePrice > 0
        ? ((salePrice - purchasePrice) / purchasePrice * 100).toStringAsFixed(1)
        : '—';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        insetPadding: Responsive(ctx).dialogInsetPadding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive(ctx).dialogWidth(preferred: 480),
            maxHeight: Responsive(ctx).dialogMaxHeight(preferred: 700),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Hero Image Section ──
              Stack(
                children: [
                  // Image or placeholder
                  SizedBox(
                    width: double.infinity,
                    height: 220,
                    child: product['foto'] != null
                        ? Image.network(
                            product['foto'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _previewImagePlaceholder(),
                          )
                        : _previewImagePlaceholder(),
                  ),
                  // Gradient overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.55),
                          ],
                          stops: const [0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Close button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black38,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => Navigator.pop(ctx),
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                  ),
                  // Stock badge
                  Positioned(
                    top: 12,
                    left: 12,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(ctx);
                        _showMultiStoreStockDialog(product);
                      },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: stockColor.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isOutOfStock
                                    ? Icons.error_outline
                                    : isLowStock
                                        ? Icons.warning_amber_rounded
                                        : Icons.check_circle_outline,
                                color: Colors.white,
                                size: 14,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '$stockLabel · $stock uds',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Product name over image
                  Positioned(
                    bottom: 12,
                    left: 16,
                    right: 16,
                    child: Text(
                      product['name'] ?? 'Producto',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),

              // ── Body ──
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Price cards
                      Row(
                        children: [
                          if (canSeePurchasePrice)
                            Expanded(
                              child: _previewPriceCard(
                                label: 'Compra',
                                value: _formatCurrency(purchasePrice),
                                icon: Icons.shopping_bag_outlined,
                                color: AppColors.info,
                              ),
                            ),
                          if (canSeePurchasePrice) const SizedBox(width: 10),
                          Expanded(
                            child: _previewPriceCard(
                              label: 'Venta',
                              value: _formatCurrency(salePrice),
                              icon: Icons.sell_outlined,
                              color: AppColors.primary,
                            ),
                          ),
                          if (canSeePurchasePrice) ...[
                            const SizedBox(width: 10),
                            Expanded(
                              child: _previewPriceCard(
                                label: 'Margen',
                                value: '$margin%',
                                icon: Icons.trending_up,
                                color: AppColors.success,
                              ),
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Info rows
                      _previewInfoRow(
                        Icons.category_outlined,
                        'Categoría',
                        _getCategoryName(product['categoryId']),
                      ),
                      if (product['supplierId'] is Map)
                        _previewInfoRow(
                          Icons.local_shipping_outlined,
                          'Proveedor',
                          product['supplierId']['name']?.toString() ?? 'Sin proveedor',
                        ),
                      if (product['locationId'] is Map)
                        _previewInfoRow(
                          Icons.location_on_outlined,
                          'Ubicación',
                          product['locationId']['name']?.toString() ?? 'Sin ubicación',
                        ),
                      if (product['weight'] != null && product['weight'] != 0)
                        _previewInfoRow(
                          Icons.scale_outlined,
                          'Peso',
                          '${product['weight']} kg',
                        ),
                      _previewInfoRow(
                        Icons.event_outlined,
                        'Caducidad',
                        product['expiryDate'] != null
                            ? DateFormat('dd MMM yyyy').format(DateTime.parse(product['expiryDate']))
                            : 'No definida',
                        valueColor: _getExpirationColor(product['expiryDate']),
                      ),

                      // Description
                      if (product['description'] != null &&
                          (product['description'] as String).isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.gray50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.gray200),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.description_outlined, size: 14, color: AppColors.gray500),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Descripción',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.gray500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                product['description'] as String,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.gray700,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // ── Quick Actions ──
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.gray50,
                  border: Border(top: BorderSide(color: AppColors.gray200)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _previewAction(
                      icon: Icons.qr_code_2,
                      label: 'QR',
                      onTap: () {
                        Navigator.pop(ctx);
                        _generateQrLabels(product);
                      },
                    ),
                    _previewAction(
                      icon: Icons.add_shopping_cart,
                      label: 'Stock',
                      onTap: () {
                        Navigator.pop(ctx);
                        _showAdjustStockDialog(product);
                      },
                    ),
                    _previewAction(
                      icon: Icons.edit_outlined,
                      label: 'Editar',
                      color: AppColors.primary,
                      onTap: () {
                        Navigator.pop(ctx);
                        _showEditProductDialog(product);
                      },
                    ),
                    _previewAction(
                      icon: Icons.delete_outline,
                      label: 'Eliminar',
                      color: AppColors.error,
                      onTap: () {
                        Navigator.pop(ctx);
                        _confirmDeleteProduct(product);
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

  Widget _previewImagePlaceholder() {
    return Container(
      color: AppColors.gray100,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 56, color: AppColors.gray400),
            const SizedBox(height: 8),
            Text('Sin imagen', style: TextStyle(color: AppColors.gray400, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _previewPriceCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: color.withValues(alpha: 0.7), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _previewInfoRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Text(
            '$label:',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.gray500,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? AppColors.gray800,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _previewAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? AppColors.gray600;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 11, color: c, fontWeight: FontWeight.w500)),
          ],
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
    _showProductDialog(product: product);
  }

  void _confirmDeleteProduct(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('¿Estás seguro de eliminar "${product['name']}"?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_outlined, color: AppColors.error, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este producto se eliminará de todas las sucursales permanentemente.',
                      style: TextStyle(fontSize: 12, color: AppColors.error),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(productProvider.notifier).deleteProduct(product['_id']);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Eliminar Permanentemente'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    _showProductDialog();
  }

  Future<void> _showProductDialog({Map<String, dynamic>? product}) async {
    // Cargar ubicaciones de la tienda actual ANTES de mostrar el dialog
    // Esto detectará automáticamente si cambió la tienda
    await ref.read(locationProvider.notifier).loadLocationsForCurrentStore();
    
    if (!mounted) return;
    
    final categoryState = ref.read(categoryProvider);
    final locationState = ref.read(locationProvider);
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
    selectedLocationId = getValidInitialValue(selectedLocationId, locationState.locations);
    
    if (kDebugMode) {
      debugPrint('   selectedLocationId después de validar: "$selectedLocationId"');
    }
    
    var selectedExpiryDate = product?['expiryDate'] != null 
        ? DateTime.parse(product!['expiryDate']) 
        : null;

    Future<void> pickImage() async {
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
          AppSnackbar.error(context, 'Error al seleccionar imagen');
        }
      }
    }

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Editar Producto' : 'Nuevo Producto'),
          content: SizedBox(
            width: Responsive(context).dialogWidth(preferred: 600),
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
                    child: Center(
                      child: Container(
                        width: 144,
                        height: 144,
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
                                  width: 144,
                                  height: 144,
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
                    initialValue: selectedCategoryId,
                    decoration: const InputDecoration(
                      labelText: 'Categoría *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: categoryState.categories.map((category) {
                      final id = (category['_id']?.toString() ?? category['id']?.toString() ?? '').trim();
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
                    initialValue: selectedSupplierId,
                    decoration: const InputDecoration(
                      labelText: 'Proveedor *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.local_shipping_outlined),
                    ),
                    items: supplierState.suppliers.map((supplier) {
                      final id = (supplier['_id']?.toString() ?? supplier['id']?.toString() ?? '').trim();
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
                    initialValue: selectedLocationId,
                    decoration: const InputDecoration(
                      labelText: 'Ubicación *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    items: locationState.locations.map((location) {
                      final id = (location['_id']?.toString() ?? location['id']?.toString() ?? '').trim();
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
                  AppSnackbar.warning(context, 'El nombre es requerido');
                  return;
                }
                // Injection protection
                if (InputValidator.containsHtmlOrScript(nameController.text) ||
                    InputValidator.containsHtmlOrScript(descriptionController.text)) {
                  AppSnackbar.warning(context, 'Entrada no válida detectada');
                  return;
                }
                if (selectedCategoryId == null) {
                  AppSnackbar.warning(context, 'Seleccione una categoría');
                  return;
                }
                if (selectedSupplierId == null) {
                  AppSnackbar.warning(context, 'Seleccione un proveedor');
                  return;
                }
                if (selectedLocationId == null || selectedLocationId!.isEmpty) {
                  AppSnackbar.warning(context, 'Seleccione una ubicación');
                  return;
                }
                if (purchasePriceController.text.trim().isEmpty) {
                  AppSnackbar.warning(context, 'El precio de compra es requerido');
                  return;
                }
                if (salePriceController.text.trim().isEmpty) {
                  AppSnackbar.warning(context, 'El precio de venta es requerido');
                  return;
                }
                if (!isEditing && stockController.text.trim().isEmpty) {
                  AppSnackbar.warning(context, 'El stock inicial es requerido');
                  return;
                }
                if (selectedExpiryDate == null) {
                  AppSnackbar.warning(context, 'Seleccione la fecha de caducidad');
                  return;
                }

                setState(() => isLoading = true);
                final purchasePrice = double.tryParse(purchasePriceController.text.trim());
                final salePrice = double.tryParse(salePriceController.text.trim());
                
                if (purchasePrice == null || salePrice == null) {
                  AppSnackbar.warning(context, 'Los precios deben ser números válidos');
                  setState(() => isLoading = false);
                  return;
                }

                if (salePrice <= purchasePrice) {
                  AppSnackbar.warning(context, 'El precio de venta debe ser mayor al precio de compra');
                  setState(() => isLoading = false);
                  return;
                }

                bool success;
                if (isEditing) {
                  success = await ref.read(productProvider.notifier).updateProduct(
                    id: product['_id'],
                    name: InputValidator.sanitize(nameController.text.trim()),
                    description: descriptionController.text.trim().isEmpty 
                        ? null 
                        : InputValidator.sanitize(descriptionController.text.trim()),
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
                    if (!context.mounted) {
                      setState(() => isLoading = false);
                      return;
                    }
                    AppSnackbar.warning(context, 'No hay tienda seleccionada');
                    setState(() => isLoading = false);
                    return;
                  }

                  success = await ref.read(productProvider.notifier).createProduct(
                    storeId: currentStore['_id'],
                    name: InputValidator.sanitize(nameController.text.trim()),
                    description: descriptionController.text.trim().isEmpty 
                        ? null 
                        : InputValidator.sanitize(descriptionController.text.trim()),
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
                  AppSnackbar.error(context, errorMessage.isNotEmpty ? errorMessage : 'Error al crear el producto');
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
            width: Responsive(context).dialogWidth(preferred: 400),
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
                  AppSnackbar.warning(context, 'Ingresa una cantidad válida');
                  return;
                }

                final newStock = isAdding 
                    ? currentStock + adjustment 
                    : currentStock - adjustment;

                if (newStock < 0) {
                  AppSnackbar.warning(context, 'El stock no puede ser negativo');
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
                    Navigator.of(context).pop();
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
    );
  }

  Future<void> _generateQrLabels(Map<String, dynamic> product) async {
    try {
      AppSnackbar.info(context, 'Generando PDF con QRs...');

      await PdfService.generateProductQrLabels(product: product);

      if (!mounted) return;
      AppSnackbar.success(context, 'PDF con 10 QRs descargado correctamente');
    } catch (e) {
      String errorMessage = 'Error al generar PDF';
      
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('path') || errorStr.contains('storage')) {
        errorMessage = 'No se pudo acceder al almacenamiento. Verifica los permisos.';
      } else if (errorStr.contains('permission')) {
        errorMessage = 'Permiso denegado. Habilita permisos de almacenamiento.';
      }
      
      if (!mounted) return;
      AppSnackbar.error(context, errorMessage);
    }
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
          
          return AlertDialog(
            title: Text('Stock en Todas las Tiendas - $productName'),
            content: SizedBox(
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
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cerrar'),
              ),
            ],
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
    Function(List<Map<String, dynamic>>, String?) callback,
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

