import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/providers/riverpod/category_notifier.dart';
import '../../shared/providers/riverpod/product_notifier.dart';
import '../../shared/providers/riverpod/category_form_notifier.dart';
import '../../shared/services/input_validator.dart';
import '../../shared/services/debouncer.dart';
import '../../core/utils/responsive.dart';
import '../../core/utils/app_snackbar.dart';

class CategoriesPage extends ConsumerStatefulWidget {
  const CategoriesPage({super.key});

  @override
  ConsumerState<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends ConsumerState<CategoriesPage> {
  final _searchController = TextEditingController();
  final _debouncer = Debouncer();
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    // Cargar categorías después de que el widget esté montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(categoryProvider.notifier).loadCategories();
      }
    });
  }

  @override
  void dispose() {
    _debouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categoryState = ref.watch(categoryProvider);
    final productState = ref.watch(productProvider);

    return DashboardLayout(
      title: 'Categorías',
      currentRoute: '/categories',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search and Add Button
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar categorías...',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) {
                    _debouncer.run(() {
                      if (mounted) setState(() => _searchQuery = value);
                    });
                  },
                ),
              ),
              const SizedBox(width: AppSizes.spacing16),
              ElevatedButton.icon(
                onPressed: () => _showCategoryDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Nueva Categoría'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.spacing24),

          // Tabla de categorías
          SizedBox(
            height: 600,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacing16),
                child: (() {
                  if (categoryState.isLoading) {
                    return LoadingIndicator(
                      message: 'Cargando categorías...',
                    );
                  }

                  // Filtrar categorías
                  final filteredCategories = categoryState.categories
                      .where((c) => _searchQuery.isEmpty ||
                          ((c['name'] as String?) ?? '').toLowerCase().contains(_searchQuery.toLowerCase()))
                      .toList();

                  if (categoryState.categories.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.spacing24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.category_outlined, size: 64, color: AppColors.textSecondary),
                            const SizedBox(height: AppSizes.spacing16),
                            const Text(
                              'No hay categorías disponibles',
                              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: AppSizes.spacing8),
                            ElevatedButton.icon(
                              onPressed: () => _showCategoryDialog(context, ref),
                              icon: const Icon(Icons.add),
                              label: const Text('Agregar Primera Categoría'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (filteredCategories.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppSizes.spacing24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.search_off, size: 64, color: AppColors.textSecondary),
                            const SizedBox(height: AppSizes.spacing16),
                            const Text(
                              'No se encontraron categorías',
                              style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      childAspectRatio: 0.85,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: filteredCategories.length,
                    itemBuilder: (context, index) {
                      final category = filteredCategories[index];
                      final categoryName = category['name'] ?? '';
                      final categoryDescription = category['description'] ?? '-';
                      final categoryImage = category['foto'] ?? category['image'];
                      
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: InkWell(
                            onTap: () => _showCategoryProducts(context, ref, category, productState.products),
                            borderRadius: BorderRadius.circular(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Imagen con botones en la esquina superior derecha
                                Expanded(
                                  flex: 2,
                                  child: Stack(
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor.withValues(alpha: 0.08),
                                          borderRadius: const BorderRadius.only(
                                            topLeft: Radius.circular(12),
                                            topRight: Radius.circular(12),
                                          ),
                                        ),
                                        child: categoryImage != null && categoryImage.toString().isNotEmpty
                                            ? ClipRRect(
                                                borderRadius: const BorderRadius.only(
                                                  topLeft: Radius.circular(12),
                                                  topRight: Radius.circular(12),
                                                ),
                                                child: Image.network(
                                                  categoryImage,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) {
                                                    return Center(
                                                      child: Icon(
                                                        Icons.category_outlined,
                                                        size: 52,
                                                        color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                                                      ),
                                                    );
                                                  },
                                                ),
                                              )
                                            : Center(
                                                child: Icon(
                                                  Icons.category_outlined,
                                                  size: 52,
                                                  color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
                                                ),
                                              ),
                                      ),
                                      // Botones en esquina superior derecha
                                      Positioned(
                                        top: 12,
                                        right: 12,
                                        child: Column(
                                          children: [
                                            GestureDetector(
                                              onTap: () => _showCategoryDialog(context, ref, category: category),
                                              child: Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  color: Colors.blue,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.blue.withValues(alpha: 0.4),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                alignment: Alignment.center,
                                                child: const Icon(Icons.edit_outlined, size: 18, color: Colors.white),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            GestureDetector(
                                              onTap: () => _confirmDelete(context, ref, category),
                                              child: Container(
                                                width: 36,
                                                height: 36,
                                                decoration: BoxDecoration(
                                                  color: Colors.red,
                                                  shape: BoxShape.circle,
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.red.withValues(alpha: 0.4),
                                                      blurRadius: 8,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                                alignment: Alignment.center,
                                                child: const Icon(Icons.delete_outline, size: 18, color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Contenido
                                Expanded(
                                  flex: MediaQuery.of(context).size.width < 800 ? 2 : 1,
                                  child: Padding(
                                    padding: const EdgeInsets.all(AppSizes.spacing16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              categoryName,
                                              style: TextStyle(
                                                fontSize: _calculateResponsiveFontSize(context, 15),
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.textPrimary,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              categoryDescription,
                                              style: TextStyle(
                                                fontSize: _calculateResponsiveFontSize(context, 12),
                                                color: AppColors.textSecondary,
                                                height: 1.4,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                })(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog(BuildContext context, WidgetRef ref, {Map<String, dynamic>? category}) {
    final nameController = TextEditingController(text: category?['name'] ?? '');
    final descriptionController = TextEditingController(text: category?['description'] ?? '');
    final isEditing = category != null;

    // Limpiar el formulario solo si es una nueva categoría (antes de abrir el diálogo)
    if (!isEditing) {
      ref.read(categoryFormProvider(null).notifier).clearImage();
    }

    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final formState = ref.watch(categoryFormProvider(category));
          final formNotifier = ref.watch(categoryFormProvider(category).notifier);

          return AlertDialog(
            title: Text(isEditing ? 'Editar Categoría' : 'Nueva Categoría'),
            content: SizedBox(
              width: Responsive(context).dialogWidth(preferred: 500),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Vista previa de imagen / Selector
                    GestureDetector(
                      onTap: () async {
                        try {
                          await formNotifier.selectImage();
                        } catch (e) {
                          if (context.mounted) {
                            AppSnackbar.error(context, 'Error al seleccionar imagen');
                          }
                        }
                      },
                      child: Center(
                        child: Container(
                          width: 144,
                          height: 144,
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
                                    width: 144,
                                    height: 144,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.add_photo_alternate, size: 40, color: Theme.of(context).primaryColor),
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
                                    Icon(Icons.add_photo_alternate, size: 40, color: Theme.of(context).primaryColor),
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
                      enabled: !formState.isLoading,
                      onChanged: formNotifier.setName,
                      decoration: const InputDecoration(
                        labelText: 'Nombre *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacing16),
                    TextField(
                      controller: descriptionController,
                      enabled: !formState.isLoading,
                      onChanged: formNotifier.setDescription,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
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
                        if (nameController.text.trim().isEmpty) {
                          if (context.mounted) {
                            AppSnackbar.warning(context, 'El nombre es requerido');
                          }
                          return;
                        }
                        // Injection protection
                        if (InputValidator.containsHtmlOrScript(nameController.text) ||
                            InputValidator.containsHtmlOrScript(descriptionController.text)) {
                          if (context.mounted) {
                            AppSnackbar.warning(context, 'Entrada no válida detectada');
                          }
                          return;
                        }

                        if (context.mounted) {
                          formNotifier.setLoading(true);
                        }

                        try {
                          bool success;
                          if (isEditing) {
                            success = await ref.read(categoryProvider.notifier).updateCategory(
                              id: category['_id'],
                              name: InputValidator.sanitize(nameController.text.trim()),
                              description: descriptionController.text.trim().isEmpty ? null : InputValidator.sanitize(descriptionController.text.trim()),
                              imageFile: formState.selectedImage,
                              imageBytes: formState.imageBytes,
                            );
                          } else {
                            success = await ref.read(categoryProvider.notifier).createCategory(
                              name: InputValidator.sanitize(nameController.text.trim()),
                              description: descriptionController.text.trim().isEmpty ? null : InputValidator.sanitize(descriptionController.text.trim()),
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
                            AppSnackbar.error(context, 'Error: $e');
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
                    : Text(isEditing ? 'Actualizar' : 'Crear'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Map<String, dynamic> category) {
    final categoryName = category['name'] ?? 'esta categoría';
    final categoryId = category['_id'];

    if (categoryId == null) {
      AppSnackbar.warning(context, 'ID de categoría no válido');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) {
          final formState = ref.watch(categoryFormProvider(null));
          final formNotifier = ref.watch(categoryFormProvider(null).notifier);

          return AlertDialog(
            title: const Text('Confirmar eliminación'),
            content: Text('¿Estás seguro de eliminar la categoría "$categoryName"?'),
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
                          final success = await ref.read(categoryProvider.notifier).deleteCategory(categoryId);

                          if (context.mounted) {
                            formNotifier.setDeleting(false);
                            if (success) {
                              Navigator.of(context).pop();
                            }
                          }
                        } catch (e) {
                          if (context.mounted) {
                            formNotifier.setDeleting(false);
                            AppSnackbar.error(context, 'Error: $e');
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

  void _showCategoryProducts(BuildContext context, WidgetRef ref, Map<String, dynamic> category, List<dynamic> products) {
    final categoryName = category['name'] ?? 'Categoría';
    final categoryId = category['_id'];
    
    // Filtrar productos por categoría
    final categoryProducts = products.where((product) {
      final productCategoryId = product['categoryId'] is Map 
          ? product['categoryId']['_id'] 
          : product['categoryId'];
      return productCategoryId == categoryId;
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
                          'Productos en: $categoryName',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${categoryProducts.length} producto(s) encontrado(s)',
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
                child: categoryProducts.isEmpty
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
                              'No hay productos en esta categoría',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.textSecondary.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: categoryProducts.length,
                        itemBuilder: (context, index) {
                          final product = categoryProducts[index];
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
                                  if (product['supplierId'] != null && 
                                      product['supplierId'] is Map)
                                    Chip(
                                      label: Text(
                                        product['supplierId']['name'] ?? 'Sin proveedor',
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

  /// Calcula el tamaño de fuente responsivo basado en el ancho de la pantalla
  double _calculateResponsiveFontSize(BuildContext context, double baseFontSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Escala el tamaño de fuente basado en el ancho de la pantalla
    // En pantallas muy anchas (>1400px) mantiene el tamaño base
    // En pantallas más estrechas reduce proporcionalmente
    if (screenWidth > 1400) {
      return baseFontSize;
    } else if (screenWidth > 1200) {
      return baseFontSize * 0.95;
    } else if (screenWidth > 1000) {
      return baseFontSize * 0.90;
    } else if (screenWidth > 800) {
      return baseFontSize * 0.85;
    } else if (screenWidth > 600) {
      return baseFontSize * 0.80;
    } else {
      return baseFontSize * 0.75;
    }
  }
}

