import 'package:flutter/material.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/providers/riverpod/store_notifier.dart';
import '../../shared/providers/riverpod/auth_notifier.dart';

class StoresPage extends ConsumerStatefulWidget {
  const StoresPage({super.key});

  @override
  ConsumerState<StoresPage> createState() => _StoresPageState();
}

class _StoresPageState extends ConsumerState<StoresPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized && mounted) {
        _hasInitialized = true;
        final storeState = ref.read(storeProvider);
        if (storeState.stores.isEmpty) {
          ref.read(storeProvider.notifier).loadStores(autoSelect: true);
        }
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
    final authState = ref.watch(authProvider);
    final isAdmin = authState.currentUser?['role'] == 'admin';
    
    // Si no es admin, mostrar página de acceso denegado
    if (!isAdmin) {
      return DashboardLayout(
        title: 'Tiendas',
        currentRoute: '/stores',
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.spacing24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: AppColors.error),
                const SizedBox(height: AppSizes.spacing16),
                const Text(
                  'Acceso Denegado',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.error),
                ),
                const SizedBox(height: AppSizes.spacing8),
                const Text(
                  'Solo los administradores pueden acceder a la gestión de tiendas',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    final storeState = ref.watch(storeProvider);
    
    return DashboardLayout(
      title: 'Tiendas',
      currentRoute: '/stores',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!storeState.isLoading) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Buscar tiendas...',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                const SizedBox(width: AppSizes.spacing16),
                ElevatedButton.icon(
                  onPressed: () => _showStoreDialog(context, null),
                  icon: const Icon(Icons.add),
                  label: const Text('Nueva Tienda'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.spacing24),
          ],
          
          if (storeState.isLoading)
            SizedBox(
              height: 600,
              child: Card(
                child: Center(
                  child: LoadingIndicator(
                    message: 'Cargando tiendas...',
                  ),
                ),
              ),
            )
          else if (storeState.stores.isEmpty)
            SizedBox(
              height: 600,
              child: Card(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSizes.spacing24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.store_outlined, size: 64, color: AppColors.textSecondary),
                        const SizedBox(height: AppSizes.spacing16),
                        const Text(
                          'No hay tiendas registradas',
                          style: TextStyle(fontSize: 18, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: AppSizes.spacing8),
                        ElevatedButton.icon(
                          onPressed: () => _showStoreDialog(context, null),
                          icon: const Icon(Icons.add),
                          label: const Text('Crear Primera Tienda'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacing16),
                child: SizedBox(
                  height: 600,
                  child: DataTable2(
                    columnSpacing: 12,
                    horizontalMargin: 12,
                    minWidth: 1000,
                    columns: const [
                      DataColumn2(label: Text('Tienda'), size: ColumnSize.L),
                      DataColumn2(label: Text('Dirección'), size: ColumnSize.L),
                      DataColumn2(label: Text('Teléfono'), size: ColumnSize.M),
                      DataColumn2(label: Text('Email'), size: ColumnSize.M),
                      DataColumn2(label: Text('Acciones'), size: ColumnSize.M),
                    ],
                    rows: _buildStoreRows(storeState.stores),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<DataRow2> _buildStoreRows(List<Map<String, dynamic>> stores) {
    return stores
        .where((s) =>
            _searchQuery.isEmpty ||
            (s['name'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()) ||
            (s['address'] ?? '').toLowerCase().contains(_searchQuery.toLowerCase()))
        .map((store) {
          final isActive = store['status'] == 'active';
          final isCurrent = ref.read(storeProvider).currentStore?['_id'] == store['_id'];

          return DataRow2(
            decoration: BoxDecoration(
              color: isCurrent ? Theme.of(context).primaryColor.withValues(alpha: 0.05) : null,
              border: isCurrent 
                ? Border(left: BorderSide(color: Theme.of(context).primaryColor, width: 3))
                : null,
            ),
            cells: [
              DataCell(
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isActive 
                          ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                          : AppColors.gray200,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.store,
                        size: 16,
                        color: isActive ? Theme.of(context).primaryColor : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: AppSizes.spacing12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  store['name'] ?? 'Sin nombre',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle, color: Colors.white, size: 12),
                                      SizedBox(width: 4),
                                      Text(
                                        'Actual',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(Text(
                store['address'] ?? 'N/A',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )),
              DataCell(Text(
                store['phone'] ?? 'N/A',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )),
              DataCell(Text(
                store['email'] ?? 'N/A',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isCurrent)
                      IconButton(
                        icon: const Icon(Icons.sync_alt, size: 18),
                        onPressed: () => _switchStore(store),
                        tooltip: 'Cambiar a esta tienda',
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => _showStoreDialog(context, store),
                      tooltip: 'Editar',
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18),
                      onPressed: () => _confirmDelete(store),
                      tooltip: 'Eliminar',
                      color: AppColors.error,
                    ),
                  ],
                ),
              ),
            ],
          );
        })
        .toList();
  }

  void _switchStore(Map<String, dynamic> store) {
    ref.read(storeProvider.notifier).selectStore(store);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cambió a tienda: ${store['name']}'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showStoreDialog(BuildContext context, Map<String, dynamic>? store) {
    final isEdit = store != null;
    final nameController = TextEditingController(text: store?['name'] ?? '');
    final addressController = TextEditingController(text: store?['address'] ?? '');
    final phoneController = TextEditingController(text: store?['phone'] ?? '');
    final emailController = TextEditingController(text: store?['email'] ?? '');
    var isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isEdit ? Icons.edit : Icons.add_business,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Text(isEdit ? 'Editar Tienda' : 'Nueva Tienda'),
            ],
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de la tienda *',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.store),
                    ),
                  ),
                  const SizedBox(height: AppSizes.spacing16),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(
                      labelText: 'Dirección',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: AppSizes.spacing16),
                  TextField(
                    controller: phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Teléfono',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.phone),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppSizes.spacing16),
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: AppSizes.spacing8),
                  const Text(
                    '* Campos requeridos',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('El nombre de la tienda es obligatorio'),
                          ),
                        );
                        return;
                      }

                      setState(() => isLoading = true);

                      bool success;
                      if (isEdit) {
                        success = await ref.read(storeProvider.notifier).updateStore(
                          id: store['_id'],
                          name: nameController.text.trim(),
                          address: addressController.text.trim().isEmpty 
                              ? null 
                              : addressController.text.trim(),
                          phone: phoneController.text.trim().isEmpty 
                              ? null 
                              : phoneController.text.trim(),
                          email: emailController.text.trim().isEmpty 
                              ? null 
                              : emailController.text.trim(),
                        );
                      } else {
                        success = await ref.read(storeProvider.notifier).createStore(
                          name: nameController.text.trim(),
                          address: addressController.text.trim().isEmpty 
                              ? null 
                              : addressController.text.trim(),
                          phone: phoneController.text.trim().isEmpty 
                              ? null 
                              : phoneController.text.trim(),
                          email: emailController.text.trim().isEmpty 
                              ? null 
                              : emailController.text.trim(),
                        );
                      }

                      setState(() => isLoading = false);

                      if (success && dialogContext.mounted) {
                        Navigator.pop(dialogContext);
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              isEdit 
                                ? 'Tienda actualizada exitosamente' 
                                : 'Tienda creada exitosamente',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
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
                  : Text(isEdit ? 'Guardar' : 'Crear'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(Map<String, dynamic> store) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.error),
            SizedBox(width: 12),
            Text('Confirmar eliminación'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '¿Estás seguro de que deseas eliminar esta tienda?',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    store['name'] ?? 'Sin nombre',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  if (store['address'] != null && (store['address'] as String).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        store['address'] ?? '',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '⚠️ Esta acción no se puede deshacer',
              style: TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final success = await ref.read(storeProvider.notifier).deleteStore(store['_id']);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tienda eliminada exitosamente'),
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}

