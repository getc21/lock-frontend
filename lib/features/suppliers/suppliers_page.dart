import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:data_table_2/data_table_2.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/providers/riverpod/supplier_form_notifier.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/providers/riverpod/supplier_notifier.dart';
import '../../shared/providers/riverpod/product_notifier.dart';
import '../../shared/providers/riverpod/currency_notifier.dart';

class SuppliersPage extends ConsumerStatefulWidget {
  const SuppliersPage({super.key});

  @override
  ConsumerState<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends ConsumerState<SuppliersPage> {
  bool _hasInitialized = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized && mounted) {
        _hasInitialized = true;

        ref.read(supplierProvider.notifier).loadSuppliers();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {


    return Consumer(
      builder: (context, ref, _) {
        final supplierState = ref.watch(supplierProvider);
        ref.watch(currencyProvider); // Permite reconstruir cuando cambia la moneda

        return DashboardLayout(
      currentRoute: '/suppliers',
      title: 'Proveedores',
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Proveedores',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacing8),
                    Text(
                      '${supplierState.suppliers.length} proveedores registrados',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => _showSupplierDialog(context),
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Nuevo Proveedor'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.spacing24,
                      vertical: AppSizes.spacing16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing16),
            // Search Bar
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar proveedores...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
              ],
            ),
            if (supplierState.isLoading)
              SizedBox(
                height: 600,
                child: Card(
                  child: Center(
                    child: LoadingIndicator(
                      message: 'Cargando proveedores...',
                    ),
                  ),
                ),
              )
            else if (supplierState.errorMessage.isNotEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.spacing48),
                  child: Column(
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                      const SizedBox(height: AppSizes.spacing16),
                      Text(
                        'Error: ${supplierState.errorMessage}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: AppColors.error,
                        ),
                      ),
                      const SizedBox(height: AppSizes.spacing16),
                      ElevatedButton(
                        onPressed: () => ref.read(supplierProvider.notifier).loadSuppliers(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              )
            else if (supplierState.suppliers.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSizes.spacing48),
                  child: Text(
                    'No hay proveedores registrados',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: 600,
                  child: DataTable2(
                    columnSpacing: AppSizes.spacing12,
                    horizontalMargin: AppSizes.spacing12,
                    minWidth: 900,
                    columns: const [
                      DataColumn2(
                        label: Text('Proveedor'),
                        size: ColumnSize.L,
                      ),
                      DataColumn2(
                        label: Text('Contacto'),
                        size: ColumnSize.M,
                      ),
                      DataColumn2(
                        label: Text('Teléfono'),
                        size: ColumnSize.M,
                      ),
                      DataColumn2(
                        label: Text('Email'),
                        size: ColumnSize.L,
                      ),
                      DataColumn2(
                        label: Text('Acciones'),
                        size: ColumnSize.S,
                      ),
                    ],
                    rows: supplierState.suppliers
                        .where((s) => _searchQuery.isEmpty ||
                            ((s['name'] as String?) ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
                            ((s['contactName'] as String?) ?? '').toLowerCase().contains(_searchQuery.toLowerCase()))
                        .toList()
                        .map((supplier) {
                      return DataRow2(
                        onTap: () => _showSupplierProducts(context, supplier),
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                // Imagen o icono del proveedor
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: supplier['foto'] != null && supplier['foto'].toString().isNotEmpty
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(8),
                                          child: Image.network(
                                            supplier['foto'],
                                            width: 40,
                                            height: 40,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Icon(
                                                Icons.store_outlined,
                                                color: Theme.of(context).primaryColor,
                                                size: 24,
                                              );
                                            },
                                          ),
                                        )
                                      : Icon(
                                          Icons.store_outlined,
                                          color: Theme.of(context).primaryColor,
                                          size: 24,
                                        ),
                                ),
                                const SizedBox(width: 12),
                                // Nombre y dirección
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        supplier['name'] ?? 'Sin nombre',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (supplier['address'] != null && supplier['address'].toString().isNotEmpty)
                                        Flexible(
                                          child: Text(
                                            supplier['address'],
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textSecondary,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          DataCell(
                            Text(supplier['contactName'] ?? '-'),
                          ),
                          DataCell(
                            supplier['contactPhone'] != null && supplier['contactPhone'].toString().isNotEmpty
                                ? Row(
                                    children: [
                                      const Icon(Icons.phone_outlined, size: 16, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Text(supplier['contactPhone']),
                                    ],
                                  )
                                : const Text('-'),
                          ),
                          DataCell(
                            supplier['contactEmail'] != null && supplier['contactEmail'].toString().isNotEmpty
                                ? Row(
                                    children: [
                                      const Icon(Icons.email_outlined, size: 16, color: AppColors.textSecondary),
                                      const SizedBox(width: 4),
                                      Expanded(
                                        child: Text(
                                          supplier['contactEmail'],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text('-'),
                          ),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  onPressed: () => _showSupplierDialog(
                                    context,
                                    supplier: supplier,
                                  ),
                                  tooltip: 'Editar',
                                  color: AppColors.textPrimary,
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  onPressed: () => _showDeleteDialog(
                                    context,
                                    supplier['_id'] ?? supplier['id'] ?? '',
                                    supplier['name'] ?? 'Sin nombre',
                                  ),
                                  tooltip: 'Eliminar',
                                  color: AppColors.textPrimary,
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
          ],
        ),
      ),
      );
    },
  );
  }

  String _formatCurrency(num value) {
    final currencyNotifier = ref.read(currencyProvider.notifier);
    return '${currencyNotifier.symbol}${(value as double).toStringAsFixed(2)}';
  }

  void _showSupplierDialog(
    BuildContext context, {
    Map<String, dynamic>? supplier,
  }) {
    final nameController = TextEditingController(text: supplier?['name'] ?? '');
    final contactPersonController = TextEditingController(text: supplier?['contactName'] ?? '');
    final phoneController = TextEditingController(text: supplier?['contactPhone'] ?? '');
    final emailController = TextEditingController(text: supplier?['contactEmail'] ?? '');
    final addressController = TextEditingController(text: supplier?['address'] ?? '');

    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final formState = ref.watch(supplierFormProvider(supplier));
          final formNotifier = ref.watch(supplierFormProvider(supplier).notifier);

          return AlertDialog(
            title: Text(supplier == null ? 'Nuevo Proveedor' : 'Editar Proveedor'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Selector de imagen
                    GestureDetector(
                      onTap: () async {
                        try {
                          await formNotifier.selectImage();
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Error al seleccionar imagen')),
                            );
                          }
                        }
                      },
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                            width: 2,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: formState.imagePreview.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(
                                  formState.imagePreview,
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate, size: 40, color: Theme.of(context).primaryColor),
                                        const SizedBox(height: 8),
                                        Text('Seleccionar imagen', style: TextStyle(fontSize: 12)),
                                      ],
                                    );
                                  },
                                ),
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate, size: 40, color: Theme.of(context).primaryColor),
                                  const SizedBox(height: 8),
                                  Text('Seleccionar imagen', style: TextStyle(fontSize: 12)),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacing24),
                    TextField(
                      controller: nameController,
                      enabled: !formState.isLoading,
                      onChanged: formNotifier.setName,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.business_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacing16),
                    TextField(
                      controller: contactPersonController,
                      enabled: !formState.isLoading,
                      onChanged: formNotifier.setContactName,
                      decoration: const InputDecoration(
                        labelText: 'Persona de Contacto',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacing16),
                    TextField(
                      controller: phoneController,
                      enabled: !formState.isLoading,
                      onChanged: formNotifier.setContactPhone,
                      decoration: const InputDecoration(
                        labelText: 'Teléfono',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: AppSizes.spacing16),
                    TextField(
                      controller: emailController,
                      enabled: !formState.isLoading,
                      onChanged: formNotifier.setContactEmail,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: AppSizes.spacing16),
                    TextField(
                      controller: addressController,
                      enabled: !formState.isLoading,
                      onChanged: formNotifier.setAddress,
                      decoration: const InputDecoration(
                        labelText: 'Dirección',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: AppSizes.spacing8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '* Campos requeridos',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: formState.isLoading ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: formState.isLoading
                    ? null
                    : () async {
                        final name = nameController.text.trim();

                        if (name.isEmpty) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('El nombre es requerido')),
                            );
                          }
                          return;
                        }

                        if (context.mounted) {
                          formNotifier.setLoading(true);
                        }

                        try {
                          bool success;
                          if (supplier == null) {
                            success = await ref.read(supplierProvider.notifier).createSupplier(
                              name: name,
                              contactPerson: contactPersonController.text.trim().isEmpty ? null : contactPersonController.text.trim(),
                              phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                              email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                              address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                              imageFile: formState.selectedImage,
                              imageBytes: formState.imageBytes,
                            );
                          } else {
                            success = await ref.read(supplierProvider.notifier).updateSupplier(
                              id: supplier['_id'] ?? supplier['id'] ?? '',
                              name: name,
                              contactPerson: contactPersonController.text.trim().isEmpty ? null : contactPersonController.text.trim(),
                              phone: phoneController.text.trim().isEmpty ? null : phoneController.text.trim(),
                              email: emailController.text.trim().isEmpty ? null : emailController.text.trim(),
                              address: addressController.text.trim().isEmpty ? null : addressController.text.trim(),
                              imageFile: formState.selectedImage,
                              imageBytes: formState.imageBytes,
                            );
                          }

                          if (context.mounted) {
                            formNotifier.setLoading(false);
                            if (success) {
                              Navigator.of(context).pop();
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            formNotifier.setLoading(false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: formState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(supplier == null ? 'Crear' : 'Actualizar'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    String supplierId,
    String supplierName,
  ) {
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final formState = ref.watch(supplierFormProvider(null));
          final formNotifier = ref.watch(supplierFormProvider(null).notifier);

          return AlertDialog(
            title: const Text('Eliminar Proveedor'),
            content: Text('¿Está seguro de que desea eliminar al proveedor "$supplierName"?'),
            actions: [
              TextButton(
                onPressed: formState.isDeleting ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: formState.isDeleting
                    ? null
                    : () async {
                        if (context.mounted) {
                          formNotifier.setDeleting(true);
                        }

                        try {
                          final success = await ref.read(supplierProvider.notifier).deleteSupplier(supplierId);

                          if (context.mounted) {
                            formNotifier.setDeleting(false);
                            if (success) {
                              Navigator.of(context).pop();
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            formNotifier.setDeleting(false);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
                child: formState.isDeleting
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
          );
        },
      ),
    );
  }

  void _showSupplierProducts(BuildContext context, Map<String, dynamic> supplier) {
    final supplierName = supplier['name'] ?? 'Proveedor';
    final supplierId = supplier['_id'];
    final productState = ref.watch(productProvider);
    
    // Filtrar productos por proveedor
    final supplierProducts = productState.products.where((product) {
      final productSupplierId = product['supplierId'] is Map 
          ? product['supplierId']['_id'] 
          : product['supplierId'];
      return productSupplierId == supplierId;
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
                          'Productos de: $supplierName',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${supplierProducts.length} producto(s) encontrado(s)',
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
                child: supplierProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inventory_2_outlined,
                              size: 64,
                              color: AppColors.textSecondary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No hay productos de este proveedor',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: supplierProducts.length,
                        itemBuilder: (context, index) {
                          final product = supplierProducts[index];
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
                                              ? AppColors.error.withValues(alpha: 0.1)
                                              : isLowStock
                                                  ? AppColors.warning.withValues(alpha: 0.1)
                                                  : AppColors.success.withValues(alpha: 0.1),
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
                                        'Precio: ${_formatCurrency((product['salePrice'] as num))}',
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
                                      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
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

