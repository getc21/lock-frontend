import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';

class ReceiptProvider {
  final String _token;
  static String get _baseUrl => ApiConfig.baseUrl;

  ReceiptProvider(this._token);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
  };

  Future<Map<String, dynamic>> getReceiptStatistics(String storeId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/audit/receipts/stats?storeId=$storeId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'No autorizado',
        };
      } else {
        return {
          'success': false,
          'message': 'Error obteniendo estadísticas: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getReceiptByNumber({
    required String receiptNumber,
    required String storeId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/audit/receipts/$receiptNumber/$storeId'),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'],
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Comprobante no encontrado',
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'No autorizado',
        };
      } else {
        return {
          'success': false,
          'message': 'Error obteniendo comprobante',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }

  Future<Map<String, dynamic>> getReceiptsByDateRange({
    required String storeId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_baseUrl/audit/receipts/date-range?storeId=$storeId&startDate=$startDate&endDate=$endDate'
        ),
        headers: _headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'data': data['data'] ?? [],
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'No autorizado',
        };
      } else {
        return {
          'success': false,
          'message': 'Error obteniendo comprobantes',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e',
      };
    }
  }
}
