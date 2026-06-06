import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/providers/riverpod/category_detail_notifier.dart';
import '../../shared/providers/riverpod/category_detail_selectors.dart';

class CategoryDetailPage extends ConsumerStatefulWidget {
  final String categoryId;

  const CategoryDetailPage({
    required this.categoryId,
    super.key,
  });

  @override
  ConsumerState<CategoryDetailPage> createState() => _CategoryDetailPageState();
}

class _CategoryDetailPageState extends ConsumerState<CategoryDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(categoryDetailProvider(widget.categoryId).notifier).loadItem();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isCategoryLoadingSelector(widget.categoryId));
    final error = ref.watch(categoryErrorSelector(widget.categoryId));
    final category = ref.watch(categorySelector(widget.categoryId));

    return DashboardLayout(
      title: 'Detalle de Categoría',
      currentRoute: '/categories',
      child: isLoading
          ? const Center(child: LoadingIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        error,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(categoryDetailProvider(widget.categoryId).notifier).loadItem();
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : category != null
                  ? _CategoryDetailContent(
                      category: category,
                      categoryId: widget.categoryId,
                    )
                  : const Center(
                      child: Text('No se encontró la categoría'),
                    ),
    );
  }
}

class _CategoryDetailContent extends ConsumerStatefulWidget {
  final Map<String, dynamic> category;
  final String categoryId;

  const _CategoryDetailContent({
    required this.category,
    required this.categoryId,
  });

  @override
  ConsumerState<_CategoryDetailContent> createState() =>
      _CategoryDetailContentState();
}

class _CategoryDetailContentState extends ConsumerState<_CategoryDetailContent> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.category['name'] ?? '');
    _descriptionController =
        TextEditingController(text: widget.category['description'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(categoryNameSelector(widget.categoryId));
    final description = ref.watch(categoryDescriptionSelector(widget.categoryId));
    final isActive = ref.watch(categoryIsActiveSelector(widget.categoryId));

    return Card(
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER mejorado
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).primaryColor,
                    Theme.of(context).primaryColor.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(AppSizes.spacing24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name ?? 'Cargando...',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          description ?? 'Sin descripción',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isActive ? Colors.green : Colors.red,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      isActive ? 'Activa' : 'Inactiva',
                      style: TextStyle(
                        color: isActive ? Colors.green.shade300 : Colors.red.shade300,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // CONTENT
            Padding(
              padding: const EdgeInsets.all(AppSizes.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información General',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.category_outlined),
                      filled: true,
                      fillColor: Theme.of(context).primaryColor.withValues(alpha: 0.02),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Descripción',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.description_outlined),
                      filled: true,
                      fillColor: Theme.of(context).primaryColor.withValues(alpha: 0.02),
                    ),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            // FOOTER
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border, width: 1)),
              ),
              padding: const EdgeInsets.all(AppSizes.spacing16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                    ),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: AppSizes.spacing12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Guardar Cambios'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Categoría actualizada'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
