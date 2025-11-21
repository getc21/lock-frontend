import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/riverpod/product_detail_notifier.dart';
import '../../shared/providers/riverpod/product_detail_selectors.dart';

class ProductDetailPage extends ConsumerStatefulWidget {
  final String productId;

  const ProductDetailPage({
    Key? key,
    required this.productId,
  }) : super(key: key);

  @override
  ConsumerState<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends ConsumerState<ProductDetailPage> {
  @override
  void initState() {
    super.initState();
    // Load product detail when page is initialized
    Future.microtask(() {
      ref.read(productDetailProvider(widget.productId).notifier).loadProductDetail();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Usar selectores para observar solo lo que cambió
    final isLoading = ref.watch(productLoadingSelector(widget.productId));
    final error = ref.watch(productErrorSelector(widget.productId));
    final product = ref.watch(productSelector(widget.productId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Producto'),
        elevation: 0,
      ),
      body: isLoading
          ? const _LoadingState()
          : error != null
              ? _ErrorState(error: error)
              : product != null
                  ? _ProductDetailContent(
                      product: product,
                      productId: widget.productId,
                    )
                  : const SizedBox.shrink(),
    );
  }
}

class _ProductDetailContent extends ConsumerStatefulWidget {
  final Map<String, dynamic> product;
  final String productId;

  const _ProductDetailContent({
    Key? key,
    required this.product,
    required this.productId,
  }) : super(key: key);

  @override
  ConsumerState<_ProductDetailContent> createState() =>
      _ProductDetailContentState();
}

class _ProductDetailContentState extends ConsumerState<_ProductDetailContent> {
  late TextEditingController _priceController;
  late TextEditingController _stockController;

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.product['price']?.toString() ?? '0.00',
    );
    _stockController = TextEditingController(
      text: widget.product['stock']?.toString() ?? '0',
    );
  }

  @override
  void dispose() {
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _updatePrice() {
    final newPrice = double.tryParse(_priceController.text) ?? 0.0;
    ref
        .read(productDetailProvider(widget.productId).notifier)
        .updatePrice(newPrice: newPrice);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Precio actualizado')),
    );
  }

  void _updateStock() {
    final newStock = int.tryParse(_stockController.text) ?? 0;
    ref
        .read(productDetailProvider(widget.productId).notifier)
        .updateStock(newStock: newStock);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Inventario actualizado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Usar selectores para observar solo las propiedades que necesitamos
    final name = ref.watch(productNameSelector(widget.productId));
    final description = ref.watch(productDescriptionSelector(widget.productId));
    final sku = ref.watch(productSkuSelector(widget.productId));
    final supplier = ref.watch(productSupplierSelector(widget.productId));
    
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image Section
          _ProductImageSection(product: widget.product),

          const SizedBox(height: 16),

          // Product Name and Category
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? 'Sin nombre',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.product['category'] ?? 'Sin categoría',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Price Section
          _SectionTitle(title: 'Precio'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _EditableField(
                  label: 'Precio (\$)',
                  controller: _priceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (_) {},
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _updatePrice,
                    child: const Text('Actualizar Precio'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Stock Section
          _SectionTitle(title: 'Inventario'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _EditableField(
                  label: 'Cantidad en Stock',
                  controller: _stockController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) {},
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _updateStock,
                    child: const Text('Actualizar Inventario'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Product Information
          _SectionTitle(title: 'Información'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _InfoRow(
                  label: 'SKU',
                  value: sku ?? 'N/A',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Proveedor',
                  value: supplier?['name']?.toString() ?? 'N/A',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Estado',
                  value: widget.product['active'] == true
                      ? 'Activo'
                      : 'Inactivo',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Description Section
          if (description != null && description.toString().isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: 'Descripción'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    widget.product['description'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.6,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
        ],
      ),
    );
  }
}

class _ProductImageSection extends StatelessWidget {
  final Map<String, dynamic> product;

  const _ProductImageSection({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final imageUrl = product['image'] as String?;

    return Container(
      width: double.infinity,
      height: 300,
      color: Colors.grey[200],
      child: imageUrl != null && imageUrl.isNotEmpty
          ? Image.network(
              imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  _PlaceholderImage(),
            )
          : _PlaceholderImage(),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.image_not_supported,
          size: 64,
          color: Colors.grey,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    Key? key,
    required this.label,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }
}

class _EditableField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;
  final Function(String) onChanged;

  const _EditableField({
    Key? key,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({
    Key? key,
    required this.error,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
