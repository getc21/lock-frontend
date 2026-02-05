import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:bellezapp_web/shared/models/cash_register.dart';
import 'package:bellezapp_web/shared/services/api_service.dart';
import 'package:bellezapp_web/shared/providers/riverpod/auth_notifier.dart';

final cashRegisterApiProvider = Provider((ref) {
  final authState = ref.watch(authProvider);
  final token = authState.token;
  
  return CashRegisterApi(
    apiService: ApiService(token: token),
  );
});

class CashRegisterApi {
  final ApiService apiService;

  CashRegisterApi({required this.apiService});

  Future<CashRegister?> getCurrentCashRegister(String storeId) async {
    try {
      final response = await apiService.get(
        '/cash/status',
        params: {'storeId': storeId},
      );
      
      if (response['status'] == 'success' && response['data'] != null) {
        return CashRegister.fromMap(response['data'] as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<CashRegister> openCashRegister({
    required String storeId,
    required double openingAmount,
  }) async {
    try {
      final body = {
        'storeId': storeId,
        'openingAmount': openingAmount,
      };

      final response = 
          await apiService.post('/cash/register/open', body: body);
      
      if (response['status'] == 'success' && response['data'] != null) {
        return CashRegister.fromMap(response['data'] as Map<String, dynamic>);
      }
      throw Exception('No se pudo abrir la caja');
    } catch (e) {
      rethrow;
    }
  }

  Future<CashRegister> closeCashRegister({
    required String cashRegisterId,
    required double closingAmount,
  }) async {
    try {
      final body = {
        'closingAmount': closingAmount,
      };

      final response = await apiService.post(
        '/cash/register/close/$cashRegisterId',
        body: body,
      );
      
      if (response['status'] == 'success' && response['data'] != null) {
        return CashRegister.fromMap(response['data'] as Map<String, dynamic>);
      }
      throw Exception('No se pudo cerrar la caja');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CashMovement>> getCashMovements({
    String? cashRegisterId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final params = <String, dynamic>{};
      
      if (cashRegisterId != null) params['cashRegisterId'] = cashRegisterId;
      if (startDate != null) {
        params['startDate'] = startDate.toIso8601String();
      }
      if (endDate != null) {
        params['endDate'] = endDate.toIso8601String();
      }

      final response = 
          await apiService.get('/cash/movements', params: params);
      
      if (response['status'] == 'success' && response['data'] != null) {
        final movementsList = response['data']['movements'] as List? ?? [];
        return movementsList
            .map((m) => CashMovement.fromMap(m as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<CashMovement> addCashMovement({
    required String cashRegisterId,
    required String type,
    required double amount,
    required String description,
    required String storeId,
  }) async {
    try {
      final body = {
        'cashRegisterId': cashRegisterId,
        'type': type,
        'amount': amount,
        'description': description,
        'storeId': storeId,
      };

      final response = await apiService.post(
        '/cash/movements',
        body: body,
      );
      
      if (response['status'] == 'success' && response['data'] != null) {
        return CashMovement.fromMap(response['data'] as Map<String, dynamic>);
      }
      throw Exception('No se pudo agregar el movimiento');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CashMovement>> getCashMovementsByDate({
    required String storeId,
    required DateTime date,
  }) async {
    try {
      final params = {
        'storeId': storeId,
        'date': date.toIso8601String().split('T')[0],
      };

      final response = 
          await apiService.get('/cash/movements', params: params);
      
      if (response['status'] == 'success' && response['data'] != null) {
        final movementsList = response['data']['movements'] as List? ?? [];
        return movementsList
            .map((m) => CashMovement.fromMap(m as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getCashRegisterSummary({
    required String cashRegisterId,
  }) async {
    try {
      final response = 
          await apiService.get('/cash/status', params: {'cashRegisterId': cashRegisterId});
      
      if (response['status'] == 'success' && response['data'] != null) {
        return response['data'] as Map<String, dynamic>;
      }
      throw Exception('No se pudo obtener el resumen de caja');
    } catch (e) {
      rethrow;
    }
  }
}
