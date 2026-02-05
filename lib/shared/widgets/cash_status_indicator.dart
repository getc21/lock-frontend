import 'package:flutter/material.dart';

class CashStatusIndicator extends StatelessWidget {
  final bool isOpen;
  final double expectedAmount;
  final double actualAmount;
  final VoidCallback onTap;

  const CashStatusIndicator({
    super.key,
    required this.isOpen,
    required this.expectedAmount,
    required this.actualAmount,
    required this.onTap,
  });

  Color _getVarianceColor() {
    final variance = expectedAmount - actualAmount;
    if (variance.abs() < 0.01) return Colors.green;
    if (variance.abs() < expectedAmount * 0.05) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final variance = expectedAmount - actualAmount;
    
    return Card(
      color: isOpen ? Colors.blue[50] : Colors.grey[100],
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Estado de Caja',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: isOpen ? Colors.green : Colors.grey,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isOpen ? 'ABIERTA' : 'CERRADA',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAmountColumn(
                    context,
                    'Esperado',
                    expectedAmount,
                  ),
                  _buildAmountColumn(
                    context,
                    'Actual',
                    actualAmount,
                  ),
                  _buildAmountColumn(
                    context,
                    'Diferencia',
                    variance,
                    color: _getVarianceColor(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (variance.abs() > 0.01)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getVarianceColor().withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        variance > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        color: _getVarianceColor(),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        variance > 0 
                          ? 'Falta: Bs. ${variance.abs().toStringAsFixed(2)}'
                          : 'Sobra: Bs. ${variance.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          color: _getVarianceColor(),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountColumn(
    BuildContext context,
    String label,
    double amount, {
    Color? color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Bs. ${amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}
