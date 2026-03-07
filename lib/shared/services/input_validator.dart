/// Servicio centralizado de validación de inputs.
/// 
/// Previene inyección de datos maliciosos y asegura integridad
/// antes de enviar al backend.
class InputValidator {
  // ── Email ──
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static String? validateEmail(String? value, {bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'El email es requerido' : null;
    }
    if (!_emailRegex.hasMatch(value.trim())) {
      return 'Ingresa un email válido';
    }
    if (value.trim().length > 254) {
      return 'El email es demasiado largo';
    }
    return null;
  }

  // ── Username ──
  static final _usernameRegex = RegExp(r'^[a-zA-Z0-9._-]+$');

  static String? validateUsername(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El username es requerido';
    }
    final v = value.trim();
    if (v.length < 3) return 'Mínimo 3 caracteres';
    if (v.length > 30) return 'Máximo 30 caracteres';
    if (!_usernameRegex.hasMatch(v)) {
      return 'Solo letras, números, puntos, guiones y guiones bajos';
    }
    return null;
  }

  // ── Password ──
  static String? validatePassword(String? value, {bool isNew = true}) {
    if (value == null || value.isEmpty) {
      return isNew ? 'La contraseña es requerida' : null;
    }
    if (value.length < 6) return 'Mínimo 6 caracteres';
    if (value.length > 128) return 'Máximo 128 caracteres';
    return null;
  }

  // ── Nombre/Texto general ──
  static String? validateName(String? value, {String field = 'Este campo', int min = 1, int max = 100}) {
    if (value == null || value.trim().isEmpty) {
      return '$field es requerido';
    }
    final v = value.trim();
    if (v.length < min) return '$field debe tener al menos $min caracteres';
    if (v.length > max) return '$field no puede exceder $max caracteres';
    // Prevenir inyección de HTML/scripts
    if (_containsHtmlTags(v)) {
      return '$field contiene caracteres no permitidos';
    }
    return null;
  }

  // ── Precio ──
  static String? validatePrice(String? value, {String field = 'El precio', bool required = true}) {
    if (value == null || value.trim().isEmpty) {
      return required ? '$field es requerido' : null;
    }
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return '$field debe ser un número válido';
    if (parsed < 0) return '$field no puede ser negativo';
    if (parsed > 999999.99) return '$field es demasiado alto';
    return null;
  }

  // ── Stock/Cantidad ──
  static String? validateQuantity(String? value, {String field = 'La cantidad', bool required = true, int max = 999999}) {
    if (value == null || value.trim().isEmpty) {
      return required ? '$field es requerida' : null;
    }
    final parsed = int.tryParse(value.trim());
    if (parsed == null) return '$field debe ser un número entero';
    if (parsed < 0) return '$field no puede ser negativa';
    if (parsed > max) return '$field es demasiado alta (máx: $max)';
    return null;
  }

  // ── Teléfono ──
  static String? validatePhone(String? value, {bool required = false}) {
    if (value == null || value.trim().isEmpty) {
      return required ? 'El teléfono es requerido' : null;
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)+]'), '');
    if (cleaned.length < 7 || cleaned.length > 15) {
      return 'Número de teléfono inválido';
    }
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Solo números en el teléfono';
    }
    return null;
  }

  // ── Sanitización ──

  /// Sanitizar texto: eliminar tags HTML y limitar longitud
  static String sanitize(String input, {int maxLength = 500}) {
    var cleaned = input
        .replaceAll(RegExp(r'<[^>]*>'), '') // Strip HTML tags
        .replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '') // Strip control chars
        .trim();
    if (cleaned.length > maxLength) {
      cleaned = cleaned.substring(0, maxLength);
    }
    return cleaned;
  }

  /// Sanitizar un mapa de datos antes de enviar al API
  static Map<String, dynamic> sanitizeMap(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is String) {
        return MapEntry(key, sanitize(value));
      }
      return MapEntry(key, value);
    });
  }

  // ── Public helpers ──

  /// Checks if a string contains HTML tags or script injection attempts
  static bool containsHtmlOrScript(String value) {
    return _containsHtmlTags(value);
  }

  // ── Helpers privados ──

  static bool _containsHtmlTags(String value) {
    return RegExp(r'<\s*script|<\s*iframe|<\s*object|<\s*embed|javascript:', caseSensitive: false)
        .hasMatch(value);
  }
}
