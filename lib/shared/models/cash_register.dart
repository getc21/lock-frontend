import 'package:intl/intl.dart';

class CashRegister {
  final String? id;
  final String storeId;
  final String storeName;
  final DateTime openingTime;
  final DateTime? closingTime;
  final double openingAmount;
  final double? closingAmount;
  final double? expectedAmount;
  final String status; // 'open', 'closed'
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String userId;

  CashRegister({
    this.id,
    required this.storeId,
    required this.storeName,
    required this.openingTime,
    this.closingTime,
    required this.openingAmount,
    this.closingAmount,
    this.expectedAmount,
    this.status = 'open',
    required this.createdAt,
    this.updatedAt,
    required this.userId,
  });

  bool get isOpen => status == 'open';
  bool get isClosed => status == 'closed';

  double? get difference => 
      (closingAmount != null && expectedAmount != null) 
          ? closingAmount! - expectedAmount! 
          : null;

  factory CashRegister.fromMap(Map<String, dynamic> json) {
    return CashRegister(
      id: json['_id'] ?? json['id'],
      storeId: json['storeId'] is Map
          ? (json['storeId']['_id'] ?? json['storeId']['id'] ?? 'unknown')
          : (json['storeId'] ?? 'unknown'),
      storeName: json['storeId'] is Map
          ? json['storeId']['name'] ?? 'Tienda'
          : json['storeName'] ?? 'Tienda',
      openingTime: json['openingTime'] != null
          ? DateTime.parse(json['openingTime'].toString())
          : DateTime.now(),
      closingTime: json['closingTime'] != null
          ? DateTime.parse(json['closingTime'].toString())
          : null,
      openingAmount: (json['openingAmount'] as num?)?.toDouble() ?? 0.0,
      closingAmount: (json['closingAmount'] as num?)?.toDouble(),
      expectedAmount: (json['expectedAmount'] as num?)?.toDouble(),
      status: json['status'] ?? 'open',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
      userId: json['userId'] is Map
          ? (json['userId']['_id'] ?? json['userId']['id'] ?? '')
          : json['userId'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'storeId': storeId,
      'storeName': storeName,
      'openingTime': openingTime.toIso8601String(),
      'closingTime': closingTime?.toIso8601String(),
      'openingAmount': openingAmount,
      'closingAmount': closingAmount,
      'expectedAmount': expectedAmount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'userId': userId,
    };
  }

  CashRegister copyWith({
    String? id,
    String? storeId,
    String? storeName,
    DateTime? openingTime,
    DateTime? closingTime,
    double? openingAmount,
    double? closingAmount,
    double? expectedAmount,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
  }) {
    return CashRegister(
      id: id ?? this.id,
      storeId: storeId ?? this.storeId,
      storeName: storeName ?? this.storeName,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      openingAmount: openingAmount ?? this.openingAmount,
      closingAmount: closingAmount ?? this.closingAmount,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userId: userId ?? this.userId,
    );
  }
}

class CashMovement {
  final int? id;
  final String type; // 'apertura', 'cierre', 'venta', 'entrada', 'salida'
  final double amount;
  final String description;
  final String? orderId;
  final String? userId;
  final DateTime createdAt;
  final String? cashRegisterId;
  final String saleType; // 'cash' = venta en efectivo, 'qr' = venta por QR/tarjeta
  final String paymentMethod; // 'efectivo', 'qr', 'tarjeta'

  CashMovement({
    this.id,
    required this.type,
    required this.amount,
    required this.description,
    this.orderId,
    this.userId,
    required this.createdAt,
    this.cashRegisterId,
    this.saleType = 'cash',
    this.paymentMethod = 'efectivo',
  });

  // Getters para determinar tipo (soporta tanto español como inglés)
  bool get isIncome => type == 'entrada' || type == 'income'; // Solo entradas externas, NO ventas
  bool get isOutcome => type == 'salida' || type == 'expense'; // Solo salidas, NO cierre
  bool get isSpecial => type == 'apertura' || type == 'cierre' || type == 'opening' || type == 'closing';

  String get typeDisplayName {
    const labels = {
      'apertura': 'Apertura de Caja',
      'opening': 'Apertura de Caja',
      'cierre': 'Cierre de Caja',
      'closing': 'Cierre de Caja',
      'venta': 'Venta',
      'sale': 'Venta',
      'entrada': 'Entrada de Dinero',
      'income': 'Entrada de Dinero',
      'salida': 'Salida de Dinero',
      'expense': 'Salida de Dinero',
    };
    return labels[type] ?? type;
  }

  String get formattedAmount {
    final formatter = NumberFormat.currency(symbol: 'Bs.', decimalDigits: 2);
    if (isOutcome) {
      return '- ${formatter.format(amount)}';
    }
    return '+ ${formatter.format(amount)}';
  }

  factory CashMovement.fromMap(Map<String, dynamic> json) {
    return CashMovement(
      id: null, // MongoDB returns _id as string, which we don't need to store as int
      type: json['type']?.toString() ?? 'venta',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      description: json['description']?.toString() ?? '',
      orderId: json['orderId']?.toString(),
      userId: json['userId']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : json['date'] != null
              ? DateTime.parse(json['date'].toString())
              : DateTime.now(),
      cashRegisterId: json['cashRegisterId']?.toString(),
      saleType: json['saleType']?.toString() ?? 'cash',
      paymentMethod: json['paymentMethod']?.toString() ?? 'efectivo',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'description': description,
      'orderId': orderId,
      'userId': userId,
      'createdAt': createdAt.toIso8601String(),
      'cashRegisterId': cashRegisterId,
      'saleType': saleType,
      'paymentMethod': paymentMethod,
    };
  }

  // Factorys para crear movimientos específicos
  static CashMovement apertura(double amount, DateTime date, {String? userId}) {
    return CashMovement(
      type: 'apertura',
      amount: amount,
      description: 'Apertura de caja',
      createdAt: date,
      userId: userId,
    );
  }

  static CashMovement cierre(double amount, DateTime date, {String? userId}) {
    return CashMovement(
      type: 'cierre',
      amount: amount,
      description: 'Cierre de caja',
      createdAt: date,
      userId: userId,
    );
  }

  static CashMovement venta(double amount, DateTime date,
      {String? orderId, String? userId}) {
    return CashMovement(
      type: 'venta',
      amount: amount,
      description: 'Venta en efectivo',
      orderId: orderId,
      createdAt: date,
      userId: userId,
    );
  }

  static CashMovement entrada(double amount, String description, DateTime date,
      {String? userId}) {
    return CashMovement(
      type: 'entrada',
      amount: amount,
      description: description,
      createdAt: date,
      userId: userId,
    );
  }

  static CashMovement salida(double amount, String description, DateTime date,
      {String? userId}) {
    return CashMovement(
      type: 'salida',
      amount: amount,
      description: description,
      createdAt: date,
      userId: userId,
    );
  }

  CashMovement copyWith({
    int? id,
    String? type,
    double? amount,
    String? description,
    String? orderId,
    String? userId,
    DateTime? createdAt,
    String? cashRegisterId,
  }) {
    return CashMovement(
      id: id ?? this.id,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      description: description ?? this.description,
      orderId: orderId ?? this.orderId,
      userId: userId ?? this.userId,
      createdAt: createdAt ?? this.createdAt,
      cashRegisterId: cashRegisterId ?? this.cashRegisterId,
    );
  }
}
