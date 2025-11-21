# 📋 Checklist de Migración a SPA - Por Provider

## 🎯 Estado Actual

| Provider | Estado | Prioridad | Estimado |
|----------|--------|-----------|----------|
| ✅ OrderNotifier | ✅ DONE | - | - |
| ⏳ ProductNotifier | ⏱️ TODO | Alta | 1h |
| ⏳ CustomerNotifier | ⏱️ TODO | Alta | 1h |
| ⏳ CategoryNotifier | ⏱️ TODO | Media | 45m |
| ⏳ SupplierNotifier | ⏱️ TODO | Media | 45m |
| ⏳ UserNotifier | ⏱️ TODO | Media | 45m |
| ⏳ LocationNotifier | ⏱️ TODO | Baja | 45m |
| ⏳ DiscountNotifier | ⏱️ TODO | Baja | 45m |

**Total estimado:** 6-8 horas  
**Mejora esperada:** 70-90% reducción en API calls

---

## 📝 Checklist por Provider

### 1. ProductNotifier
- [ ] Importar `CacheService` al inicio
- [ ] Crear campo `final CacheService _cache = CacheService();`
- [ ] Crear método `_getCacheKey()` para generar claves
- [ ] En `loadProducts()`:
  - [ ] Verificar caché antes de cargar
  - [ ] Usar `_cache.getOrFetch()` para requests
  - [ ] Guardar con TTL de 10 minutos
  - [ ] Agregar parámetro `forceRefresh`
- [ ] En `createProduct()`:
  - [ ] Invalidar caché con `invalidatePattern('products:')`
  - [ ] Forzar recarga con `forceRefresh: true`
- [ ] En `updateProduct()`:
  - [ ] Invalidar caché específico y patrón
- [ ] En `deleteProduct()`:
  - [ ] Invalidar caché y reportes
- [ ] Agregar método `getProductById()` con caché
- [ ] Tests unitarios para caché

**Archivo:** `lib/shared/providers/riverpod/product_notifier.dart`  
**Referencia:** OrderNotifier (ya está hecho)

---

### 2. CustomerNotifier
- [ ] Importar `CacheService`
- [ ] Campo `_cache`
- [ ] Método `_getCacheKey(storeId, searchTerm)`
- [ ] En `loadCustomers()`:
  - [ ] Caché con búsqueda opcional
  - [ ] TTL 10 minutos
  - [ ] Parámetro `forceRefresh`
- [ ] En métodos CRUD:
  - [ ] Invalidar patrón `'customers:'`
- [ ] En `searchCustomers()`:
  - [ ] Considerar TTL más corto (5 min)
- [ ] En `getCustomerById()`:
  - [ ] Caché individual

**Archivo:** `lib/shared/providers/riverpod/customer_notifier.dart`

---

### 3. CategoryNotifier
- [ ] Importar `CacheService`
- [ ] Campo `_cache`
- [ ] Método `_getCacheKey(storeId)`
- [ ] En `loadCategories()`:
  - [ ] Caché con TTL 15 minutos (menos cambios)
  - [ ] Parámetro `forceRefresh`
- [ ] En `createCategory()`, `updateCategory()`, `deleteCategory()`:
  - [ ] Invalidar `'categories:' + storeId`
  - [ ] También invalidar reportes (si aplica)

**Archivo:** `lib/shared/providers/riverpod/category_notifier.dart`

---

### 4. SupplierNotifier
- [ ] Importar `CacheService`
- [ ] Campo `_cache`
- [ ] Método `_getCacheKey(storeId)`
- [ ] En `loadSuppliers()`:
  - [ ] Caché con TTL 15 minutos
  - [ ] Parámetro `forceRefresh`
- [ ] En CRUD:
  - [ ] Invalidar patrón `'suppliers:'`

**Archivo:** `lib/shared/providers/riverpod/supplier_notifier.dart`

---

