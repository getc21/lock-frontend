import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/secure_http_client.dart';

class LocationProvider {
  static String get baseUrl => ApiConfig.baseUrl;
  final String token;

  LocationProvider(this.token);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // Obtener todas las ubicaciones
  Future<Map<String, dynamic>> getLocations({String? storeId}) async {
    try {
      String url = '$baseUrl/locations';
      if (storeId != null) {
        url += '?storeId=$storeId';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: _headers,
      );
      await SecureHttpClient.checkResponse(response);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Manejar diferentes estructuras de respuesta
        var locationsData = data['data'];
        
        // Si data es un Map que contiene un array, extraerlo
        if (locationsData is Map && locationsData.containsKey('locations')) {
          locationsData = locationsData['locations'];
        } else if (locationsData is Map && locationsData.containsKey('data')) {
          locationsData = locationsData['data'];
        }
        
        // Asegurar que sea una lista
        if (locationsData is! List) {
          locationsData = [];
        }
        
        return {'success': true, 'data': locationsData};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo ubicaciones'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener ubicación por ID
  Future<Map<String, dynamic>> getLocationById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/locations/$id'),
        headers: _headers,
      );
      await SecureHttpClient.checkResponse(response);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo ubicación'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Crear ubicación
  Future<Map<String, dynamic>> createLocation({
    required String name,
    required String storeId,
    String? description,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/locations'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'storeId': storeId,
          if (description != null) 'description': description,
        }),
      );
      await SecureHttpClient.checkResponse(response);

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error creando ubicación'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Actualizar ubicación
  Future<Map<String, dynamic>> updateLocation({
    required String id,
    String? name,
    String? description,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null && name.isNotEmpty) body['name'] = name;
      if (description != null && description.isNotEmpty) body['description'] = description;

      final response = await http.patch(
        Uri.parse('$baseUrl/locations/$id'),
        headers: _headers,
        body: jsonEncode(body),
      );
      await SecureHttpClient.checkResponse(response);

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error actualizando ubicación'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Eliminar ubicación
  Future<Map<String, dynamic>> deleteLocation(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/locations/$id'),
        headers: _headers,
      );
      await SecureHttpClient.checkResponse(response);

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true, 'message': 'Ubicación eliminada exitosamente'};
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Error eliminando ubicación'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}

