import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../models/return_models.dart';
import '../../../shared/providers/riverpod/auth_notifier.dart';

// Parámetros inmutables para el provider
class ReturnFilters {
  final String storeId;
  final String? status;
  final String? type;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? customerId;
  final String? refundMethod;

  const ReturnFilters({
    required this.storeId,
    this.status,
    this.type,
    this.startDate,
    this.endDate,
    this.customerId,
    this.refundMethod,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReturnFilters &&
          runtimeType == other.runtimeType &&
          storeId == other.storeId &&
          status == other.status &&
          type == other.type &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          customerId == other.customerId &&
          refundMethod == other.refundMethod;

  @override
  int get hashCode =>
      storeId.hashCode ^
      status.hashCode ^
      type.hashCode ^
      startDate.hashCode ^
      endDate.hashCode ^
      customerId.hashCode ^
      refundMethod.hashCode;
}

class ReturnsService {
  final Dio dio;
  // URL del backend en producción
  final String baseUrl = 'https://api.naturalmarkets.net';

  ReturnsService(this.dio);

  // Prueba de conectividad
  Future<bool> healthCheck() async {
    try {
      // Crear un Dio limpio sin headers problemáticos para el health check
      final cleanDio = Dio();
      final response = await cleanDio.get(
        '$baseUrl/returns/test/debug',
        options: Options(
          validateStatus: (status) => true,
        ),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Crear solicitud de devolución
  Future<ReturnRequest> createReturnRequest({
    required String orderId,
    required ReturnType type,
    required List<ReturnItem> items,
    required RefundMethod refundMethod,
    required ReturnReasonCategory reasonCategory,
    String? reasonDetails,
    List<String>? attachmentUrls,
    String? notes,
    required String storeId,
  }) async {
    try {
      final requestData = {
        'orderId': orderId,
        'type': type.value,
        'items': items.map((i) => i.toJson()).toList(),
        'refundMethod': refundMethod.value,
        'reasonCategory': reasonCategory.value,
        'reasonDetails': reasonDetails,
        'attachmentUrls': attachmentUrls ?? [],
        'notes': notes != null ? [notes] : [],  // Convert to array for backend
        'storeId': storeId,
      };
      
      final response = await dio.post(
        '$baseUrl/returns/request',
        data: requestData,
      );

      return ReturnRequest.fromJson(response.data['returnRequest']);
    } catch (e) {
      throw Exception('Error al crear solicitud de devolución: $e');
    }
  }

  // Obtener devoluciones con filtros
  Future<Map<String, dynamic>> getReturnsWithFilters({
    required String storeId,
    String? status,
    String? type,
    DateTime? startDate,
    DateTime? endDate,
    String? customerId,
    String? refundMethod,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      
      // Agregar storeId si no está vacío
      if (storeId.isNotEmpty) {
        queryParams['storeId'] = storeId;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (type != null && type.isNotEmpty) {
        queryParams['type'] = type;
      }
      if (startDate != null) {
        queryParams['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        queryParams['endDate'] = endDate.toIso8601String();
      }
      if (customerId != null) {
        queryParams['customerId'] = customerId;
      }
      if (refundMethod != null) {
        queryParams['refundMethod'] = refundMethod;
      }

      final response = await dio.get(
        '$baseUrl/returns',
        queryParameters: queryParams,
        options: Options(
          validateStatus: (status) => status! < 500, // Aceptar cualquier status < 500
        ),
      );

      // Manejar 304 No Modified
      if (response.statusCode == 304) {
        return {
          'returns': [],
          'summary': {},
        };
      }

      // Si no hay datos en la respuesta, retornar vacío
      if (response.data == null) {
        return {
          'returns': [],
          'summary': {},
        };
      }

      return {
        'returns': (response.data['returns'] as List?)
            ?.map((r) => ReturnRequest.fromJson(r))
            .toList() ?? [],
        'summary': response.data['summary'] ?? {},
      };
    } catch (e) {
      throw Exception('Error al obtener devoluciones: $e');
    }
  }

  // Aprobar solicitud de devolución
  Future<ReturnRequest> approveReturnRequest({
    required String returnRequestId,
    String? approvalNotes,
  }) async {
    try {
      final response = await dio.patch(
        '$baseUrl/returns/$returnRequestId/approve',
        data: {
          'approvalNotes': approvalNotes,
        },
      );

      return ReturnRequest.fromJson(response.data['returnRequest']);
    } catch (e) {
      throw Exception('Error al aprobar devolución: $e');
    }
  }

  // Procesar devolución
  Future<Map<String, dynamic>> processReturnAndRefund({
    required String returnRequestId,
    String? processNotes,
  }) async {
    try {
      final response = await dio.patch(
        '$baseUrl/returns/$returnRequestId/process',
        data: {
          'processNotes': processNotes,
        },
      );

      return {
        'returnRequest': ReturnRequest.fromJson(response.data['returnRequest']),
        'refundTransaction': response.data['refundTransaction'],
      };
    } catch (e) {
      throw Exception('Error al procesar reembolso: $e');
    }
  }

  // Rechazar solicitud
  Future<ReturnRequest> rejectReturnRequest({
    required String returnRequestId,
    required String rejectionReason,
    String? internalNotes,
  }) async {
    try {
      final response = await dio.patch(
        '$baseUrl/returns/$returnRequestId/reject',
        data: {
          'rejectionReason': rejectionReason,
          'internalNotes': internalNotes,
        },
      );

      return ReturnRequest.fromJson(response.data['returnRequest']);
    } catch (e) {
      throw Exception('Error al rechazar devolución: $e');
    }
  }

  // Obtener reporte de auditoría
  Future<AuditReport> getAuditReport({
    required String storeId,
    String? actionType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = {
        'storeId': storeId,
        if (actionType != null) 'actionType': actionType,
        if (startDate != null) 'startDate': startDate.toIso8601String(),
        if (endDate != null) 'endDate': endDate.toIso8601String(),
      };

      final response = await dio.get(
        '$baseUrl/returns/audit/report',
        queryParameters: queryParams,
      );

      return AuditReport.fromJson(response.data);
    } catch (e) {
      throw Exception('Error al obtener reporte de auditoría: $e');
    }
  }
}

// Providers
final returnsServiceProvider = Provider((ref) {
  final authState = ref.watch(authProvider);
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),
  );
  
  // Agregar token de autenticación
  if (authState.token.isNotEmpty) {
    dio.options.headers['Authorization'] = 'Bearer ${authState.token}';
  }
  
  // NO agregar headers que causen problemas CORS
  // Los headers de cache deben ser manejados por el backend, no el cliente
  
  return ReturnsService(dio);
});

// Returns list provider
final returnsProvider = FutureProvider.family<
    Map<String, dynamic>,
    ReturnFilters
>((ref, filters) async {
  final service = ref.watch(returnsServiceProvider);
  return service.getReturnsWithFilters(
    storeId: filters.storeId,
    status: filters.status,
    type: filters.type,
    startDate: filters.startDate,
    endDate: filters.endDate,
    customerId: filters.customerId,
    refundMethod: filters.refundMethod,
  );
});

// Pending returns provider
final pendingReturnsProvider = FutureProvider.family<
    List<ReturnRequest>,
    String
>((ref, storeId) async {
  final result = await ref.watch(
    returnsProvider(ReturnFilters(
      storeId: storeId,
      status: 'pending',
    )).future,
  );
  return result['returns'] as List<ReturnRequest>;
});

// Create return state notifier
class CreateReturnNotifier extends StateNotifier<AsyncValue<ReturnRequest?>> {
  final ReturnsService service;

  CreateReturnNotifier(this.service) : super(const AsyncValue.data(null));

  Future<void> createReturn({
    required String orderId,
    required ReturnType type,
    required List<ReturnItem> items,
    required RefundMethod refundMethod,
    required ReturnReasonCategory reasonCategory,
    String? reasonDetails,
    List<String>? attachmentUrls,
    String? notes,
    required String storeId,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      return await service.createReturnRequest(
        orderId: orderId,
        type: type,
        items: items,
        refundMethod: refundMethod,
        reasonCategory: reasonCategory,
        reasonDetails: reasonDetails,
        attachmentUrls: attachmentUrls,
        notes: notes,
        storeId: storeId,
      );
    });
  }
}

final createReturnProvider =
    StateNotifierProvider<CreateReturnNotifier, AsyncValue<ReturnRequest?>>((ref) {
  final service = ref.watch(returnsServiceProvider);
  return CreateReturnNotifier(service);
});
