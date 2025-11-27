import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'package:http_parser/http_parser.dart';
import '../config/api_config.dart';

class ProductProvider {
  static String get baseUrl => ApiConfig.baseUrl;
  final String token;

  ProductProvider(this.token);

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Map<String, String> get _authHeaders => {
    'Authorization': 'Bearer $token',
  };

  // Obtener todos los productos
  Future<Map<String, dynamic>> getProducts({
    String? storeId,
    String? categoryId,
    String? supplierId,
    String? locationId,
    bool? lowStock,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (storeId != null) queryParams['storeId'] = storeId;
      if (categoryId != null) queryParams['categoryId'] = categoryId;
      if (supplierId != null) queryParams['supplierId'] = supplierId;
      if (locationId != null) queryParams['locationId'] = locationId;
      if (lowStock != null) queryParams['lowStock'] = lowStock.toString();

      final uri = Uri.parse('$baseUrl/products')
          .replace(queryParameters: queryParams.isEmpty ? null : queryParams);
      
      if (kDebugMode) {



      }
      
      final response = await http.get(uri, headers: _headers);
      final data = jsonDecode(response.body);

      if (kDebugMode) {


        if (data is Map) {


        }
      }

      if (response.statusCode == 200) {
        // Backend devuelve {status: 'success', results: X, data: {products: [...]}}
        final products = data['data']['products'];
        if (kDebugMode) {

        }
        if (products is List) {
          return {'success': true, 'data': products};
        } else {
          return {'success': false, 'message': 'Formato de respuesta inválido'};
        }
      } else {
        if (kDebugMode) {

        }
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo productos'
        };
      }
    } catch (e) {
      if (kDebugMode) {

      }
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Obtener producto por ID
  Future<Map<String, dynamic>> getProductById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/$id'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Backend devuelve {status: 'success', data: {product: {...}}}
        return {'success': true, 'data': data['data']['product']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error obteniendo producto'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Crear producto
  Future<Map<String, dynamic>> createProduct({
    required String name,
    String? description,
    required double purchasePrice,
    required double salePrice,
    double? weight,
    required String categoryId,
    required String supplierId,
    required String locationId,
    required String storeId,
    required int stock,
    required DateTime expiryDate,
    dynamic imageFile,
    String? imageBytes,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/products'),
      );

      request.headers.addAll(_authHeaders);
      request.fields['name'] = name;
      if (description != null && description.isNotEmpty) request.fields['description'] = description;
      request.fields['purchasePrice'] = purchasePrice.toString();
      request.fields['salePrice'] = salePrice.toString();
      // Solo enviar weight si tiene un valor válido
      if (weight != null && weight > 0) request.fields['weight'] = weight.toString();
      request.fields['categoryId'] = categoryId;
      request.fields['supplierId'] = supplierId;
      request.fields['locationId'] = locationId;
      request.fields['storeId'] = storeId;
      request.fields['stock'] = stock.toString();
      // Enviar fecha de vencimiento en formato ISO 8601
      request.fields['expiryDate'] = expiryDate.toIso8601String();

      if (imageFile != null && imageBytes != null) {
        // Para web, usar imageBytes (base64)
        request.files.add(
          http.MultipartFile.fromBytes(
            'foto',
            Uri.parse(imageBytes).data!.contentAsBytes(),
            filename: 'product_image.jpg',
          ),
        );
      } else if (imageFile != null) {
        // Para móvil, usar el archivo directamente
        // Detectar el tipo MIME del archivo
        final mimeType = lookupMimeType(imageFile.path);
        
        // Si no se detecta, usar el tipo según la extensión
        String contentType = mimeType ?? 'image/jpeg';
        
        // Parsear el tipo MIME para obtener type y subtype
        final mimeParts = contentType.split('/');
        final mediaType = mimeParts.length == 2 
            ? MediaType(mimeParts[0], mimeParts[1])
            : MediaType('image', 'jpeg');
        
        request.files.add(
          await http.MultipartFile.fromPath(
            'foto',
            imageFile.path,
            contentType: mediaType,
          ),
        );
      }
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error creando producto'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Actualizar producto
  Future<Map<String, dynamic>> updateProduct({
    required String id,
    String? name,
    String? description,
    double? purchasePrice,
    double? salePrice,
    double? weight,
    String? categoryId,
    String? supplierId,
    String? locationId,
    DateTime? expiryDate,
    dynamic imageFile,
    String? imageBytes,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$baseUrl/products/$id'),
      );

      request.headers.addAll(_authHeaders);
      if (name != null) request.fields['name'] = name;
      if (description != null) request.fields['description'] = description;
      if (purchasePrice != null) {
        request.fields['purchasePrice'] = purchasePrice.toString();
      }
      if (salePrice != null) {
        request.fields['salePrice'] = salePrice.toString();
      }
      if (weight != null) request.fields['weight'] = weight.toString();
      if (categoryId != null) request.fields['categoryId'] = categoryId;
      if (supplierId != null) request.fields['supplierId'] = supplierId;
      if (locationId != null) request.fields['locationId'] = locationId;
      if (expiryDate != null) {
        request.fields['expiryDate'] = expiryDate.toIso8601String();
      }

      if (imageFile != null && imageBytes != null) {
        // Para web, usar imageBytes (base64)
        request.files.add(
          http.MultipartFile.fromBytes(
            'foto',
            Uri.parse(imageBytes).data!.contentAsBytes(),
            filename: 'product_image.jpg',
          ),
        );
      } else if (imageFile != null) {
        // Para móvil, usar el archivo directamente
        // Detectar el tipo MIME del archivo
        final mimeType = lookupMimeType(imageFile.path);
        
        // Si no se detecta, usar el tipo según la extensión
        String contentType = mimeType ?? 'image/jpeg';
        
        // Parsear el tipo MIME para obtener type y subtype
        final mimeParts = contentType.split('/');
        final mediaType = mimeParts.length == 2 
            ? MediaType(mimeParts[0], mimeParts[1])
            : MediaType('image', 'jpeg');
        
        request.files.add(
          await http.MultipartFile.fromPath(
            'foto',
            imageFile.path,
            contentType: mediaType,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error actualizando producto'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Eliminar producto
  Future<Map<String, dynamic>> deleteProduct(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/products/$id'),
        headers: _headers,
      );

      if (response.statusCode == 204) {
        return {'success': true};
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Error eliminando producto'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Actualizar stock
  Future<Map<String, dynamic>> updateStock({
    required String id,
    required int quantity,
    required String operation, // 'add' o 'subtract'
  }) async {
    try {
      final url = Uri.parse('$baseUrl/products/$id/stock');
      
      if (kDebugMode) {
        print('🔍 Actualizando stock en: $url');
        print('🔍 Quantity: $quantity, Operation: $operation');
      }

      // PATCH - Como está definido en el backend
      final response = await http.patch(
        url,
        headers: _headers,
        body: jsonEncode({
          'quantity': quantity,
          'operation': operation,
        }),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw TimeoutException('Request timeout after 30s'),
      );

      if (kDebugMode) {
        print('🔍 Status: ${response.statusCode}');
        print('🔍 Response: ${response.body}');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {'success': true, 'data': data['data']};
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Sesión expirada. Por favor inicia sesión nuevamente.',
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'No tienes permisos para actualizar el stock.',
        };
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': 'Producto o endpoint no encontrado.',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Error actualizando stock (${response.statusCode})'
        };
      }
    } on TimeoutException catch (e) {
      if (kDebugMode) print('⏱️ Timeout: $e');
      return {
        'success': false,
        'message': 'La solicitud tardó demasiado. Intenta nuevamente.'
      };
    } catch (e) {
      if (kDebugMode) print('❌ Error: $e');
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  // Ajustar stock (wrapper simplificado para updateStock)
  Future<Map<String, dynamic>> adjustStock({
    required String productId,
    required int adjustment,
  }) async {
    final operation = adjustment > 0 ? 'add' : 'subtract';
    final quantity = adjustment.abs();
    
    return await updateStock(
      id: productId,
      quantity: quantity,
      operation: operation,
    );
  }

  // Buscar producto por nombre o código de barras
  Future<Map<String, dynamic>> searchProduct(String query) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products/search/$query'),
        headers: _headers,
      );
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'data': data['data']['product']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Producto no encontrado'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}

