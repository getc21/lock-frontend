class Customer {
  final String? id;  // Changed from int? to String? for MongoDB _id
  final String name;
  final String phone;
  final String? email;
  final String? address;
  final String? notes;
  final DateTime createdAt;
  final DateTime? lastPurchase;
  final double totalSpent;
  final int totalOrders;
  final int loyaltyPoints;

  Customer({
    this.id,
    required this.name,
    required this.phone,
    this.email,
    this.address,
    this.notes,
    DateTime? createdAt,
    this.lastPurchase,
    this.totalSpent = 0.0,
    this.totalOrders = 0,
    this.loyaltyPoints = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      if (id != null) '_id': id,
      'name': name,
      'phone': phone,
      if (email != null) 'email': email,
      if (address != null) 'address': address,
      if (notes != null) 'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      if (lastPurchase != null) 'lastPurchase': lastPurchase!.toIso8601String(),
      'totalSpent': totalSpent,
      'totalOrders': totalOrders,
      'loyaltyPoints': loyaltyPoints,
    };
  }

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['_id']?.toString() ?? map['id']?.toString(),
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'],
      address: map['address'],
      notes: map['notes'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? map['created_at'] ?? '') ?? DateTime.now(),
      lastPurchase: map['lastPurchase'] != null || map['last_purchase'] != null
          ? DateTime.tryParse(map['lastPurchase'] ?? map['last_purchase'] ?? '') 
          : null,
      totalSpent: (map['totalSpent'] ?? map['total_spent'] ?? 0.0).toDouble(),
      totalOrders: (map['totalOrders'] ?? map['total_orders'] ?? 0) as int,
      loyaltyPoints: (map['loyaltyPoints'] ?? map['loyalty_points'] ?? 0) as int,
    );
  }

  // Métodos de utilidad
  String get displayName {
    return name.isNotEmpty ? name : 'Cliente sin nombre';
  }

  String get formattedPhone {
    if (phone.isEmpty) return 'Sin teléfono';
    // Formatear teléfono si es necesario
    return phone;
  }

  String get customerSince {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(createdAt);
    
    if (difference.inDays < 30) {
      return 'Cliente desde hace ${difference.inDays} días';
    } else if (difference.inDays < 365) {
      final int months = (difference.inDays / 30).floor();
      return 'Cliente desde hace $months ${months == 1 ? 'mes' : 'meses'}';
    } else {
      final int years = (difference.inDays / 365).floor();
      return 'Cliente desde hace $years ${years == 1 ? 'año' : 'años'}';
    }
  }

  String get lastPurchaseFormatted {
    if (lastPurchase == null) return 'Sin compras';
    
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(lastPurchase!);
    
    if (difference.inDays == 0) {
      return 'Hoy';
    } else if (difference.inDays == 1) {
      return 'Ayer';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else if (difference.inDays < 30) {
      final int weeks = (difference.inDays / 7).floor();
      return 'Hace $weeks ${weeks == 1 ? 'semana' : 'semanas'}';
    } else {
      final int months = (difference.inDays / 30).floor();
      return 'Hace $months ${months == 1 ? 'mes' : 'meses'}';
    }
  }

  String get totalSpentFormatted {
    return '\$${totalSpent.toStringAsFixed(2)}';
  }

  String get ordersText {
    return '$totalOrders ${totalOrders == 1 ? 'compra' : 'compras'}';
  }

  String get loyaltyPointsText {
    return '$loyaltyPoints ${loyaltyPoints == 1 ? 'punto' : 'puntos'}';
  }

  // Calcular puntos ganados por una compra (1 punto por cada $10)
  static int calculatePointsFromPurchase(double purchaseAmount) {
    return (purchaseAmount / 10).floor();
  }

  // Obtener el total de puntos ganados basado en el total gastado
  int get expectedPointsFromSpending {
    return calculatePointsFromPurchase(totalSpent);
  }

  // Crear nuevo cliente con datos actualizados
  Customer copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? notes,
    DateTime? createdAt,
    DateTime? lastPurchase,
    double? totalSpent,
    int? totalOrders,
    int? loyaltyPoints,
  }) {
    return Customer(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      lastPurchase: lastPurchase ?? this.lastPurchase,
      totalSpent: totalSpent ?? this.totalSpent,
      totalOrders: totalOrders ?? this.totalOrders,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
    );
  }

  @override
  String toString() {
    return 'Customer{id: $id, name: $name, phone: $phone, totalSpent: $totalSpent, totalOrders: $totalOrders}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Customer &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}