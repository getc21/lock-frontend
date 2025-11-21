import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/riverpod/customer_detail_notifier.dart';
import '../../shared/providers/riverpod/customer_detail_selectors.dart';

class CustomerDetailPage extends ConsumerStatefulWidget {
  final String customerId;

  const CustomerDetailPage({
    Key? key,
    required this.customerId,
  }) : super(key: key);

  @override
  ConsumerState<CustomerDetailPage> createState() =>
      _CustomerDetailPageState();
}

class _CustomerDetailPageState extends ConsumerState<CustomerDetailPage> {
  @override
  void initState() {
    super.initState();
    // Load customer detail when page is initialized
    Future.microtask(() {
      ref
          .read(customerDetailProvider(widget.customerId).notifier)
          .loadCustomerDetail();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Usar selectores para observar solo lo que cambió
    final isLoading = ref.watch(customerLoadingSelector(widget.customerId));
    final error = ref.watch(customerErrorSelector(widget.customerId));
    final customer = ref.watch(customerSelector(widget.customerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles del Cliente'),
        elevation: 0,
      ),
      body: isLoading
          ? const _LoadingState()
          : error != null
              ? _ErrorState(error: error)
              : customer != null
                  ? _CustomerDetailContent(
                      customer: customer,
                      customerId: widget.customerId,
                    )
                  : const SizedBox.shrink(),
    );
  }
}

class _CustomerDetailContent extends ConsumerStatefulWidget {
  final Map<String, dynamic> customer;
  final String customerId;

  const _CustomerDetailContent({
    Key? key,
    required this.customer,
    required this.customerId,
  }) : super(key: key);

  @override
  ConsumerState<_CustomerDetailContent> createState() =>
      _CustomerDetailContentState();
}

class _CustomerDetailContentState
    extends ConsumerState<_CustomerDetailContent> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.customer['name'] ?? '');
    _emailController =
        TextEditingController(text: widget.customer['email'] ?? '');
    _phoneController =
        TextEditingController(text: widget.customer['phone'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _updateCustomerInfo() {
    ref
        .read(customerDetailProvider(widget.customerId).notifier)
        .updateCustomerInfo(
          name: _nameController.text,
          email: _emailController.text,
          phone: _phoneController.text,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Información actualizada')),
    );
  }

  void _loadOrderHistory() {
    // Load order history - refresh the customer detail
    ref
        .read(customerDetailProvider(widget.customerId).notifier)
        .loadCustomerDetail(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final customerState =
        ref.watch(customerDetailProvider(widget.customerId));

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          _CustomerProfileHeader(customer: widget.customer),

          const SizedBox(height: 24),

          // Contact Information
          _SectionTitle(title: 'Información de Contacto'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _EditableField(
                  label: 'Nombre',
                  controller: _nameController,
                  keyboardType: TextInputType.name,
                ),
                const SizedBox(height: 12),
                _EditableField(
                  label: 'Correo Electrónico',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                _EditableField(
                  label: 'Teléfono',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _updateCustomerInfo,
                    child: const Text('Guardar Cambios'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Customer Statistics
          _SectionTitle(title: 'Estadísticas'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total de Órdenes',
                    value: (widget.customer['totalOrders'] ?? 0).toString(),
                    icon: Icons.shopping_bag,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Gasto Total',
                    value: '\$${(widget.customer['totalSpent'] ?? 0.0).toStringAsFixed(2)}',
                    icon: Icons.attach_money,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Customer Information
          _SectionTitle(title: 'Información General'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                _InfoRow(
                  label: 'ID Cliente',
                  value: widget.customerId,
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Tipo de Cliente',
                  value: widget.customer['type'] ?? 'Regular',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Estado',
                  value: widget.customer['active'] == true
                      ? 'Activo'
                      : 'Inactivo',
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  label: 'Registrado',
                  value: widget.customer['createdAt'] != null
                      ? _formatDate(widget.customer['createdAt'].toString())
                      : 'N/A',
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Delivery Address
          if (widget.customer['address'] != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionTitle(title: 'Dirección de Entrega'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.customer['address'] ?? 'No especificada',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      if (widget.customer['city'] != null)
                        Text(
                          '${widget.customer['city']}, ${widget.customer['state'] ?? ''}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      if (widget.customer['zipCode'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            widget.customer['zipCode'],
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),

          // Recent Orders Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loadOrderHistory,
                icon: const Icon(Icons.history),
                label: const Text('Ver Historial de Órdenes'),
              ),
            ),
          ),

          // Orders List
          if (customerState.customer?['orders'] != null &&
              (customerState.customer!['orders'] as List).isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _SectionTitle(title: 'Órdenes Recientes'),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: List.generate(
                      (customerState.customer!['orders'] as List).length,
                      (index) {
                        final order =
                            customerState.customer!['orders'][index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _OrderCard(order: order),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }
}

class _CustomerProfileHeader extends StatelessWidget {
  final Map<String, dynamic> customer;

  const _CustomerProfileHeader({
    Key? key,
    required this.customer,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border(
          bottom: BorderSide(
            color: Colors.blue[100] ?? Colors.grey,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.blue[400],
              borderRadius: BorderRadius.circular(40),
            ),
            child: Center(
              child: Text(
                _getInitials(customer['name'] ?? 'C'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            customer['name'] ?? 'Cliente Sin Nombre',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            customer['email'] ?? 'Sin correo',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    return name
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0] : '')
        .take(2)
        .join()
        .toUpperCase();
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: Colors.blue),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
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

  const _EditableField({
    Key? key,
    required this.label,
    required this.controller,
    this.keyboardType = TextInputType.text,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
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

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> order;

  const _OrderCard({
    Key? key,
    required this.order,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Orden #${order['_id'] ?? 'N/A'}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(order['status']),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  order['status'] ?? 'Pendiente',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '\$${(order['total'] ?? 0.0).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            order['createdAt'] != null
                ? _formatDate(order['createdAt'].toString())
                : 'N/A',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
      case 'entregado':
        return Colors.green;
      case 'pending':
      case 'pendiente':
        return Colors.orange;
      case 'cancelled':
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateString;
    }
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
          const Text(
            'Error',
            style: TextStyle(
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
