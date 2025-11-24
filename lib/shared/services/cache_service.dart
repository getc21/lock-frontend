import 'package:flutter/foundation.dart';

/// Modelo de datos en caché con soporte para TTL (Time To Live)
class CacheEntry<T> {
  final T data;
  final DateTime createdAt;
  final Duration? ttl;

  CacheEntry({
    required this.data,
    required this.createdAt,
    this.ttl,
  });

  /// Verifica si el cache ha expirado
  bool get isExpired {
    if (ttl == null) return false;
    return DateTime.now().difference(createdAt) > ttl!;
  }

  /// Verifica si el cache es válido
  bool get isValid => !isExpired;
}

/// Servicio de caché centralizado con soporte para múltiples tipos de datos
/// Proporciona almacenamiento en memoria con TTL automático e invalidación
class CacheService {
  static final CacheService _instance = CacheService._internal();

  factory CacheService() {
    return _instance;
  }

  CacheService._internal();

  final Map<String, dynamic> _cache = {};
  final Map<String, Future<dynamic>> _pendingRequests = {};

  /// Obtiene un valor del caché
  /// 
  /// Retorna null si el caché no existe, ha expirado o no es del tipo esperado
  T? get<T>(String key) {
    if (!_cache.containsKey(key)) return null;

    final entry = _cache[key] as CacheEntry<T>?;
    if (entry == null) return null;

    if (entry.isExpired) {
      _cache.remove(key);
      return null;
    }

    return entry.data;
  }

  /// Almacena un valor en el caché con TTL opcional
  /// 
  /// [ttl] define cuánto tiempo permanecerá válido el cache
  /// Si no se proporciona, el cache es permanente hasta ser invalidado manualmente
  void set<T>(
    String key,
    T data, {
    Duration? ttl,
  }) {
    _cache[key] = CacheEntry<T>(
      data: data,
      createdAt: DateTime.now(),
      ttl: ttl,
    );
    if (kDebugMode) {
    }
  }

  /// Obtiene un valor del caché o ejecuta [fetcher] si no existe/expiró
  /// 
  /// Evita requests duplicadas usando deduplicación con [_pendingRequests]
  Future<T> getOrFetch<T>(
    String key,
    Future<T> Function() fetcher, {
    Duration? ttl = const Duration(minutes: 5),
  }) async {
    // Retornar valor en caché si es válido
    final cached = get<T>(key);
    if (cached != null) {
      if (kDebugMode) {

      }
      return cached;
    }

    // Evitar requests duplicadas si ya está en progreso
    if (_pendingRequests.containsKey(key)) {
      if (kDebugMode) {
      }
      return await _pendingRequests[key]!;
    }

    // Ejecutar fetcher y almacenar resultado en caché
    if (kDebugMode) {
    }

    try {
      final future = fetcher();
      _pendingRequests[key] = future;

      final result = await future;
      set<T>(key, result, ttl: ttl);
      return result;
    } finally {
      _pendingRequests.remove(key);
    }
  }

  /// Invalida un caché específico
  void invalidate(String key) {
    _cache.remove(key);
    if (kDebugMode) {

    }
  }

  /// Invalida múltiples cachés usando un patrón (prefix)
  /// 
  /// Útil para limpiar todos los cachés relacionados, por ejemplo:
  /// `invalidatePattern('order:')` limpia todos los cachés de órdenes
  void invalidatePattern(String pattern) {
    final keysToRemove = _cache.keys
        .where((key) => key.startsWith(pattern))
        .toList();

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    if (kDebugMode) {
    }
  }

  /// Limpia todo el caché
  void clear() {
    _cache.clear();
    if (kDebugMode) {
    }
  }

  /// Obtiene estadísticas del caché
  Map<String, dynamic> getStats() {
    int validCount = 0;
    int expiredCount = 0;

    for (final entry in _cache.values) {
      if (entry is CacheEntry) {
        entry.isExpired ? expiredCount++ : validCount++;
      }
    }

    return {
      'totalEntries': _cache.length,
      'validEntries': validCount,
      'expiredEntries': expiredCount,
      'keys': _cache.keys.toList(),
    };
  }

  /// Limpia cachés expirados
  void cleanup() {
    final keysToRemove = <String>[];

    for (final entry in _cache.entries) {
      if (entry.value is CacheEntry && (entry.value as CacheEntry).isExpired) {
        keysToRemove.add(entry.key);
      }
    }

    for (final key in keysToRemove) {
      _cache.remove(key);
    }

    if (kDebugMode) {

    }
  }
}

