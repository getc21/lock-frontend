import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/providers/riverpod/store_detail_notifier.dart';
import '../../shared/providers/riverpod/store_detail_selectors.dart';

class StoreDetailPage extends ConsumerStatefulWidget {
  final String storeId;

  const StoreDetailPage({Key? key, required this.storeId}) : super(key: key);

  @override
  ConsumerState<StoreDetailPage> createState() => _StoreDetailPageState();
}

class _StoreDetailPageState extends ConsumerState<StoreDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(storeDetailProvider(widget.storeId).notifier).loadItem();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isStoreLoadingSelector(widget.storeId));
    final error = ref.watch(storeErrorSelector(widget.storeId));
    final store = ref.watch(storeSelector(widget.storeId));

    return DashboardLayout(
      title: 'Detalle de Tienda',
      currentRoute: '/stores',
      child: isLoading
          ? const Center(child: LoadingIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AppColors.error),
                      const SizedBox(height: 16),
                      Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          ref.read(storeDetailProvider(widget.storeId).notifier).loadItem();
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : store != null
                  ? _StoreDetailContent(store: store, storeId: widget.storeId)
                  : const Center(child: Text('No se encontró la tienda')),
    );
  }
}

class _StoreDetailContent extends ConsumerStatefulWidget {
  final Map<String, dynamic> store;
  final String storeId;

  const _StoreDetailContent({Key? key, required this.store, required this.storeId}) : super(key: key);

  @override
  ConsumerState<_StoreDetailContent> createState() => _StoreDetailContentState();
}

class _StoreDetailContentState extends ConsumerState<_StoreDetailContent> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _phoneController;
  late TextEditingController _cityController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.store['name'] ?? '');
    _addressController = TextEditingController(text: widget.store['address'] ?? '');
    _phoneController = TextEditingController(text: widget.store['phone'] ?? '');
    _cityController = TextEditingController(text: widget.store['city'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(storeNameSelector(widget.storeId));
    final address = ref.watch(storeAddressSelector(widget.storeId));
    final phone = ref.watch(storePhoneSelector(widget.storeId));
    final city = ref.watch(storeCitySelector(widget.storeId));

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name ?? 'Cargando...', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(address ?? 'Sin dirección', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(phone ?? 'Sin teléfono', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(city ?? 'Sin ciudad', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
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
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Dirección', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Teléfono', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'Ciudad', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tienda actualizada'), backgroundColor: Colors.green),
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
