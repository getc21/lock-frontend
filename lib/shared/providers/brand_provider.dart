import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/secure_http_client.dart';

class BrandProvider {
  static String get baseUrl => ApiConfig.baseUrl;
  final String token;

  BrandProvider(this.token);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  /// Headers sin Content-Type para multipart (se setea automáticamente)
  Map<String, String> get _authHeaders => {
    'Authorization': 'Bearer $token',
  };

  /// GET /api/brands
  Future<Map<String, dynamic>> getBrands({int page = 1, int limit = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/brands?page=$page&limit=$limit'),
        headers: _headers,
      );
      await SecureHttpClient.checkResponse(response);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']['brands'], 'pagination': data['pagination']};
      }
      return {'success': false, 'message': data['message'] ?? 'Error loading brands'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// GET /api/brands/:id
  Future<Map<String, dynamic>> getBrandById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/brands/$id'),
        headers: _headers,
      );
      await SecureHttpClient.checkResponse(response);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']['brand']};
      }
      return {'success': false, 'message': data['message'] ?? 'Error loading brand'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// GET /api/brands/:id/stats
  Future<Map<String, dynamic>> getBrandStats(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/brands/$id/stats'),
        headers: _headers,
      );
      await SecureHttpClient.checkResponse(response);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Error loading stats'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// POST /api/brands — Crea marca + admin (multipart para logo)
  Future<Map<String, dynamic>> createBrand({
    required Map<String, dynamic> brandData,
    required Map<String, dynamic> adminData,
    dynamic imageFile,
    String? imageBytes,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/brands'),
      );
      request.headers.addAll(_authHeaders);

      // Enviar brand y admin como JSON strings en campos multipart
      request.fields['brand'] = jsonEncode(brandData);
      request.fields['admin'] = jsonEncode(adminData);

      // Adjuntar imagen si se seleccionó
      if (imageFile != null && imageBytes != null) {
        // Web: imageBytes es un data URI base64
        request.files.add(
          http.MultipartFile.fromBytes(
            'logo',
            Uri.parse(imageBytes).data!.contentAsBytes(),
            filename: 'brand_logo.jpg',
          ),
        );
      } else if (imageFile != null) {
        // Móvil: archivo directo
        request.files.add(
          await http.MultipartFile.fromPath(
            'logo',
            imageFile.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      }
      return {'success': false, 'message': data['message'] ?? 'Error creating brand'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// PATCH /api/brands/:id (multipart para logo)
  Future<Map<String, dynamic>> updateBrand(
    String id,
    Map<String, dynamic> data, {
    dynamic imageFile,
    String? imageBytes,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$baseUrl/brands/$id'),
      );
      request.headers.addAll(_authHeaders);

      // Enviar cada campo del data como field
      data.forEach((key, value) {
        if (value != null) {
          request.fields[key] = value is Map || value is List
              ? jsonEncode(value)
              : value.toString();
        }
      });

      // Adjuntar imagen si se seleccionó
      if (imageFile != null && imageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'logo',
            Uri.parse(imageBytes).data!.contentAsBytes(),
            filename: 'brand_logo.jpg',
          ),
        );
      } else if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'logo',
            imageFile.path,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': responseData['data']['brand']};
      }
      return {'success': false, 'message': responseData['message'] ?? 'Error updating brand'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  /// DELETE /api/brands/:id (soft delete)
  Future<Map<String, dynamic>> deleteBrand(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/brands/$id'),
        headers: _headers,
      );
      await SecureHttpClient.checkResponse(response);

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      }
      return {'success': false, 'message': data['message'] ?? 'Error deleting brand'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
