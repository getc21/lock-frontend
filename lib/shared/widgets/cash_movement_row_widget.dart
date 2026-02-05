import 'package:flutter/material.dart';
import 'package:bellezapp_web/shared/models/cash_register.dart';
import 'package:intl/intl.dart';

class CashMovementRowWidget extends StatelessWidget {
  final CashMovement movement;
  final TextStyle? textStyle;

  const CashMovementRowWidget({
    super.key,
    required this.movement,
    this.textStyle,
  });

  Color _getTypeColor() {
    if (movement.isIncome) return Colors.green;
    if (movement.isOutcome) return Colors.red;
    return Colors.blue;
  }

  IconData _getTypeIcon() {
    if (movement.isIncome) return Icons.arrow_downward;
    if (movement.isOutcome) return Icons.arrow_upward;
    return Icons.info;
  }

  String _getTypeLabel() {
    return movement.typeDisplayName;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Row(
        children: [
          // Type icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getTypeColor().withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getTypeIcon(),
              color: _getTypeColor(),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Description and type
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  movement.description,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _getTypeLabel(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: _getTypeColor(),
                  ),
                ),
              ],
            ),
          ),
          // Amount and time
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                movement.formattedAmount,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: _getTypeColor(),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                DateFormat('HH:mm').format(movement.createdAt),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
