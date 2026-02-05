import 'package:flutter/material.dart';
import 'package:bellezapp_web/shared/models/quotation.dart';
import 'package:intl/intl.dart';

class QuotationCardWidget extends StatelessWidget {
  final Quotation quotation;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const QuotationCardWidget({
    super.key,
    required this.quotation,
    required this.onTap,
    required this.onDelete,
  });

  Color _getStatusColor() {
    switch (quotation.status) {
      case 'pending':
        return Colors.orange;
      case 'converted':
        return Colors.green;
      case 'expired':
        return Colors.red;
      case 'cancelled':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  String _getStatusLabel() {
    switch (quotation.status) {
      case 'pending':
        return 'Pendiente';
      case 'converted':
        return 'Convertido';
      case 'expired':
        return 'Expirado';
      case 'cancelled':
        return 'Cancelado';
      default:
        return quotation.status;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cotización #${(quotation.id ?? 'N/A').substring(0, quotation.id != null ? 8 : 3).toUpperCase()}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          quotation.customerName ?? 'Cliente',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusLabel(),
                      style: TextStyle(
                        color: _getStatusColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Fecha de emisión',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy').format(quotation.quotationDate),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vencimiento',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        quotation.expirationDate != null
                            ? DateFormat('dd/MM/yyyy').format(quotation.expirationDate!)
                            : 'No definido',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        'Bs. ${quotation.totalQuotation.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: Colors.red,
                        onPressed: onDelete,
                      ),
                      IconButton(
                        icon: const Icon(Icons.arrow_forward),
                        onPressed: onTap,
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
