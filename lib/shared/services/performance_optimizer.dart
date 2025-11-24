import 'package:flutter/foundation.dart';

/// Estrategia de optimización para mejorar performance en SPA
/// 
/// Implementa:
/// - Lazy loading de datos
/// - Precarga selectiva en background
/// - Reducción de payload
/// - Paginación automática
class PerformanceOptimizer {
  static final PerformanceOptimizer _instance =
      PerformanceOptimizer._internal();

  factory PerformanceOptimizer() {
    return _instance;
  }

  PerformanceOptimizer._internal();

  // Configuración de límites
  static const int defaultPageSize = 20;
  static const int maxItemsToPreload = 50;
  static const Duration preloadDelay = Duration(milliseconds: 500);

  /// Paginar resultados para reducir payload inicial
  /// 
  /// Ejemplo:
  /// ```dart
  /// final page1 = optimizer.paginate(allItems, page: 1, pageSize: 20);
  /// ```
  List<T> paginate<T>(
    List<T> items, {
    int page = 1,
    int pageSize = defaultPageSize,
  }) {
    if (items.isEmpty) return [];
    
    final startIndex = (page - 1) * pageSize;
    final endIndex = startIndex + pageSize;

    if (startIndex >= items.length) return [];

    return items.sublist(
      startIndex,
      endIndex > items.length ? items.length : endIndex,
    );
  }

  /// Obtener total de páginas
  int getTotalPages(int totalItems, {int pageSize = defaultPageSize}) {
    return (totalItems / pageSize).ceil();
  }

  /// Precarga selectiva: cargar solo items críticos primero
  /// 
  /// Filtra items por prioridad (ej: órdenes recientes, productos populares)
  List<T> filterByPriority<T>(
    List<T> items,
    bool Function(T item) priorityFilter, {
    int maxItems = maxItemsToPreload,
  }) {
    final priorityItems = items.where(priorityFilter).toList();
    
    if (priorityItems.length > maxItems) {
      return priorityItems.sublist(0, maxItems);
    }
    
    return priorityItems;
  }

  /// Lazy load: devuelve solo lo esencial al inicio
  /// 
  /// Útil para reducir el tamaño inicial de datos
  Map<String, dynamic> extractEssentialFields(
    Map<String, dynamic> item,
    List<String> essentialFields,
  ) {
    return {
      for (var field in essentialFields)
        if (item.containsKey(field)) field: item[field]
    };
  }

  /// Chunky loading: dividir datos en chunks para cargar progresivamente
  /// 
  /// Ejemplo:
  /// ```dart
  /// final chunks = optimizer.chunkData(items, chunkSize: 10);
  /// for (var chunk in chunks) {
  ///   await processChunk(chunk);
  /// }
  /// ```
  List<List<T>> chunkData<T>(
    List<T> items, {
    int chunkSize = 10,
  }) {
    final chunks = <List<T>>[];
    
    for (int i = 0; i < items.length; i += chunkSize) {
      final end = (i + chunkSize > items.length) ? items.length : i + chunkSize;
      chunks.add(items.sublist(i, end));
    }
    
    return chunks;
  }

  /// Detectar cambios para evitar reloads innecesarios
  bool hasChanges<T>(
    List<T> oldList,
    List<T> newList,
    String Function(T item) getId,
  ) {
    if (oldList.length != newList.length) return true;
    
    final oldIds = oldList.map(getId).toSet();
    final newIds = newList.map(getId).toSet();
    
    return oldIds != newIds;
  }

  /// Calcular estadísticas para monitoreo
  Map<String, dynamic> getLoadingStats({
    required int totalItems,
    required int loadedItems,
    required Duration loadTime,
  }) {
    final percentageLoaded = (loadedItems / totalItems * 100).toStringAsFixed(1);
    final itemsPerSecond = (loadedItems / loadTime.inSeconds).toStringAsFixed(2);
    
    return {
      'totalItems': totalItems,
      'loadedItems': loadedItems,
      'percentageLoaded': '$percentageLoaded%',
      'loadTimeMs': loadTime.inMilliseconds,
      'itemsPerSecond': itemsPerSecond,
      'estimatedTotalTimeMs': (totalItems / (loadedItems / loadTime.inMilliseconds)).toInt(),
    };
  }

  /// Monitorear performance
  void logPerformanceMetrics(String operation, Duration duration) {
    if (kDebugMode) {

    }
  }
}

/// Estrategia de carga para diferentes tipos de datos
enum LoadStrategy {
  /// Cargar todo de una vez
  eager,
  
  /// Cargar en chunks progresivamente
  chunked,
  
  /// Cargar solo cuando se solicite (true lazy)
  lazy,
  
  /// Precarga selectiva + lazy para el resto
  hybrid,
}

/// Configuración de optimización por página
class PageOptimizationConfig {
  final LoadStrategy strategy;
  final int pageSize;
  final int maxPreloadItems;
  final Duration preloadDelay;
  final bool enablePagination;

  const PageOptimizationConfig({
    this.strategy = LoadStrategy.hybrid,
    this.pageSize = PerformanceOptimizer.defaultPageSize,
    this.maxPreloadItems = PerformanceOptimizer.maxItemsToPreload,
    this.preloadDelay = PerformanceOptimizer.preloadDelay,
    this.enablePagination = true,
  });
}

