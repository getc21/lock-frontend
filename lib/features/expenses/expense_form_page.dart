import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/providers/riverpod/expense_notifier.dart';
import '../../shared/providers/riverpod/store_notifier.dart';

class ExpenseFormPage extends ConsumerStatefulWidget {
  const ExpenseFormPage({super.key});

  @override
  ConsumerState<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends ConsumerState<ExpenseFormPage> {
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _loadCategories();
  }

  void _loadCategories() {
    final store = ref.read(storeProvider).currentStore;
    if (store != null) {
      Future.microtask(() async {
        await ref.read(expenseProvider.notifier).loadCategories(store['_id']);
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    final store = ref.read(storeProvider).currentStore;

    if (_amountController.text.isEmpty || store == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Por favor completa los campos requeridos')),
        );
      }
      return;
    }

    try {
      await ref.read(expenseProvider.notifier).createExpense(
            storeId: store['_id'],
            amount: double.parse(_amountController.text),
            categoryId: _selectedCategoryId,
            description: _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gasto registrado exitosamente'),
            backgroundColor: AppColors.success,
          ),
        );
      }

      // Pequeño delay para que se vea el SnackBar antes de navegar
      await Future.delayed(Duration(milliseconds: 500));

      if (mounted) {
        // 🔴 RECARGAR REPORTE antes de navegar
        final storeId = store['_id'] as String;
        await ref.read(expenseProvider.notifier).loadExpenseReport(
          storeId: storeId,
          period: 'monthly',
        );
      }

      // Navegar después de recargar (usando context protegido)
      if (mounted) {
        context.go('/expenses/report');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _showCreateCategoryDialog() async {
    final store = ref.read(storeProvider).currentStore;
    final nameController = TextEditingController();
    final pageState = this; // Guardar referencia del estado de la página

    return showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          width: 400,
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
                padding: const EdgeInsets.all(AppSizes.spacing16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.add_circle_outline,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacing12),
                    const Expanded(
                      child: Text(
                        'Nueva Categoría',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // CONTENT
              Padding(
                padding: const EdgeInsets.all(AppSizes.spacing20),
                child: TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: 'Nombre de la categoría',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label_outline),
                  ),
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
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      style: TextButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                      ),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: AppSizes.spacing12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(dialogContext).primaryColor,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        if (nameController.text.isNotEmpty && store != null) {
                          // Cerrar diálogo ANTES del async gap
                          Navigator.pop(dialogContext);
                          
                          try {
                            // Crear categoría en el backend
                            await ref.read(expenseProvider.notifier).createCategory(
                              storeId: store['_id'],
                              name: nameController.text,
                              description: 'Categoría personalizada',
                            );

                            if (pageState.mounted) {
                              ScaffoldMessenger.of(pageState.context).showSnackBar(
                                SnackBar(
                                  content: Text('Categoría "${nameController.text}" creada ✅'),
                                  backgroundColor: AppColors.success,
                                ),
                              );
                              
                              // Recargar categorías en el estado
                              pageState.setState(() {});
                            }
                          } catch (e) {
                            if (pageState.mounted) {
                              ScaffoldMessenger.of(pageState.context).showSnackBar(
                                SnackBar(
                                  content: Text('Error: $e'),
                                  backgroundColor: AppColors.error,
                                ),
                              );
                            }
                          }
                        }
                      },
                      child: const Text('Crear'),
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

  @override
  Widget build(BuildContext context) {
    final expenseState = ref.watch(expenseProvider);
    final categories = expenseState.categories;

    return DashboardLayout(
      title: 'Registrar Gasto',
      currentRoute: '/expenses/new',
      child: SingleChildScrollView(
        padding: EdgeInsets.all(AppSizes.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Nuevo Gasto',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            SizedBox(height: AppSizes.spacing12),
            Card(
              elevation: 0,
              color: AppColors.surface,
              child: Padding(
                padding: EdgeInsets.all(AppSizes.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // MONTO (REQUERIDO)
                    Text(
                      'Monto *',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: AppSizes.spacing12),
                    TextField(
                      controller: _amountController,
                      keyboardType:
                          TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: AppSizes.spacing12),

                    // CATEGORÍA
                    Text(
                      'Categoría',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: AppSizes.spacing12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _selectedCategoryId,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: 'Selecciona una categoría',
                            ),
                            items: [
                              DropdownMenuItem(
                                value: null,
                                child: Text('Sin categoría'),
                              ),
                              ...categories.map(
                                (cat) => DropdownMenuItem<String>(
                                  value: cat['_id'] ?? cat['id'],
                                  child: Text(cat['name'] ?? 'Sin nombre'),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedCategoryId = value);
                            },
                          ),
                        ),
                        SizedBox(width: AppSizes.spacing12),
                        // Botón para crear nueva categoría
                        IconButton.filled(
                          onPressed: _showCreateCategoryDialog,
                          icon: const Icon(Icons.add),
                          tooltip: 'Crear nueva categoría',
                          style: IconButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSizes.spacing12),

                    // DESCRIPCIÓN
                    Text(
                      'Descripción',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    SizedBox(height: AppSizes.spacing12),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Describe el gasto...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: AppSizes.spacing12),

                    // BOTONES
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColor,
                          ),
                          child: Text('Cancelar'),
                        ),
                        SizedBox(width: AppSizes.spacing12),
                        ElevatedButton(
                          onPressed: expenseState.isLoading ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                          child: expenseState.isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text('Registrar Gasto'),
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
    );
  }
}
