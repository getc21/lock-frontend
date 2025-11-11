import 'package:flutter/material.dart';

enum DiscountType {
  percentage('percentage', 'Porcentaje', '%'),
  fixed('fixed', 'Monto Fijo', '\$');

  const DiscountType(this.value, this.displayName, this.symbol);

  final String value;
  final String displayName;
  final String symbol;

  static DiscountType fromString(String value) {
    return DiscountType.values.firstWhere(
      (DiscountType type) => type.value == value,
      orElse: () => DiscountType.percentage,
    );
  }
}

class Discount {
  final String? id;  // Changed from int? to String? for MongoDB _id
  final String name;
  final String description;
  final DiscountType type;
  final double value;
  final double? minimumAmount;
  final double? maximumDiscount;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime createdAt;

  Discount({
    this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.value,
    this.minimumAmount,
    this.maximumDiscount,
    this.startDate,
    this.endDate,
    this.isActive = true,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) '_id': id,
      'name': name,
      'description': description,
      'type': type.value,
      'value': value,
      if (minimumAmount != null) 'minimumAmount': minimumAmount,
      if (maximumDiscount != null) 'maximumDiscount': maximumDiscount,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      'active': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Discount.fromMap(Map<String, dynamic> map) {
    return Discount(
      id: map['_id']?.toString() ?? map['id']?.toString(),
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      type: DiscountType.fromString(map['type'] ?? 'percentage'),
      value: (map['value'] ?? 0.0).toDouble(),
      minimumAmount: map['minimumAmount']?.toDouble() ?? map['minimum_amount']?.toDouble(),
      maximumDiscount: map['maximumDiscount']?.toDouble() ?? map['maximum_discount']?.toDouble(),
      startDate: map['startDate'] != null || map['start_date'] != null
          ? DateTime.tryParse(map['startDate'] ?? map['start_date'] ?? '') 
          : null,
      endDate: map['endDate'] != null || map['end_date'] != null
          ? DateTime.tryParse(map['endDate'] ?? map['end_date'] ?? '') 
          : null,
      isActive: map['active'] ?? map['is_active'] == 1 || map['is_active'] == true,
      createdAt: DateTime.tryParse(map['createdAt'] ?? map['created_at'] ?? '') ?? DateTime.now(),
    );
  }

  // Calcular el monto del descuento para un total dado
  double calculateDiscountAmount(double totalAmount) {
    // Verificar si el descuento está activo
    if (!isActive) return 0.0;
    
    // Verificar fechas de validez
    final DateTime now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return 0.0;
    if (endDate != null && now.isAfter(endDate!)) return 0.0;
    
    // Verificar monto mínimo
    if (minimumAmount != null && totalAmount < minimumAmount!) return 0.0;
    
    double discountAmount = 0.0;
    
    switch (type) {
      case DiscountType.percentage:
        discountAmount = totalAmount * (value / 100);
        break;
      case DiscountType.fixed:
        discountAmount = value;
        break;
    }
    
    // Aplicar límite máximo de descuento
    if (maximumDiscount != null && discountAmount > maximumDiscount!) {
      discountAmount = maximumDiscount!;
    }
    
    // No puede ser mayor al total
    if (discountAmount > totalAmount) {
      discountAmount = totalAmount;
    }
    
    return discountAmount;
  }

  // Verificar si el descuento es aplicable
  bool isApplicable(double totalAmount) {
    if (!isActive) return false;
    
    final DateTime now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) return false;
    if (endDate != null && now.isAfter(endDate!)) return false;
    
    if (minimumAmount != null && totalAmount < minimumAmount!) return false;
    
    return true;
  }

  // Obtener descripción del descuento
  String get displayValue {
    switch (type) {
      case DiscountType.percentage:
        return '${value.toStringAsFixed(0)}%';
      case DiscountType.fixed:
        return '\$${value.toStringAsFixed(2)}';
    }
  }

  String get displayDescription {
    String desc = '$name - $displayValue';
    if (minimumAmount != null) {
      desc += ' (Min: \$${minimumAmount!.toStringAsFixed(2)})';
    }
    return desc;
  }

  String get statusText {
    if (!isActive) return 'Inactivo';
    
    final DateTime now = DateTime.now();
    if (startDate != null && now.isBefore(startDate!)) {
      return 'Programado';
    }
    if (endDate != null && now.isAfter(endDate!)) {
      return 'Expirado';
    }
    
    return 'Activo';
  }

  Color get statusColor {
    switch (statusText) {
      case 'Activo':
        return Colors.green;
      case 'Programado':
        return Colors.orange;
      case 'Expirado':
      case 'Inactivo':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // Crear copia con modificaciones
  Discount copyWith({
    String? id,
    String? name,
    String? description,
    DiscountType? type,
    double? value,
    double? minimumAmount,
    double? maximumDiscount,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Discount(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      value: value ?? this.value,
      minimumAmount: minimumAmount ?? this.minimumAmount,
      maximumDiscount: maximumDiscount ?? this.maximumDiscount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'Discount{id: $id, name: $name, type: $type, value: $value, isActive: $isActive}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Discount &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

// Clase para aplicar descuento a una orden
class OrderDiscount {
  final Discount discount;
  final double originalAmount;
  final double discountAmount;
  final double finalAmount;

  OrderDiscount({
    required this.discount,
    required this.originalAmount,
    required this.discountAmount,
    required this.finalAmount,
  });

  double get discountPercentage {
    if (originalAmount == 0) return 0.0;
    return (discountAmount / originalAmount) * 100;
  }

  String get summary {
    return '${discount.name}: -\$${discountAmount.toStringAsFixed(2)} (${discountPercentage.toStringAsFixed(1)}%)';
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'discount_id': discount.id,
      'discount_name': discount.name,
      'original_amount': originalAmount,
      'discount_amount': discountAmount,
      'final_amount': finalAmount,
    };
  }
}