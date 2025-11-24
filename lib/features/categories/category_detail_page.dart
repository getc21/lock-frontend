import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/providers/riverpod/category_detail_notifier.dart';
import '../../shared/providers/riverpod/category_detail_selectors.dart';

class CategoryDetailPage extends ConsumerStatefulWidget {
  final String categoryId;

  const CategoryDetailPage({
    Key? key,
    required this.categoryId,
  }) : super(key: key);

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
    Key? key,
    required this.category,
    required this.categoryId,
  }) : super(key: key);

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

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name ?? 'Cargando...',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      description ?? 'Sin descripción',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'Activa' : 'Inactiva',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            const Text('Información General', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción', border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Categoría actualizada'), backgroundColor: Colors.green),
                    );
                  },
                  child: const Text('Guardar Cambios'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
