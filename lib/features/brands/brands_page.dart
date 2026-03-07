import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
// ignore: unused_import
import 'dart:math';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/providers/riverpod/brand_notifier.dart';
import '../../shared/providers/riverpod/auth_notifier.dart';
import 'create_brand_dialog.dart';

class BrandsPage extends ConsumerStatefulWidget {
  const BrandsPage({super.key});

  @override
  ConsumerState<BrandsPage> createState() => _BrandsPageState();
}

class _BrandsPageState extends ConsumerState<BrandsPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _hasInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasInitialized && mounted) {
        _hasInitialized = true;
        ref.read(brandProvider.notifier).loadBrands();
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
    final isSuperAdmin = authState.currentUser?['role'] == 'superadmin';

    if (!isSuperAdmin) {
      return DashboardLayout(
        title: 'Marcas',
        currentRoute: '/brands',
        child: const Center(
          child: Text('No tienes permisos para acceder a esta sección'),
        ),
      );
    }

    final brandState = ref.watch(brandProvider);

    return DashboardLayout(
      title: 'Gestión de Marcas',
      currentRoute: '/brands',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header con búsqueda y botón de crear
          _buildHeader(context, brandState),
          const SizedBox(height: AppSizes.spacing16),
          // Lista de marcas
          if (brandState.isLoading)
            const Padding(
              padding: EdgeInsets.all(64),
              child: Center(child: CircularProgressIndicator()),
            )
          else
            _buildBrandsList(context, brandState),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, BrandState brandState) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Row(
          children: [
            // Búsqueda
            Expanded(
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Buscar marcas...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing12,
                    vertical: AppSizes.spacing8,
                  ),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ),
            const SizedBox(width: AppSizes.spacing16),
            // Contador
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing12,
                vertical: AppSizes.spacing8,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              child: Text(
                '${brandState.brands.length} marcas',
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSizes.spacing12),
            // Refrescar
            IconButton(
              onPressed: () => ref.read(brandProvider.notifier).loadBrands(),
              icon: const Icon(Icons.refresh),
              tooltip: 'Refrescar',
            ),
            const SizedBox(width: AppSizes.spacing8),
            // Crear marca
            FilledButton.icon(
              onPressed: () => _showCreateBrandDialog(context),
              icon: const Icon(Icons.add),
              label: const Text('Nueva Marca'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandsList(BuildContext context, BrandState brandState) {
    final brands = brandState.brands.where((brand) {
      if (_searchQuery.isEmpty) return true;
      final name = (brand['name'] ?? '').toString().toLowerCase();
      final slug = (brand['slug'] ?? '').toString().toLowerCase();
      final email = (brand['contactEmail'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      return name.contains(query) || slug.contains(query) || email.contains(query);
    }).toList();

    if (brands.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(64),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.business_outlined, size: 64, color: AppColors.textSecondary),
            const SizedBox(height: AppSizes.spacing16),
            Text(
              _searchQuery.isEmpty ? 'No hay marcas registradas' : 'Sin resultados',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.spacing8),
            Text(
              _searchQuery.isEmpty
                  ? 'Crea tu primera marca para comenzar'
                  : 'Intenta con otros términos de búsqueda',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: brands.length,
      itemBuilder: (context, index) => _buildBrandCard(context, brands[index]),
    );
  }

  Widget _buildBrandCard(BuildContext context, Map<String, dynamic> brand) {
    final isActive = brand['isActive'] == true;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSizes.spacing12),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.spacing16),
        child: Row(
          children: [
            // Logo / Icono
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isActive
                    ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
                    : AppColors.textSecondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
              ),
              child: Center(
                child: brand['logo'] != null && brand['logo'].toString().isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                        child: Image.network(
                          brand['logo'],
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(
                            Icons.business,
                            size: 28,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                      )
                    : Icon(
                        Icons.business,
                        size: 28,
                        color: isActive
                            ? Theme.of(context).primaryColor
                            : AppColors.textSecondary,
                      ),
              ),
            ),
            const SizedBox(width: AppSizes.spacing16),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        brand['name'] ?? '',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: AppSizes.spacing8),
                      _buildStatusBadge(context, isActive),
                      const SizedBox(width: AppSizes.spacing8),
                      Icon(Icons.store_outlined, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Máx. ${brand['maxStores'] ?? 3} suc.',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    brand['contactEmail'] ?? '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.link, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        brand['slug'] ?? '',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),

                    ],
                  ),
                ],
              ),
            ),
            // Acciones
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _showEditBrandDialog(context, brand),
                  icon: const Icon(Icons.edit_outlined),
                  tooltip: 'Editar',
                ),
                if (isActive)
                  IconButton(
                    onPressed: () => _confirmDeactivate(context, brand),
                    icon: Icon(Icons.block, color: Colors.red.shade400),
                    tooltip: 'Desactivar',
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context, bool isActive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.green.withValues(alpha: 0.1)
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        isActive ? 'Activa' : 'Inactiva',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: isActive ? Colors.green : Colors.red,
        ),
      ),
    );
  }

  void _showCreateBrandDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CreateBrandDialog(),
    );
  }

  void _showEditBrandDialog(BuildContext context, Map<String, dynamic> brand) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateBrandDialog(existingBrand: brand),
    );
  }

  void _confirmDeactivate(BuildContext context, Map<String, dynamic> brand) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desactivar Marca'),
        content: Text(
          '¿Estás seguro que deseas desactivar "${brand['name']}"?\n\n'
          'Esto desactivará también a todos los usuarios de esta marca.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final brandId = brand['_id'] ?? brand['id'];
              if (brandId != null) {
                await ref.read(brandProvider.notifier).deleteBrand(brandId);
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desactivar'),
          ),
        ],
      ),
    );
  }
}
