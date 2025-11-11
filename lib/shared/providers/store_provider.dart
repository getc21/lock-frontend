import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class StoreProvider {
  static String get baseUrl => ApiConfig.baseUrl;
  final String token;

  StoreProvider(this.token);

  Map<String, String> get _headers => <String, String>{
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // Obtener todas las tiendas
  Future<Map<String, dynamic>> getStores() async {
    try {
      final http.Response response = await http.get(
        Uri.parse('$baseUrl/stores'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final stores = data['data']['stores'];
        if (stores is List) {
          return <String, dynamic>{'success': true, 'data': stores};
        } else {
          return <String, dynamic>{'success': false, 'message': 'Formato de respuesta inválido'};
        }
      } else {
        return <String, dynamic>{
          'success': false,
          'message': data['message'] ?? 'Error obteniendo tiendas'
        };
      }
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener tienda por ID
  Future<Map<String, dynamic>> getStoreById(String id) async {
    try {
      final http.Response response = await http.get(
        Uri.parse('$baseUrl/stores/$id'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return <String, dynamic>{'success': true, 'data': data['data']['store']};
      } else {
        return <String, dynamic>{
          'success': false,
          'message': data['message'] ?? 'Error obteniendo tienda'
        };
      }
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Crear tienda (solo admin)
  Future<Map<String, dynamic>> createStore({
    required String name,
    String? address,
    String? phone,
    String? email,
  }) async {
    try {
      final http.Response response = await http.post(
        Uri.parse('$baseUrl/stores'),
        headers: _headers,
        body: jsonEncode(<String, String>{
          'name': name,
          if (address != null) 'address': address,
          if (phone != null) 'phone': phone,
          if (email != null) 'email': email,
        }),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return <String, dynamic>{'success': true, 'data': data['data']};
      } else {
        return <String, dynamic>{
          'success': false,
          'message': data['message'] ?? 'Error creando tienda'
        };
      }
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Actualizar tienda (solo admin)
  Future<Map<String, dynamic>> updateStore({
    required String id,
    String? name,
    String? address,
    String? phone,
    String? email,
  }) async {
    try {
      final Map<String, dynamic> body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (address != null) body['address'] = address;
      if (phone != null) body['phone'] = phone;
      if (email != null) body['email'] = email;

      final http.Response response = await http.patch(
        Uri.parse('$baseUrl/stores/$id'),
        headers: _headers,
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return <String, dynamic>{'success': true, 'data': data['data']};
      } else {
        return <String, dynamic>{
          'success': false,
          'message': data['message'] ?? 'Error actualizando tienda'
        };
      }
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Eliminar tienda (solo admin)
  Future<Map<String, dynamic>> deleteStore(String id) async {
    try {
      final http.Response response = await http.delete(
        Uri.parse('$baseUrl/stores/$id'),
        headers: _headers,
      );

      if (response.statusCode == 204) {
        return <String, dynamic>{'success': true};
      } else {
        final data = jsonDecode(response.body);
        return <String, dynamic>{
          'success': false,
          'message': data['message'] ?? 'Error eliminando tienda'
        };
      }
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Asignar usuario a tienda
  Future<Map<String, dynamic>> assignUserToStore(String userId, String storeId) async {
    try {
      final http.Response response = await http.post(
        Uri.parse('$baseUrl/stores/$storeId/users'),
        headers: _headers,
        body: jsonEncode(<String, String>{
          'userId': userId,
        }),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return <String, dynamic>{'success': true, 'data': data['data']};
      } else {
        return <String, dynamic>{
          'success': false,
          'message': data['message'] ?? 'Error asignando usuario a tienda'
        };
      }
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Desasignar usuario de tienda
  Future<Map<String, dynamic>> unassignUserFromStore(String userId, String storeId) async {
    try {
      final http.Response response = await http.delete(
        Uri.parse('$baseUrl/stores/$storeId/users/$userId'),
        headers: _headers,
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return <String, dynamic>{'success': true};
      } else {
        final data = jsonDecode(response.body);
        return <String, dynamic>{
          'success': false,
          'message': data['message'] ?? 'Error desasignando usuario de tienda'
        };
      }
    } catch (e) {
      return <String, dynamic>{'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