### 5. UserNotifier
- [ ] Importar `CacheService`
- [ ] Campo `_cache`
- [ ] Método `_getCacheKey()` (sin storeId, es global)
- [ ] En `loadUsers()`:
  - [ ] Caché global (mismo para toda la app)
  - [ ] TTL 15 minutos
  - [ ] Parámetro `forceRefresh`
- [ ] En CRUD:
  - [ ] Invalidar patrón `'users:'`
- [ ] Considerar:
  - [ ] Al cambiar rol/permisos, refrescar caché
  - [ ] Al logout, limpiar caché de usuarios

**Archivo:** `lib/shared/providers/riverpod/user_notifier.dart`

---

### 6. LocationNotifier
- [ ] Importar `CacheService`
- [ ] Campo `_cache`
- [ ] Método `_getCacheKey(storeId)`
- [ ] En `loadLocations()`:
  - [ ] Caché con TTL 20 minutos (cambian poco)
  - [ ] Parámetro `forceRefresh`
- [ ] En CRUD:
  - [ ] Invalidar patrón `'locations:' + storeId`

**Archivo:** `lib/shared/providers/riverpod/location_notifier.dart`

---

### 7. DiscountNotifier
- [ ] Importar `CacheService`
- [ ] Campo `_cache`
- [ ] Método `_getCacheKey(storeId, discountType)`
- [ ] En `loadDiscounts()`:
  - [ ] Caché con TTL 5 minutos (datos sensibles, cambios frecuentes)
  - [ ] Parámetro `forceRefresh`
- [ ] En CRUD:
  - [ ] Invalidar patrón `'discounts:'`
  - [ ] Invalidar también `'orders:'` (los descuentos afectan órdenes)

**Archivo:** `lib/shared/providers/riverpod/discount_notifier.dart`

---

## 🔄 Orden Recomendado de Migración

### Fase 1: Dependencias críticas (2h)
1. **ProductNotifier** - Usado en muchas páginas
2. **CustomerNotifier** - Usado en órdenes y reportes

### Fase 2: Módulos principales (2h)
3. **CategoryNotifier** - Usado en productos
4. **SupplierNotifier** - Menos crítico pero importante

### Fase 3: Administrativo (2h)
5. **UserNotifier** - Cambios poco frecuentes
6. **LocationNotifier** - Cambios poco frecuentes
7. **DiscountNotifier** - Sensible, cambios frecuentes

---

## 🎯 Beneficios por Fase

### Fase 1 (2h)
- **API calls reducidas:** 60-70%
- **Impacto visual:** Alto (páginas más rápidas)
- **Complejidad:** Media

### Fase 2 (2h)
- **API calls reducidas:** 80-85%
- **Impacto visual:** Medio
- **Complejidad:** Baja

### Fase 3 (2h)
- **API calls reducidas:** 90%
- **Impacto visual:** Bajo (cambios administrativos)
- **Complejidad:** Muy baja

---

## 🧪 Testing por Provider

### Template de test

```dart
void main() {
  group('ProductNotifier with Cache', () {
    test('debería usar caché al cargar productos dos veces', () async {
      final cache = CacheService();
      final notifier = ProductNotifier(ref);
      
      await notifier.loadProducts(storeId: 'store1');
      final firstTime = DateTime.now();
      
      await notifier.loadProducts(storeId: 'store1');
      final secondTime = DateTime.now();
      
      // Segunda carga debería ser mucho más rápida (de caché)
      expect(secondTime.difference(firstTime).inMilliseconds, lessThan(100));
    });

    test('debería invalidar caché al crear producto', () async {
      final cache = CacheService();
      cache.set('products:store1', [], ttl: Duration(minutes: 10));
      
      await notifier.createProduct(storeId: 'store1', data: {});
      
      expect(cache.get('products:store1'), isNull);
    });

    test('debería forzar recarga con forceRefresh=true', () async {
      final cache = CacheService();
      cache.set('products:store1', [], ttl: Duration(minutes: 10));
      
      await notifier.loadProducts(storeId: 'store1', forceRefresh: true);
      
      // Debería haber hecho un request, no usar caché
      // (verificar con mock de API)
    });
  });
}
```

