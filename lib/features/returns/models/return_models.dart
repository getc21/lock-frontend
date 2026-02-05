
// Enums
enum ReturnStatus {
  pending('pending', 'Pendiente'),
  approved('approved', 'Aprobada'),
  completed('completed', 'Completada'),
  rejected('rejected', 'Rechazada');

  final String value;
  final String label;
  const ReturnStatus(this.value, this.label);

  factory ReturnStatus.fromValue(String value) {
    return ReturnStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReturnStatus.pending,
    );
  }
}

enum ReturnType {
  return_('return', 'Devolución'),
  exchange('exchange', 'Cambio'),
  partialRefund('partial_refund', 'Reembolso Parcial'),
  fullRefund('full_refund', 'Reembolso Total');

  final String value;
  final String label;
  const ReturnType(this.value, this.label);

  factory ReturnType.fromValue(String value) {
    return ReturnType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReturnType.return_,
    );
  }
}

enum ReturnReasonCategory {
  defective('defective', 'Producto Defectuoso'),
  notAsDescribed('not_as_described', 'No Como se Describe'),
  customerChangeMind('customer_change_mind', 'Cliente Cambió de Parecer'),
  wrongItem('wrong_item', 'Producto Incorrecto'),
  damaged('damaged', 'Dañado'),
  other('other', 'Otro');

  final String value;
  final String label;
  const ReturnReasonCategory(this.value, this.label);

  factory ReturnReasonCategory.fromValue(String value) {
    return ReturnReasonCategory.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ReturnReasonCategory.other,
    );
  }
}

enum RefundMethod {
  efectivo('efectivo', 'Efectivo'),
  tarjeta('tarjeta', 'Tarjeta'),
  transferencia('transferencia', 'Transferencia'),
  storeCreditInternal('cuenta', 'Crédito de Cuenta');

  final String value;
  final String label;
  const RefundMethod(this.value, this.label);

  factory RefundMethod.fromValue(String? value) {
    if (value == null) return RefundMethod.efectivo;
    return RefundMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => RefundMethod.efectivo,
    );
  }
}

// Models
class ReturnItem {
  final String productId;
  final String? productName;
  final int originalQuantity;  // Total quantity in order
  final int returnQuantity;    // Quantity being returned
  final double unitPrice;
  final String returnReason;   // Reason for this item's return

  ReturnItem({
    required this.productId,
    this.productName,
    required this.originalQuantity,
    required this.returnQuantity,
    required this.unitPrice,
    required this.returnReason,
  });

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'originalQuantity': originalQuantity,
        'returnQuantity': returnQuantity,
        'unitPrice': unitPrice,
        'returnReason': returnReason,
      };

  factory ReturnItem.fromJson(Map<String, dynamic> json) {
    // Manejar productId que puede ser string u objeto
    String productId;
    final productIdValue = json['productId'];
    if (productIdValue is Map) {
      productId = productIdValue['_id']?.toString() ?? '';
    } else {
      productId = productIdValue?.toString() ?? '';
    }
    
    return ReturnItem(
      productId: productId,
      productName: json['productName']?.toString(),
      originalQuantity: json['originalQuantity'] ?? 0,
      returnQuantity: json['returnQuantity'] ?? 0,
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      returnReason: json['returnReason']?.toString() ?? '',
    );
  }
}

class ReturnRequest {
  final String? id;
  final String orderId;
  final String orderNumber;
  final ReturnType type;
  final ReturnStatus status;
  final List<ReturnItem> items;
  final double totalRefundAmount;
  final RefundMethod refundMethod;
  final String customerId;
  final String customerName;
  final String storeId;
  final ReturnReasonCategory returnReasonCategory;
  final String? returnReasonDetails;
  final String? requestedBy;
  final DateTime? requestedAt;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? processedBy;
  final DateTime? processedAt;
  final List<String>? attachmentUrls;
  final List<String>? notes;
  final String? internalNotes;

