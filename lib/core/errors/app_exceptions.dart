/// Excepciones tipadas para manejo de errores consistente en toda la app.
///
/// Jerarquía:
/// - [AppException] — Base para todas las excepciones de la app
///   - [ApiException] — Errores de la API REST (incluye statusCode)
///   - [NetworkException] — Sin conexión a internet
///   - [AuthException] — Token expirado, sesión inválida
///   - [ValidationException] — Datos de formulario inválidos
///   - [StorageException] — Errores de almacenamiento local
library;

/// Excepción base de la aplicación.
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
  });

  @override
  String toString() => 'AppException($code): $message';
}

/// Error retornado por la API REST.
class ApiException extends AppException {
  final int statusCode;

  const ApiException(
    super.message, {
    required this.statusCode,
    super.code,
    super.originalError,
  });

  /// True si el error indica un problema del servidor (5xx).
  bool get isServerError => statusCode >= 500;

  /// True si el error indica un recurso no encontrado (404).
  bool get isNotFound => statusCode == 404;

  /// True si el error indica datos inválidos (400/422).
  bool get isValidationError => statusCode == 400 || statusCode == 422;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

/// Sin conexión de red.
class NetworkException extends AppException {
  const NetworkException([
    super.message = 'Sin conexión a internet. Verifica tu red.',
  ]);

  @override
  String toString() => 'NetworkException: $message';
}

/// Token expirado o sesión inválida.
class AuthException extends AppException {
  const AuthException([
    super.message = 'Sesión expirada. Inicia sesión de nuevo.',
  ]);

  @override
  String toString() => 'AuthException: $message';
}

/// Datos de formulario inválidos.
class ValidationException extends AppException {
  final Map<String, String> fieldErrors;

  const ValidationException(
    super.message, {
    this.fieldErrors = const {},
  });

  @override
  String toString() => 'ValidationException: $message (fields: ${fieldErrors.keys.join(', ')})';
}

/// Error de almacenamiento local (SharedPreferences, SecureStorage, etc.).
class StorageException extends AppException {
  const StorageException([
    super.message = 'Error al acceder al almacenamiento local.',
  ]);

  @override
  String toString() => 'StorageException: $message';
}
