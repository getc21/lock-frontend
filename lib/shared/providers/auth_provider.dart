import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthProvider {
  static String get baseUrl => ApiConfig.baseUrl;
  String? _token;

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  // Constructor privado para inicializar automáticamente
  AuthProvider() {
    _initToken();
  }

  // Inicializar token automáticamente
  Future<void> _initToken() async {
    await loadToken();
  }

  // Cargar token guardado
  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  // Guardar token
  Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  // Eliminar token
  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Headers con token
  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (_token != null) 'Authorization': 'Bearer $_token',
  };

  // Login
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      print('🔵 Intentando login en: $baseUrl/auth/login');
      print('🔵 Username: $username');
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      print('🔵 Status Code: ${response.statusCode}');
      print('🔵 Response Body: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // El backend devuelve: { status: 'success', data: { user: {...}, token: '...' } }
        final responseData = data['data'];
        final token = responseData['token'];
        if (token != null) {
          await _saveToken(token);
        }
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error en el login'
        };
      }
    } catch (e) {
      print('🔴 Error de login: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Register
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String role,
    List<String>? stores,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        'username': username,
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        'role': role,
      };
      
      // Agregar tiendas si se proporcionan
      if (stores != null && stores.isNotEmpty) {
        requestBody['stores'] = stores;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        // El backend devuelve: { status: 'success', data: { user: {...}, token: '...' } }
        final responseData = data['data'];
        return {'success': true, 'data': responseData};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error en el registro'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Get Profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/profile'),
        headers: _headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo perfil'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Logout
  Future<void> logout() async {
    await clearToken();
  }

  // Get All Users
  Future<Map<String, dynamic>> getAllUsers() async {
    try {     
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // El backend devuelve { status: 'success', data: { users: [...] } }
        // Necesitamos extraer el array de usuarios
        var resultData = data['data'];
        // Si data contiene un objeto con un array de usuarios, extraerlo
        if (resultData is Map && resultData.containsKey('users')) {
          resultData = resultData['users'];
        }
        
        return {'success': true, 'data': resultData};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo usuarios'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Get User Assigned Stores
  Future<Map<String, dynamic>> getUserAssignedStores(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/$userId/stores'),
        headers: _headers,
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo tiendas asignadas'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Update User
  Future<Map<String, dynamic>> updateUser(Map<String, dynamic> userData) async {
    try {
      final userId = userData['id'] ?? userData['_id'];
      if (userId == null) {
        return {'success': false, 'message': 'ID de usuario no proporcionado'};
      }

      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: _headers,
        body: jsonEncode(userData),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error actualizando usuario'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Delete User
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/users/$userId'),
        headers: _headers,
      );
      // Manejar respuesta vacía o con solo status code
      if (response.body.isEmpty || response.body.trim().isEmpty) {
        if (response.statusCode == 200 || response.statusCode == 204) {
          return {'success': true, 'message': 'Usuario eliminado exitosamente'};
        } else {
          return {'success': false, 'message': 'Error eliminando usuario: código ${response.statusCode}'};
        }
      }
      final data = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true, 'data': data, 'message': 'Usuario eliminado exitosamente'};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error eliminando usuario'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}
