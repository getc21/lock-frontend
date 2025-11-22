import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/providers/riverpod/supplier_detail_notifier.dart';
import '../../shared/providers/riverpod/supplier_detail_selectors.dart';

/// Página de detalle de un proveedor específico
/// Utiliza supplierDetailProvider (.family) para lazy loading
/// Usar selectores para observar SOLO los campos que cambian
class SupplierDetailPage extends ConsumerStatefulWidget {
  final String supplierId;

  const SupplierDetailPage({
    Key? key,
    required this.supplierId,
  }) : super(key: key);

  @override
  ConsumerState<SupplierDetailPage> createState() => _SupplierDetailPageState();
}

class _SupplierDetailPageState extends ConsumerState<SupplierDetailPage> {
  @override
  void initState() {
    super.initState();
    // Cargar detalle cuando entra a la página
    Future.microtask(() {
      ref.read(supplierDetailProvider(widget.supplierId).notifier).loadItem();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Usar selectores para observar SOLO lo que cambió
    final isLoading = ref.watch(isSupplierLoadingSelector(widget.supplierId));
    final error = ref.watch(supplierErrorSelector(widget.supplierId));
    final supplier = ref.watch(supplierSelector(widget.supplierId));

    return DashboardLayout(
      title: 'Detalle de Proveedor',
      currentRoute: '/suppliers',
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
                          ref.read(supplierDetailProvider(widget.supplierId).notifier).loadItem();
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : supplier != null
                  ? _SupplierDetailContent(
                      supplier: supplier,
                      supplierId: widget.supplierId,
                    )
                  : const Center(
                      child: Text('No se encontró el proveedor'),
                    ),
    );
  }
}

/// Widget de contenido de detalle de proveedor
class _SupplierDetailContent extends ConsumerStatefulWidget {
  final Map<String, dynamic> supplier;
  final String supplierId;

  const _SupplierDetailContent({
    Key? key,
    required this.supplier,
    required this.supplierId,
  }) : super(key: key);

  @override
  ConsumerState<_SupplierDetailContent> createState() =>
      _SupplierDetailContentState();
}

class _SupplierDetailContentState extends ConsumerState<_SupplierDetailContent> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.supplier['name'] ?? '');
    _emailController =
        TextEditingController(text: widget.supplier['email'] ?? '');
    _phoneController =
        TextEditingController(text: widget.supplier['phone'] ?? '');
    _cityController =
        TextEditingController(text: widget.supplier['city'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usar selectores para componentes que necesiten updates
    final name = ref.watch(supplierNameSelector(widget.supplierId));
    final email = ref.watch(supplierEmailSelector(widget.supplierId));
    final phone = ref.watch(supplierPhoneSelector(widget.supplierId));
    final city = ref.watch(supplierCitySelector(widget.supplierId));
    final isActive = ref.watch(supplierIsActiveSelector(widget.supplierId));

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
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
                    Text(
                      name ?? 'Cargando...',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      email ?? 'Sin email',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? Colors.green.withOpacity(0.2)
                        : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isActive ? 'Activo' : 'Inactivo',
                    style: TextStyle(
                      color: isActive ? Colors.green : Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Formulario
            const Text(
              'Información General',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Nombre
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre del Proveedor',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Email
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Teléfono
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Ciudad
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: 'Ciudad',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),

            // Botones de acción
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
                    // Guardar cambios
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Proveedor actualizado'),
                        backgroundColor: Colors.green,
                      ),
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
