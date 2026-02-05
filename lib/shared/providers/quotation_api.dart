import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bellezapp_web/shared/models/quotation.dart';
import 'package:bellezapp_web/shared/services/api_service.dart';
import 'package:bellezapp_web/shared/providers/riverpod/auth_notifier.dart';

final quotationApiProvider = Provider((ref) {
  final authState = ref.watch(authProvider);
  final token = authState.token;
  
  return QuotationApi(
    apiService: ApiService(token: token),
  );
});

class QuotationApi {
  final ApiService apiService;

  QuotationApi({required this.apiService});

  Future<List<Quotation>> getQuotations({
    String? storeId,
    String? customerId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int limit = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };

    if (storeId != null) params['storeId'] = storeId;
    if (customerId != null) params['customerId'] = customerId;
    if (status != null) params['status'] = status;
    if (startDate != null) {
      params['startDate'] = startDate.toIso8601String();
    }
    if (endDate != null) {
      params['endDate'] = endDate.toIso8601String();
    }

    try {
      final response = await apiService.get('/quotations', params: params);
      
      if (response['status'] == 'success' && response['data'] != null) {
        final quotationsList = response['data']['quotations'] as List? ?? [];
        return quotationsList
            .map((q) => Quotation.fromMap(q as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Quotation> getQuotation(String id) async {
    try {
      final response = await apiService.get('/quotations/$id');
      
      if (response['status'] == 'success' && response['data'] != null) {
        final data = response['data'] as Map<String, dynamic>;
        final quotationData = data['quotation'] ?? data;
        return Quotation.fromMap(quotationData as Map<String, dynamic>);
      }
      throw Exception('No se pudo obtener la cotización');
    } catch (e) {
      rethrow;
    }
  }

  Future<Quotation> createQuotation({
    required String storeId,
    String? customerId,
    required List<Map<String, dynamic>> items,
    double discountAmount = 0.0,
    String? paymentMethod,
    String? notes,
    DateTime? expirationDate,
  }) async {
    try {
      final body = <String, dynamic>{
        'storeId': storeId,
        'items': items,
        'discountAmount': discountAmount,
      };
      
      // Solo incluir campos opcionales si tienen valor
      if (customerId != null && customerId.isNotEmpty) {
        body['customerId'] = customerId;
      }
      if (paymentMethod != null) {
        body['paymentMethod'] = paymentMethod;
      }
      if (notes != null) {
        body['notes'] = notes;
      }
      if (expirationDate != null) {
        body['expirationDate'] = expirationDate.toIso8601String();
      }

      final response = await apiService.post('/quotations', body: body);
      
      if (response['status'] == 'success' && response['data'] != null) {
        return Quotation.fromMap(response['data'] as Map<String, dynamic>);
      }
      throw Exception('No se pudo crear la cotización');
    } catch (e) {
      rethrow;
    }
  }

  Future<Quotation> updateQuotation(
    String id, {
    List<Map<String, dynamic>>? items,
    double? discountAmount,
    String? paymentMethod,
    String? notes,
    DateTime? expirationDate,
  }) async {
    try {
      final body = <String, dynamic>{};
      
      if (items != null) body['items'] = items;
      if (discountAmount != null) body['discountAmount'] = discountAmount;
      if (paymentMethod != null) body['paymentMethod'] = paymentMethod;
      if (notes != null) body['notes'] = notes;
      if (expirationDate != null) {
        body['expirationDate'] = expirationDate.toIso8601String();
      }

      final response = await apiService.put('/quotations/$id', body: body);
      
      if (response['status'] == 'success' && response['data'] != null) {
        return Quotation.fromMap(response['data'] as Map<String, dynamic>);
      }
      throw Exception('No se pudo actualizar la cotización');
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> convertQuotationToOrder(
    String quotationId, {
    String? paymentMethod,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (paymentMethod != null) body['paymentMethod'] = paymentMethod;

      final response = 
          await apiService.post('/quotations/$quotationId/convert', body: body);
      
      if (response['status'] == 'success') {
        return response['data'] as Map<String, dynamic>;
      }
      throw Exception('No se pudo convertir la cotización a orden');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteQuotation(String id) async {
    try {
      final response = await apiService.delete('/quotations/$id');
      
      if (response['status'] != 'success') {
        throw Exception('No se pudo eliminar la cotización');
      }
    } catch (e) {
      rethrow;
    }
  }
}
