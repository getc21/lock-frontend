import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class QuotationFilterWidget extends StatefulWidget {
  final Function(String? status) onStatusChanged;
  final Function(DateTime? start, DateTime? end) onDateRangeChanged;
  final String? selectedStatus;
  final DateTime? startDate;
  final DateTime? endDate;

  const QuotationFilterWidget({
    super.key,
    required this.onStatusChanged,
    required this.onDateRangeChanged,
    this.selectedStatus,
    this.startDate,
    this.endDate,
  });

  @override
  State<QuotationFilterWidget> createState() => _QuotationFilterWidgetState();
}

class _QuotationFilterWidgetState extends State<QuotationFilterWidget> {
  late DateTime? _startDate;
  late DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      widget.onDateRangeChanged(_startDate, _endDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filtros',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          // Status filter
          DropdownButton<String?>(
            isExpanded: true,
            value: widget.selectedStatus,
            hint: const Text('Seleccionar estado'),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Todos'),
              ),
              const DropdownMenuItem<String?>(
                value: 'pending',
                child: Text('Pendiente'),
              ),
              const DropdownMenuItem<String?>(
                value: 'converted',
                child: Text('Convertido'),
              ),
              const DropdownMenuItem<String?>(
                value: 'expired',
                child: Text('Expirado'),
              ),
              const DropdownMenuItem<String?>(
                value: 'cancelled',
                child: Text('Cancelado'),
              ),
            ],
            onChanged: widget.onStatusChanged,
          ),
          const SizedBox(height: 16),
          // Date range picker
          ElevatedButton.icon(
            onPressed: _selectDateRange,
            icon: const Icon(Icons.calendar_today),
            label: Text(
              _startDate != null && _endDate != null
                  ? '${DateFormat('dd/MM/yyyy').format(_startDate!)} - ${DateFormat('dd/MM/yyyy').format(_endDate!)}'
                  : 'Seleccionar rango de fechas',
            ),
          ),
          if (_startDate != null && _endDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _startDate = null;
                    _endDate = null;
                  });
                  widget.onDateRangeChanged(null, null);
                },
                child: const Text('Limpiar fechas'),
              ),
            ),
        ],
      ),
    );
  }
}
