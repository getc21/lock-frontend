import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String? token;
  static const String baseUrl = 'http://localhost:3000/api';

  ApiService({this.token});

  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
    };
    
    if (token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    
    return headers;
  }

  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? params,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      final queryUri = params != null
          ? uri.replace(
              queryParameters: params.map(
                (key, value) => MapEntry(key, value.toString()),
              ),
            )
          : uri;

      final response = await http.get(queryUri, headers: _headers);
      return _handleResponse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(body ?? {}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(body ?? {}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? body,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
        body: jsonEncode(body ?? {}),
      );
      return _handleResponse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> delete(String endpoint) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl$endpoint'),
        headers: _headers,
      );
      return _handleResponse(response);
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {
          'status': 'success',
          'data': decoded['data'] ?? decoded,
          'message': decoded['message'],
        };
      } else {
        return {
          'status': 'error',
          'message': decoded['message'] ?? 'Error en la solicitud',
          'data': decoded['data'],
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Error al procesar la respuesta: $e',
      };
    }
  }
}
