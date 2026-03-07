import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Callback para notificar al auth notifier que la sesión expiró
typedef SessionExpiredCallback = Future<void> Function();

/// Callback para refrescar el token usando el refresh token
typedef RefreshTokenCallback = Future<bool> Function();

/// Cliente HTTP centralizado con interceptores de seguridad.
/// 
/// Maneja automáticamente:
/// - Headers de autorización
/// - Detección de 401/403 → intento de refresh → auto-logout si falla
/// - Logging en modo debug
class SecureHttpClient {
  static SecureHttpClient? _instance;
  static SessionExpiredCallback? _onSessionExpired;
  static RefreshTokenCallback? _onRefreshToken;
  static bool _isLoggingOut = false;
  static bool _isRefreshing = false;

  SecureHttpClient._();

  static SecureHttpClient get instance {
    _instance ??= SecureHttpClient._();
    return _instance!;
  }

  /// Registrar callback de sesión expirada (llamar desde AuthNotifier)
  static void setSessionExpiredCallback(SessionExpiredCallback callback) {
    _onSessionExpired = callback;
  }

  /// Registrar callback de refresh token (llamar desde AuthNotifier)
  static void setRefreshTokenCallback(RefreshTokenCallback callback) {
    _onRefreshToken = callback;
  }

  /// Obtener token guardado
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  /// Headers con autorización
  Future<Map<String, String>> _authHeaders({Map<String, String>? extra}) async {
    final token = await _getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      ...?extra,
    };
  }

  /// Headers solo auth (sin Content-Type, para multipart)
  Future<Map<String, String>> _authOnlyHeaders() async {
    final token = await _getToken();
    return {
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Verificar respuesta y manejar errores de autenticación
  Future<http.Response> _handleResponse(http.Response response) async {
    if (response.statusCode == 401 || response.statusCode == 403) {
      final body = _tryParseJson(response.body);
      final message = body?['message'] ?? '';

      // 401 = token expirado/inválido → try refresh → logout if fails
      // 403 con "token" en el mensaje = token corrupto → try refresh → logout
      // 403 por permisos (role) NO hace refresh/logout
      final isTokenError = response.statusCode == 401 ||
          (response.statusCode == 403 &&
              (message.toString().toLowerCase().contains('token') ||
               message.toString().toLowerCase().contains('expired')));

      if (isTokenError && !_isLoggingOut && !_isRefreshing) {
        // Try refreshing the token first
        if (_onRefreshToken != null) {
          _isRefreshing = true;
          try {
            final refreshed = await _onRefreshToken!();
            if (refreshed) {
              if (kDebugMode) {
                debugPrint('🔄 SecureHttpClient: Token refreshed successfully');
              }
              _isRefreshing = false;
              return response; // Return original response; caller should retry if needed
            }
          } catch (e) {
            if (kDebugMode) {
              debugPrint('⚠️ SecureHttpClient: Refresh failed: $e');
            }
          } finally {
            _isRefreshing = false;
          }
        }

        // Refresh failed or not available → logout
        _isLoggingOut = true;
        if (kDebugMode) {
          debugPrint('🔒 SecureHttpClient: Sesión expirada (${response.statusCode}). Auto-logout...');
        }
        try {
          if (_onSessionExpired != null) {
            await _onSessionExpired!();
          }
        } finally {
          _isLoggingOut = false;
        }
      }
    }
    return response;
  }

  Map<String, dynamic>? _tryParseJson(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  // ── HTTP Methods ──

  /// Check response for 401/403 and trigger auto-logout if needed.
  /// Can be used by existing providers that still use http.* directly.
  static Future<http.Response> checkResponse(http.Response response) async {
    return instance._handleResponse(response);
  }

  Future<http.Response> get(String url, {Map<String, String>? headers}) async {
    final h = await _authHeaders(extra: headers);
    final response = await http.get(Uri.parse(url), headers: h);
    return _handleResponse(response);
  }

  Future<http.Response> post(String url, {Object? body, Map<String, String>? headers}) async {
    final h = await _authHeaders(extra: headers);
    final response = await http.post(
      Uri.parse(url),
      headers: h,
      body: body is String ? body : jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<http.Response> put(String url, {Object? body, Map<String, String>? headers}) async {
    final h = await _authHeaders(extra: headers);
    final response = await http.put(
      Uri.parse(url),
      headers: h,
      body: body is String ? body : jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<http.Response> patch(String url, {Object? body, Map<String, String>? headers}) async {
    final h = await _authHeaders(extra: headers);
    final response = await http.patch(
      Uri.parse(url),
      headers: h,
      body: body is String ? body : jsonEncode(body),
    );
    return _handleResponse(response);
  }

  Future<http.Response> delete(String url, {Map<String, String>? headers}) async {
    final h = await _authHeaders(extra: headers);
    final response = await http.delete(Uri.parse(url), headers: h);
    return _handleResponse(response);
  }

  /// Para requests multipart (upload de archivos)
  Future<http.StreamedResponse> sendMultipart(http.MultipartRequest request) async {
    final headers = await _authOnlyHeaders();
    request.headers.addAll(headers);
    return request.send();
  }
}