  ReturnRequest({
    this.id,
    required this.orderId,
    required this.orderNumber,
    required this.type,
    required this.status,
    required this.items,
    required this.totalRefundAmount,
    required this.refundMethod,
    required this.customerId,
    required this.customerName,
    required this.storeId,
    required this.returnReasonCategory,
    this.returnReasonDetails,
    this.requestedBy,
    this.requestedAt,
    this.approvedBy,
    this.approvedAt,
    this.processedBy,
    this.processedAt,
    this.attachmentUrls,
    this.notes,
    this.internalNotes,
  });

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'type': type.value,
        'items': items.map((i) => i.toJson()).toList(),
        'refundMethod': refundMethod.value,
        'returnReasonCategory': returnReasonCategory.value,
        'returnReasonDetails': returnReasonDetails,
        'notes': notes?.join('; '),
        'attachmentUrls': attachmentUrls,
        'storeId': storeId,
      };

  factory ReturnRequest.fromJson(Map<String, dynamic> json) {
    // Manejar orderId que puede ser un string o un objeto
    String orderId;
    if (json['orderId'] is Map) {
      orderId = json['orderId']['_id'].toString();
    } else {
      orderId = json['orderId'].toString();
    }

    return ReturnRequest(
      id: json['_id'],
      orderId: orderId,
      orderNumber: json['orderNumber'],
      type: ReturnType.fromValue(json['type']),
      status: ReturnStatus.fromValue(json['status']),
      items: (json['items'] as List)
          .map((i) => ReturnItem.fromJson(i))
          .toList(),
      totalRefundAmount: (json['totalRefundAmount'] ?? 0).toDouble(),
      refundMethod: RefundMethod.fromValue(json['refundMethod']),
      // Manejar customerId que puede ser un string o un objeto
      customerId: _extractId(json['customerId']) ?? '',
      // Extraer customerName desde customerName o desde customerId.name si es objeto poblado
      customerName: json['customerName'] ?? 
          (json['customerId'] is Map ? json['customerId']['name']?.toString() : null) ?? 
          '',
      // Manejar storeId que puede ser un string o un objeto
      storeId: _extractId(json['storeId']) ?? '',
      returnReasonCategory:
          ReturnReasonCategory.fromValue(json['returnReasonCategory']),
      returnReasonDetails: json['returnReasonDetails'],
      // Extraer ID de requestedBy si es un objeto poblado
      requestedBy: _extractId(json['requestedBy']),
      requestedAt:
          json['requestedAt'] != null ? DateTime.parse(json['requestedAt']) : null,
      // Extraer ID de approvedBy si es un objeto poblado
      approvedBy: _extractId(json['approvedBy']),
      approvedAt:
          json['approvedAt'] != null ? DateTime.parse(json['approvedAt']) : null,
      // Extraer ID de processedBy si es un objeto poblado
      processedBy: _extractId(json['processedBy']),
      processedAt:
          json['processedAt'] != null ? DateTime.parse(json['processedAt']) : null,
      attachmentUrls: List<String>.from(json['attachmentUrls'] ?? []),
      notes: List<String>.from(json['notes'] ?? []),
      internalNotes: json['internalNotes'],
    );
  }

  // Extraer ID de un campo que puede ser string o un objeto poblado
  static String? _extractId(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) return value['_id']?.toString();
    return value.toString();
  }
}

class AuditReport {
  final List<AuditLogEntry> logs;
  final FinancialSummary financialSummary;

  AuditReport({
    required this.logs,
    required this.financialSummary,
  });

  factory AuditReport.fromJson(Map<String, dynamic> json) {
    return AuditReport(
      logs: (json['logs'] as List)
          .map((l) => AuditLogEntry.fromJson(l))
          .toList(),
      financialSummary: FinancialSummary.fromJson(json['financialSummary']),
    );
  }
}

class AuditLogEntry {
  final DateTime timestamp;
  final String actionType;
  final String description;
  final String? user;
  final String? status;

  AuditLogEntry({
    required this.timestamp,
    required this.actionType,
    required this.description,
    this.user,
    this.status,
  });

  factory AuditLogEntry.fromJson(Map<String, dynamic> json) {
    return AuditLogEntry(
      timestamp: DateTime.parse(json['timestamp']),
      actionType: json['actionType'],
      description: json['description'],
      user: json['user'],
      status: json['status'],
    );
  }
}

class FinancialSummary {
  final double totalDebits;
  final double totalCredits;

  FinancialSummary({
    required this.totalDebits,
    required this.totalCredits,
  });

  factory FinancialSummary.fromJson(Map<String, dynamic> json) {
    return FinancialSummary(
      totalDebits: (json['totalDebits'] ?? 0).toDouble(),
      totalCredits: (json['totalCredits'] ?? 0).toDouble(),
    );
  }

  double get net => totalDebits - totalCredits;
}
