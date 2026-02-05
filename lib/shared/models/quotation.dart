class Quotation {
  final String? id;
  final DateTime quotationDate;
  final DateTime? expirationDate;
  final double totalQuotation;
  final String? customerId;
  final String? customerName;
  final String? storeId;
  final List<QuotationItem> items;
  final String? userId;
  final String? discountId;
  final double discountAmount;
  final String? paymentMethod;
  final String? notes;
  final String status; // pending, converted, expired, cancelled
  final String? convertedOrderId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Quotation({
    this.id,
    required this.quotationDate,
    this.expirationDate,
    required this.totalQuotation,
    this.customerId,
    this.customerName,
    required this.storeId,
    required this.items,
    this.userId,
    this.discountId,
    this.discountAmount = 0.0,
    this.paymentMethod,
    this.notes,
    this.status = 'pending',
    this.convertedOrderId,
    this.createdAt,
    this.updatedAt,
  });

  factory Quotation.fromMap(Map<String, dynamic> json) {
    return Quotation(
      id: json['_id'] ?? json['id'],
      quotationDate: json['quotationDate'] != null
          ? DateTime.parse(json['quotationDate'].toString())
          : DateTime.now(),
      expirationDate: json['expirationDate'] != null
          ? DateTime.parse(json['expirationDate'].toString())
          : null,
      totalQuotation: (json['totalQuotation'] as num?)?.toDouble() ?? 0.0,
      customerId: json['customerId'] is Map
          ? json['customerId']['_id'] ?? json['customerId']['id']
          : json['customerId'],
      customerName: json['customerId'] is Map
          ? json['customerId']['name']
          : json['customerName'],
      storeId: json['storeId'] is Map
          ? json['storeId']['_id'] ?? json['storeId']['id']
          : json['storeId'],
      items: json['items'] != null
          ? List<QuotationItem>.from(
              (json['items'] as List).map((x) => QuotationItem.fromMap(x)))
          : [],
      userId: json['userId'] is Map
          ? json['userId']['_id'] ?? json['userId']['id']
          : json['userId'],
      discountId: json['discountId'] is Map
          ? json['discountId']['_id'] ?? json['discountId']['id']
          : json['discountId'],
      discountAmount: (json['discountAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['paymentMethod'],
      notes: json['notes'],
      status: json['status'] ?? 'pending',
      convertedOrderId: json['convertedOrderId'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      '_id': id,
      'quotationDate': quotationDate.toIso8601String(),
      'expirationDate': expirationDate?.toIso8601String(),
      'totalQuotation': totalQuotation,
      'customerId': customerId,
      'storeId': storeId,
      'items': items.map((x) => x.toMap()).toList(),
      'userId': userId,
      'discountId': discountId,
      'discountAmount': discountAmount,
      'paymentMethod': paymentMethod,
      'notes': notes,
      'status': status,
      'convertedOrderId': convertedOrderId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Quotation copyWith({
    String? id,
    DateTime? quotationDate,
    DateTime? expirationDate,
    double? totalQuotation,
    String? customerId,
    String? customerName,
    String? storeId,
    List<QuotationItem>? items,
    String? userId,
    String? discountId,
    double? discountAmount,
    String? paymentMethod,
    String? notes,
    String? status,
    String? convertedOrderId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Quotation(
      id: id ?? this.id,
      quotationDate: quotationDate ?? this.quotationDate,
      expirationDate: expirationDate ?? this.expirationDate,
      totalQuotation: totalQuotation ?? this.totalQuotation,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      storeId: storeId ?? this.storeId,
      items: items ?? this.items,
      userId: userId ?? this.userId,
      discountId: discountId ?? this.discountId,
      discountAmount: discountAmount ?? this.discountAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      convertedOrderId: convertedOrderId ?? this.convertedOrderId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class QuotationItem {
  final String? productId;
  final String? productName;
  final int quantity;
  final double price;

  QuotationItem({
    required this.productId,
    this.productName,
    required this.quantity,
    required this.price,
  });

  factory QuotationItem.fromMap(Map<String, dynamic> json) {
    // Manejar cuando productId es un object o un string
    String? pId;
    String? pName;
    
    if (json['productId'] is Map) {
      final productMap = json['productId'] as Map<String, dynamic>;
      pId = productMap['_id'] ?? productMap['id'];
      pName = productMap['name'];
    } else {
      pId = json['productId'];
      pName = json['productName'];
    }

    // Si aún no tenemos nombre pero tenemos un ID, usarlo como fallback
    if ((pName == null || pName.isEmpty) && pId != null) {
      pName = pId;
    }

    return QuotationItem(
      productId: pId,
      productName: pName,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'quantity': quantity,
      'price': price,
    };
  }

  double get subtotal => quantity * price;

  QuotationItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? price,
  }) {
    return QuotationItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }
}
