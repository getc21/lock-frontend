import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/secure_http_client.dart';

class ReportsProvider {
  static String get baseUrl => ApiConfig.baseUrl;
  final String token;

  ReportsProvider(this.token);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // 📦 Análisis de Rotación de Inventario
  Future<Map<String, dynamic>> getInventoryRotationAnalysis({
    required String storeId,
    required String startDate,
    required String endDate,
    String period = 'monthly',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/financial/analysis/inventory-rotation?storeId=$storeId&startDate=$startDate&endDate=$endDate&period=$period'),
        headers: _headers,
      );
      await SecureHttpClient.checkResponse(response);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo análisis de rotación'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e'
      };
    }
  }

  // 💰 Análisis de Rentabilidad por Producto
  Future<Map<String, dynamic>> getProfitabilityAnalysis({
    required String storeId,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/financial/analysis/profitability?storeId=$storeId&startDate=$startDate&endDate=$endDate'),
        headers: _headers,
      );
      await SecureHttpClient.checkResponse(response);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo análisis de rentabilidad'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e'
      };
    }
  }

  // 📈 Análisis de Tendencias de Ventas
  Future<Map<String, dynamic>> getSalesTrendsAnalysis({
    required String storeId,
    required String startDate,
    required String endDate,
    String period = 'daily',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/financial/analysis/sales-trends?storeId=$storeId&startDate=$startDate&endDate=$endDate&period=$period'),
        headers: _headers,
      );
      await SecureHttpClient.checkResponse(response);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo análisis de tendencias'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e'
      };
    }
  }

  // 🔄 Comparación de Períodos
  Future<Map<String, dynamic>> getPeriodsComparison({
    required String storeId,
    required String currentStartDate,
    required String currentEndDate,
    required String previousStartDate,
    required String previousEndDate,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/financial/analysis/periods-comparison?storeId=$storeId&currentStartDate=$currentStartDate&currentEndDate=$currentEndDate&previousStartDate=$previousStartDate&previousEndDate=$previousEndDate'),
        headers: _headers,
      );
      await SecureHttpClient.checkResponse(response);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo comparación de períodos'
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error de conexión: $e'
      };
    }
  }
}
