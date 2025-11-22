import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/widgets/loading_indicator.dart';
import '../../shared/providers/riverpod/location_detail_notifier.dart';
import '../../shared/providers/riverpod/location_detail_selectors.dart';

class LocationDetailPage extends ConsumerStatefulWidget {
  final String locationId;

  const LocationDetailPage({Key? key, required this.locationId}) : super(key: key);

  @override
  ConsumerState<LocationDetailPage> createState() => _LocationDetailPageState();
}

class _LocationDetailPageState extends ConsumerState<LocationDetailPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(locationDetailProvider(widget.locationId).notifier).loadItem();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(isLocationLoadingSelector(widget.locationId));
    final error = ref.watch(locationErrorSelector(widget.locationId));
    final location = ref.watch(locationSelector(widget.locationId));

    return DashboardLayout(
      title: 'Detalle de Ubicación',
      currentRoute: '/locations',
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
                          ref.read(locationDetailProvider(widget.locationId).notifier).loadItem();
                        },
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
              : location != null
                  ? _LocationDetailContent(location: location, locationId: widget.locationId)
                  : const Center(child: Text('No se encontró la ubicación')),
    );
  }
}

class _LocationDetailContent extends ConsumerStatefulWidget {
  final Map<String, dynamic> location;
  final String locationId;

  const _LocationDetailContent({Key? key, required this.location, required this.locationId}) : super(key: key);

  @override
  ConsumerState<_LocationDetailContent> createState() => _LocationDetailContentState();
}

class _LocationDetailContentState extends ConsumerState<_LocationDetailContent> {
  late TextEditingController _nameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _zipController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.location['name'] ?? '');
    _addressController = TextEditingController(text: widget.location['address'] ?? '');
    _cityController = TextEditingController(text: widget.location['city'] ?? '');
    _stateController = TextEditingController(text: widget.location['state'] ?? '');
    _zipController = TextEditingController(text: widget.location['zip'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(locationNameSelector(widget.locationId));
    final address = ref.watch(locationAddressSelector(widget.locationId));
    final city = ref.watch(locationCitySelector(widget.locationId));

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
              controller: _cityController,
              decoration: const InputDecoration(labelText: 'Ciudad', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _stateController,
              decoration: const InputDecoration(labelText: 'Estado', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _zipController,
              decoration: const InputDecoration(labelText: 'Código Postal', border: OutlineInputBorder()),
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
                      const SnackBar(content: Text('Ubicación actualizada'), backgroundColor: Colors.green),
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
