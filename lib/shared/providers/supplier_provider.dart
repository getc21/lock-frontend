import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class SupplierProvider {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    // Priorizar 'auth_token', luego intentar 'token'
    String? token = prefs.getString('auth_token');
    if (token == null || token.isEmpty) {
      token = prefs.getString('token');
    }
    return token;
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getSuppliers() async {
    try {

      
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/suppliers'),
        headers: await _getHeaders(),
      );




      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        


        
        // Flexible parsing - handle different response structures
        if (data is Map<String, dynamic>) {



          
          if (data['data'] != null) {

            
            // Intentar múltiples estructuras
            if (data['data'] is List) {
              return {'success': true, 'data': data['data']};
            } else if (data['data']['proveedores'] is List) {

              return {'success': true, 'data': data['data']['proveedores']};
            } else if (data['data']['suppliers'] is List) {

              return {'success': true, 'data': data['data']['suppliers']};
            } else if (data['data']['data'] is List) {

              return {'success': true, 'data': data['data']['data']};
            }
          } else if (data['proveedores'] is List) {

            return {'success': true, 'data': data['proveedores']};
          } else if (data['suppliers'] is List) {

            return {'success': true, 'data': data['suppliers']};
          }
        }
        

        return {'success': false, 'message': 'Invalid response format'};
      } else if (response.statusCode == 404) {
        return {'success': false, 'message': 'Endpoint /suppliers no existe en el backend'};
      } else {

        return {'success': false, 'message': 'Error al cargar proveedores (${response.statusCode})'};
      }
    } catch (e) {

      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> getSupplierById(String id) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/suppliers/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {'success': true, 'data': data['data'] ?? data};
      } else {
        return {'success': false, 'message': 'Error al cargar proveedor'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> createSupplier(
    String name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    dynamic imageFile, // Puede ser XFile (web) o File (mobile)
    String? imageBytes, // Base64 string para web
  ) async {
    try {
      final token = await _getToken();
      
      // Crear multipart request para enviar imagen
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/suppliers'),
      );

      // Headers
      request.headers['Authorization'] = 'Bearer $token';

      // Campos del formulario
      request.fields['name'] = name;
      if (contactPerson != null && contactPerson.isNotEmpty) {
        request.fields['contactName'] = contactPerson;
      }
      if (phone != null && phone.isNotEmpty) {
        request.fields['contactPhone'] = phone;
      }
      if (email != null && email.isNotEmpty) {
        request.fields['contactEmail'] = email;
      }
      if (address != null && address.isNotEmpty) {
        request.fields['address'] = address;
      }

      // Agregar imagen si existe
      if (imageFile != null && imageBytes != null) {
        // Para web - enviar bytes directamente
        request.files.add(
          http.MultipartFile.fromBytes(
            'foto', // Nombre del campo que espera el backend
            Uri.parse(imageBytes).data!.contentAsBytes(),
            filename: 'supplier_image.jpg',
          ),
        );
      }




      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        try {
          json.decode(response.body);
          return {'success': true, 'message': 'Proveedor creado exitosamente'};
        } catch (e) {


          return {'success': false, 'message': 'Error al procesar respuesta del servidor'};
        }
      } else {

        try {
          final data = json.decode(response.body);
          return {'success': false, 'message': data['message'] ?? 'Error al crear proveedor'};
        } catch (e) {
          return {'success': false, 'message': 'Error del servidor (${response.statusCode})'};
        }
      }
    } catch (e) {

      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> updateSupplier(
    String id,
    String name,
    String? contactPerson,
    String? phone,
    String? email,
    String? address,
    dynamic imageFile,
    String? imageBytes,
  ) async {
    try {
      final token = await _getToken();
      
      // Si hay imagen, usar multipart, sino JSON normal
      if (imageFile != null && imageBytes != null) {
        var request = http.MultipartRequest(
          'PATCH', // Cambiar a PATCH en lugar de PUT
          Uri.parse('${ApiConfig.baseUrl}/suppliers/$id'),
        );

        request.headers['Authorization'] = 'Bearer $token';
        request.fields['name'] = name;
        if (contactPerson != null && contactPerson.isNotEmpty) {
          request.fields['contactName'] = contactPerson;
        }
        if (phone != null && phone.isNotEmpty) {
          request.fields['contactPhone'] = phone;
        }
        if (email != null && email.isNotEmpty) {
          request.fields['contactEmail'] = email;
        }
        if (address != null && address.isNotEmpty) {
          request.fields['address'] = address;
        }

        request.files.add(
          http.MultipartFile.fromBytes(
            'foto',
            Uri.parse(imageBytes).data!.contentAsBytes(),
            filename: 'supplier_image.jpg',
          ),
        );
        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);



        if (response.statusCode == 200) {
          return {'success': true, 'message': 'Proveedor actualizado exitosamente'};
        } else {
          try {
            final data = json.decode(response.body);
            return {'success': false, 'message': data['message'] ?? 'Error al actualizar proveedor'};
          } catch (e) {
            return {'success': false, 'message': 'Error del servidor (${response.statusCode})'};
          }
        }
      } else {
        // Sin imagen, enviar JSON normal con PATCH
        final body = {
          'name': name,
          if (contactPerson != null && contactPerson.isNotEmpty) 'contactName': contactPerson,
          if (phone != null && phone.isNotEmpty) 'contactPhone': phone,
          if (email != null && email.isNotEmpty) 'contactEmail': email,
          if (address != null && address.isNotEmpty) 'address': address,
        };

        final response = await http.patch(
          Uri.parse('${ApiConfig.baseUrl}/suppliers/$id'),
          headers: await _getHeaders(),
          body: json.encode(body),
        );



        if (response.statusCode == 200) {
          return {'success': true, 'message': 'Proveedor actualizado exitosamente'};
        } else {
          try {
            final data = json.decode(response.body);
            return {'success': false, 'message': data['message'] ?? 'Error al actualizar proveedor'};
          } catch (e) {
            return {'success': false, 'message': 'Error del servidor (${response.statusCode})'};
          }
        }
      }
    } catch (e) {

      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteSupplier(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/suppliers/$id'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 204 || response.statusCode == 200) {
        return {'success': true, 'message': 'Proveedor eliminado exitosamente'};
      } else {
        return {'success': false, 'message': 'Error al eliminar proveedor'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error de conexión: $e'};
    }
  }
}

