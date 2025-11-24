import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class UserProvider {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getUsers() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users'),
        headers: await _getHeaders(),
      );

      if (kDebugMode) {


      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (kDebugMode) {


        }
        
        // Flexible parsing - handle different response structures
        if (data is Map<String, dynamic>) {
          if (data['data'] != null) {
            if (data['data'] is List) {
              if (kDebugMode) {
              }
              return {'success': true, 'data': data['data']};
            } else if (data['data']['users'] is List) {
              if (kDebugMode) {
              }
              return {'success': true, 'data': data['data']['users']};
            } else if (data['data']['data'] is List) {
              if (kDebugMode) {
              }
              return {'success': true, 'data': data['data']['data']};
            }
          } else if (data['users'] is List) {
            if (kDebugMode) {
            }
            return {'success': true, 'data': data['users']};
          }
        }
        
        if (kDebugMode) {

        }
        return {'success': false, 'message': 'Invalid response format'};
      } else {
        if (kDebugMode) {

        }
        return {'success': false, 'message': 'Error al cargar usuarios'};
      }
    } catch (e) {
      if (kDebugMode) {

      }
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> getUserById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data['data'] ?? data};
      } else {
        return {'success': false, 'message': 'Error al cargar usuario'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> createUser(
    String username,
    String firstName,
    String lastName,
    String email,
    String password,
    String role,
  ) async {
    try {
      final body = <String, dynamic>{
        'username': username,
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
      };

      // NO enviar stores - los usuarios no se asocian a tiendas en la creación

      if (kDebugMode) {


      }

      final headers = await _getHeaders();
      
      if (kDebugMode) {

      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/users'),
        headers: headers,
        body: json.encode(body),
      );

      if (kDebugMode) {


      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {'success': true, 'message': 'Usuario creado exitosamente'};
      } else {
        String errorMessage = 'Error al crear usuario';
        try {
          final data = json.decode(response.body);
          errorMessage = data['message'] ?? data['error'] ?? errorMessage;
          if (kDebugMode) {

          }
        } catch (e) {
          if (kDebugMode) {

          }
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      if (kDebugMode) {

      }
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> updateUser(
    String id,
    String username,
    String firstName,
    String lastName,
    String email,
    String role,
    String? password,
  ) async {
    try {
      final body = <String, dynamic>{
        'username': username,
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'role': role,
      };

      // NO enviar stores - los usuarios no se asocian a tiendas

      if (password != null && password.isNotEmpty) {
        body['password'] = password;
      }

      if (kDebugMode) {

      }

      final response = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/users/$id'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (kDebugMode) {


      }

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Usuario actualizado exitosamente'};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Error al actualizar usuario'};
      }
    } catch (e) {
      if (kDebugMode) {

      }
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteUser(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/users/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Usuario eliminado exitosamente'};
      } else {
        return {'success': false, 'message': 'Error al eliminar usuario'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> assignStoreToUser(String userId, String storeId) async {
    try {
      final body = <String, dynamic>{
        'userId': userId,
        'storeId': storeId,
      };

      if (kDebugMode) {


      }

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/users/assign-store'),
        headers: await _getHeaders(),
        body: json.encode(body),
      );

      if (kDebugMode) {


      }

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Tienda asignada exitosamente'};
      } else {
        String errorMessage = 'Error al asignar tienda';
        try {
          final data = json.decode(response.body);
          errorMessage = data['message'] ?? data['error'] ?? errorMessage;
        } catch (e) {
          // Ignorar error de parsing
        }
        return {'success': false, 'message': errorMessage};
      }
    } catch (e) {
      if (kDebugMode) {

      }
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}