---

## 📊 Métrica de Progreso

```
Completado:     ████████░░░░░░░░░░░░░░░░ 12.5% (1/8)
En progreso:    Ninguno
Por hacer:      ██████████████████████████ 87.5% (7/8)

Estimado total: 6-8 horas
Completado:     1 hora (OrderNotifier)
Pendiente:      5-7 horas
```

---

## 🎓 Aprendizajes Clave

Después de migrar el primer provider (OrderNotifier), deberías entender:

1. ✅ Cómo crear claves de caché consistentes
2. ✅ Cuándo usar `getOrFetch()` vs `get()`
3. ✅ Cómo invalidar selectivamente
4. ✅ Diferencia entre `invalidate()` e `invalidatePattern()`
5. ✅ Cuándo forzar refresh con `forceRefresh: true`

Los siguientes 7 providers serán mucho más fáciles (copy-paste con ajustes).

---

## 💾 Template Rápido (Copy-Paste)

```dart
import '../../services/cache_service.dart';

class XxxNotifier extends StateNotifier<XxxState> {
  final Ref ref;
  final CacheService _cache = CacheService();
  
  XxxNotifier(this.ref) : super(XxxState());
  
  String _getCacheKey(String storeId) => 'xxx:$storeId';
  
  Future<void> loadXxx(String storeId, {bool forceRefresh = false}) async {
    final cacheKey = _getCacheKey(storeId);
    
    if (!forceRefresh) {
      final cached = _cache.get<List>(cacheKey);
      if (cached != null) {
        state = state.copyWith(items: cached);
        return;
      }
    }
    
    state = state.copyWith(isLoading: true);
    try {
      final items = await _cache.getOrFetch(
        cacheKey,
        () => _api.getXxx(storeId),
        ttl: const Duration(minutes: 10),
      );
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
  
  Future<bool> createXxx(String storeId, Map data) async {
    // ... create logic ...
    _cache.invalidatePattern('xxx:$storeId');
    await loadXxx(storeId, forceRefresh: true);
    return true;
  }
}
```

---

## 🎯 Objetivo Final

Cuando termines todas las migraciones:

✅ **100% de providers con caché**  
✅ **API calls reducidas en 90%**  
✅ **App completamente optimizada como SPA**  
✅ **Documentación y tests completos**  

**Tiempo estimado:** 6-8 horas  
**Impacto:** Transformar el rendimiento completamente

---

## 📞 Problemas Comunes

### Problema: "Caché duplicado en la app"
**Solución:** Cada notifier mantiene su propio CacheService, pero es singleton.
Los datos se comparten automáticamente. Esto es correcto.

### Problema: "TTL muy corto, veo datos stale"
**Solución:** Aumenta TTL a 15-20 min para datos que cambian poco.
Usa 5 min para datos críticos (descuentos, precios).

### Problema: "No sé si invalidar con invalidate() o invalidatePattern()"
**Solución:**
- `invalidate(key)` - Una clave específica
- `invalidatePattern('prefix:')` - Todas las claves que empiezan con prefix

### Problema: "Mi notifier tiene múltiples filtros"
**Solución:** Incluye todos los parámetros en la clave:
```dart
String _getCacheKey(String storeId, String? filter, String? search) 
  => 'products:$storeId:$filter:$search';
```

---

## ✨ Próxima Acción

1. Selecciona **ProductNotifier** como primer provider a migrar
2. Usa el template de arriba
3. Sigue el checklist paso por paso
4. Agrega tests (template incluido)
5. Commit con: `git commit -m "refactor: Agregar caché a ProductNotifier"`
6. Repite para los siguientes 6 providers

**Tiempo para completar Fase 1:** ~2 horas  
**Impacto inmediato:** Reducción visible de latencia en órdenes y productos

---

**Status:** 1/8 providers ✅ Completados  
**Próximo:** ProductNotifier  
**ETA:** Noviembre 22-24, 2025
