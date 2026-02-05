import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:bellezapp_web/shared/models/quotation.dart';
import 'package:bellezapp_web/shared/providers/riverpod/quotation_form_notifier.dart';
import 'package:bellezapp_web/shared/providers/riverpod/store_notifier.dart';
import 'package:bellezapp_web/shared/widgets/dashboard_layout.dart';

class CreateQuotationPage extends ConsumerStatefulWidget {
  const CreateQuotationPage({super.key});

  @override
  ConsumerState<CreateQuotationPage> createState() => _CreateQuotationPageState();
}

class _CreateQuotationPageState extends ConsumerState<CreateQuotationPage> {
  late TextEditingController _customerNameController;
  late TextEditingController _productNameController;
  late TextEditingController _quantityController;
  late TextEditingController _priceController;
  late TextEditingController _discountController;
  late TextEditingController _notesController;

  String? _selectedCustomerId;

  @override
  void initState() {
    super.initState();
    _customerNameController = TextEditingController();
    _productNameController = TextEditingController();
    _quantityController = TextEditingController();
    _priceController = TextEditingController();
    _discountController = TextEditingController();
    _notesController = TextEditingController();
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _productNameController.dispose();
    _quantityController.dispose();
    _priceController.dispose();
    _discountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateSubtotal(QuotationFormState state) {
    // Update will be handled by state management
  }

  void _addItem(QuotationFormState state) {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final price = double.tryParse(_priceController.text) ?? 0;

    if (_productNameController.text.isEmpty || quantity <= 0 || price < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, complete todos los campos')),
      );
      return;
    }

    final item = QuotationItem(
      productId: DateTime.now().millisecondsSinceEpoch.toString(),
      productName: _productNameController.text,
      quantity: quantity.toInt(),
      price: price,
    );

    ref
        .read(quotationFormProvider(_selectedCustomerId).notifier)
        .addItem(item);

    _productNameController.clear();
    _quantityController.clear();
    _priceController.clear();

    setState(() {
      _updateSubtotal(state);
    });
  }

  Future<void> _submitQuotation(QuotationFormState state) async {
    if (_customerNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, ingrese el nombre del cliente')),
      );
      return;
    }

    if (state.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, agregue al menos un artículo')),
      );
      return;
    }

    final result = await ref
        .read(quotationFormProvider(_selectedCustomerId).notifier)
        .submitQuotation(
          customerId: _selectedCustomerId ?? 'nuevo',
          customerName: _customerNameController.text,
        );

    if (result != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cotización creada exitosamente')),
      );
      context.go('/quotations');
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeState = ref.watch(storeProvider);
    final storeId = storeState.currentStore?['_id'] ?? storeState.currentStore?['id'];
    final formState = ref.watch(quotationFormProvider(storeId));

    return DashboardLayout(
      title: 'Nueva Cotización',
      currentRoute: '/quotations/create',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Nueva Cotización',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            // Customer section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cliente',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customerNameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del cliente',
                        hintText: 'Ingrese el nombre',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Add items section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agregar artículos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _productNameController,
                      decoration: InputDecoration(
                        labelText: 'Producto/Servicio',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _quantityController,
                            decoration: InputDecoration(
                              labelText: 'Cantidad',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _priceController,
                            decoration: InputDecoration(
                              labelText: 'Precio',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _addItem(formState),
                      icon: const Icon(Icons.add),
                      label: const Text('Agregar artículo'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Items list
            if (formState.items.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Artículos agregados',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: DataTable(
                        columnSpacing: 16,
                        columns: const [
                          DataColumn(label: Text('Producto')),
                          DataColumn(label: Text('Cantidad'), numeric: true),
                          DataColumn(label: Text('Precio'), numeric: true),
                          DataColumn(label: Text('Total'), numeric: true),
                          DataColumn(label: Text('')),
                        ],
                        rows: formState.items.map((item) {
                          final subtotal = item.quantity * item.price;
                          return DataRow(
                            cells: [
                              DataCell(Text(item.productName ?? 'Producto sin nombre')),
                              DataCell(Text(item.quantity.toString())),
                              DataCell(Text('Bs. ${item.price.toStringAsFixed(2)}')),
                              DataCell(Text('Bs. ${subtotal.toStringAsFixed(2)}')),
                              DataCell(
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  onPressed: () {
                                    ref
                                        .read(quotationFormProvider(storeId)
                                            .notifier)
                                        .removeItem(item.productId ?? 'unknown');
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            // Discount and total section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Resumen',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow(
                      context,
                      'Subtotal:',
                      formState.subtotal,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _discountController,
                      decoration: InputDecoration(
                        labelText: 'Descuento',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixText: 'Bs. ',
                      ),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        final discount = double.tryParse(value) ?? 0;
                        ref
                            .read(quotationFormProvider(storeId).notifier)
                            .setDiscountAmount(discount);
                      },
                    ),
                    const SizedBox(height: 16),
                    Divider(color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    _buildSummaryRow(
                      context,
                      'Total:',
                      formState.total,
                      isTotal: true,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _notesController,
                      decoration: InputDecoration(
                        labelText: 'Notas (opcional)',
                        hintText: 'Agregar observaciones...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLines: 3,
                      onChanged: (value) {
                        ref
                            .read(quotationFormProvider(storeId).notifier)
                            .setNotes(value);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.go('/quotations'),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: formState.isLoading
                        ? null
                        : () => _submitQuotation(formState),
                    child: formState.isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Crear cotización'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    double amount, {
    bool isTotal = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : null,
          ),
        ),
        Text(
          'Bs. ${amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: isTotal ? FontWeight.bold : null,
            fontSize: isTotal ? 18 : null,
          ),
        ),
      ],
    );
  }
}
