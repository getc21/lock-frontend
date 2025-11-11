import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class DiscountProvider {
  static String get baseUrl => ApiConfig.baseUrl;
  final String token;

  DiscountProvider(this.token);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // Obtener todos los descuentos
  Future<Map<String, dynamic>> getDiscounts({
    bool? active,
    String? storeId,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (active != null) queryParams['active'] = active.toString();
      if (storeId != null) queryParams['storeId'] = storeId;

      final uri = Uri.parse('$baseUrl/discounts').replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: _headers);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final discounts = data['data']['discounts'];

        if (discounts is List) {
          return {'success': true, 'data': discounts};
        } else {
          return {'success': false, 'message': 'Formato de respuesta inválido'};
        }
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo descuentos'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener descuento por ID
  Future<Map<String, dynamic>> getDiscountById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/discounts/$id'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']['discount']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo descuento'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Crear descuento
  Future<Map<String, dynamic>> createDiscount({
    required String name,
    String? description,
    required String type, // percentage, fixed
    required double value,
    double? minimumAmount,
    double? maximumDiscount,
    String? startDate,
    String? endDate,
    bool? active,
    String? storeId, // ⭐ AGREGAR STOREID
  }) async {
    try {
      
      final response = await http.post(
        Uri.parse('$baseUrl/discounts'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          if (description != null) 'description': description,
          'type': type,
          'value': value,
          if (minimumAmount != null) 'minimumAmount': minimumAmount,
          if (maximumDiscount != null) 'maximumDiscount': maximumDiscount,
          if (startDate != null) 'startDate': startDate,
          if (endDate != null) 'endDate': endDate,
          if (active != null) 'active': active,
          if (storeId != null) 'storeId': storeId, // ⭐ INCLUIR STOREID EN EL BODY
        }),
      );
      
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error creando descuento'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Actualizar descuento
  Future<Map<String, dynamic>> updateDiscount({
    required String id,
    String? name,
    String? description,
    String? type,
    double? value,
    double? minimumAmount,
    double? maximumDiscount,
    String? startDate,
    String? endDate,
    bool? active,
  }) async {
    try {
      
      final Map<String, dynamic> body = {};
      if (name != null) body['name'] = name;
      if (description != null) body['description'] = description;
      if (type != null) body['type'] = type;
      if (value != null) body['value'] = value;
      if (minimumAmount != null) body['minimumAmount'] = minimumAmount;
      if (maximumDiscount != null) body['maximumDiscount'] = maximumDiscount;
      if (startDate != null) body['startDate'] = startDate;
      if (endDate != null) body['endDate'] = endDate;
      if (active != null) body['active'] = active;
      final response = await http.patch(
        Uri.parse('$baseUrl/discounts/$id'),
        headers: _headers,
        body: jsonEncode(body),
      );
      

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error actualizando descuento'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Eliminar descuento
  Future<Map<String, dynamic>> deleteDiscount(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/discounts/$id'),
        headers: _headers,
      );
      // Manejar tanto código 200 como 204 para compatibilidad
      if (response.statusCode == 200 || response.statusCode == 204) {
        // Intentar parsear respuesta JSON si hay contenido
        if (response.body.isNotEmpty && response.body.trim().isNotEmpty) {
          try {
            final data = jsonDecode(response.body);
            return {'success': true, 'data': data, 'message': data['message'] ?? 'Descuento eliminado exitosamente'};
          } catch (e) {
            return {'success': true, 'message': 'Descuento eliminado exitosamente'};
          }
        } else {
          return {'success': true, 'message': 'Descuento eliminado exitosamente'};
        }
      } else {
        try {
          final data = jsonDecode(response.body);
          return {
            'success': false,
            'message': data['message'] ?? 'Error eliminando descuento'
          };
        } catch (e) {
          return {
            'success': false,
            'message': 'Error eliminando descuento: código ${response.statusCode}'
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
