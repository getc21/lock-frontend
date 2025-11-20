# 📋 Estrategia de Migración de GetX a Riverpod

## 🎯 Objetivo
Migrar gradualmente de GetX a Riverpod para aprovechar:
- ✅ Mejor manejo de ciclo de vida
- ✅ State management más predecible
- ✅ Menos problemas con cargas y rebuilds innecesarios
- ✅ Mejor soporte para testing

## 📊 Estado Actual

### GetX Controllers Activos
```
├── auth_controller.dart         → Gestiona autenticación, usuarios y permisos
├── store_controller.dart        → Selección de tienda y sincronización
├── order_controller.dart        → Órdenes y ventas
├── product_controller.dart      → Productos
├── customer_controller.dart     → Clientes
├── category_controller.dart     → Categorías (global, no depende de tienda)
├── discount_controller.dart     → Descuentos
├── location_controller.dart     → Ubicaciones
├── user_controller.dart         → Gestión de usuarios
├── supplier_controller.dart     → Proveedores
├── reports_controller.dart      → Reportes
└── dashboard_collapse_controller.dart → Estado del sidebar (UI local)
```

### Riverpod Providers Creados
```
├── auth_notifier.dart           → AuthState + AuthNotifier + authProvider
├── store_notifier.dart          → StoreState + StoreNotifier + storeProvider
└── order_notifier.dart          → OrderState + OrderNotifier + orderProvider
```

## 🚀 Fase de Migración (4 Fases)

### ⭐ FASE 1: Infraestructura (COMPLETADA)
- ✅ Agregar dependencias: flutter_riverpod, riverpod_annotation, build_runner
- ✅ Crear carpeta `riverpod/` con providers base
- ✅ Envolver app en `ProviderScope`
- ✅ Mantener GetX en paralelo (coexistencia híbrida)

### 🔷 FASE 2: Migrar Auth (PRÓXIMA)
**Tiempo estimado:** 2-3 horas
**Impacto:** Alto (dependen de esto otros módulos)

Pasos:
1. Crear provider selectors para acceso rápido (`userNameProvider`, `isAdminProvider`, etc)
2. Actualizar `LoginPage` a `ConsumerWidget`
3. Reemplazar `Get.put()` en main.dart con inicialización de Riverpod
4. Actualizar widgets que usan `authController` → usar `authProvider`
5. Eliminar `AuthController` de GetX (deprecated)

**Archivo clave:** `login_page.dart`

### 🔶 FASE 3: Migrar Store + Orders (PARALELA)
**Tiempo estimado:** 3-4 horas
**Impacto:** Alto (core de la app)

Pasos:
1. Listeners en Riverpod: cuando cambia tienda, refrescar órdenes
2. Actualizar `OrdersPage` a `ConsumerStatefulWidget`
3. Reemplazar `_orderController` → `ref.read/watch(orderProvider)`
4. Eliminar `OrderController` de GetX
5. Similar para StoreController

**Archivos clave:** `orders_page.dart`, `store_selector.dart` (si existe)

### 🔴 FASE 4: Migrar Resto (GRADUAL)
**Tiempo estimado:** 4-5 horas
**Pasos:**
1. Productos → Riverpod
2. Clientes → Riverpod  
3. Categorías → Riverpod
4. Ubicaciones → Riverpod
5. Descuentos → Riverpod
6. Usuarios → Riverpod
7. Proveedores → Riverpod
8. Reportes → Riverpod
9. Dashboard → Riverpod (UI local)

## 🎪 Arquitectura Híbrida Actual

```dart
// main.dart - Coexistencia
ProviderScope(                    // ← Riverpod
  child: GetMaterialApp(          // ← GetX navigation
    home: GetX(() {              // ← GetX auth state
      // Pero widgets pueden usar ConsumerWidget también
    })
  )
)
```

## 📝 Patrón de Migración

### Antes (GetX)
```dart
class OrdersPage extends StatefulWidget {
  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  late final OrderController _orderController;
  
  @override
  void initState() {
    _orderController = Get.find<OrderController>();
    _orderController.loadOrdersForCurrentStore();
  }
  
  @override
  Widget build(BuildContext context) {
    return Obx(() => 
      ListView.builder(
        itemCount: _orderController.orders.length,
      )
    );
  }
}
```

### Después (Riverpod)
```dart
class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderProvider.notifier).loadOrdersForCurrentStore();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    
    return ListView.builder(
      itemCount: orderState.orders.length,
    );
  }
}
```

## 🔗 Dependencias Entre Providers

```
authProvider
  ├── Necesario para obtener token
  └── Usado por: storeProvider, orderProvider, productProvider, etc.

storeProvider
  ├── Escucha cambios de tienda
  └── Dispara refrescar: orderProvider, productProvider, customerProvider

orderProvider
  ├── Depende de: authProvider, storeProvider
  └── Usado por: OrdersPage, DashboardPage
```

## 🎯 Plan Inmediato

**OPCIÓN A - Migración Rápida (Completa en 1 semana)**
1. Migrar Auth completamente
2. Migrar Orders/Stores
3. Migrar resto en paralelo
4. Eliminar GetX

**OPCIÓN B - Migración Gradual (Completa en 3 semanas, más segura)**
1. Implementar Riverpod en paralelo con GetX
2. Página por página ir migrando
3. Testing después de cada página
4. Eliminar GetX solo cuando todo funcione

## ⚠️ Puntos Críticos a Evitar

1. **No mezclar `Obx()` con `ref.watch()`** en el mismo widget
2. **No olvidar `ProviderScope`** en main.dart (ya hecho ✅)
3. **Listeners para sincronización:** Usar `ref.listen()` en lugar de `ever()`
4. **Loading states:** Usar AsyncValue en lugar de RxBool
5. **Navigation:** Mantener Get.to() / Get.off() (funciona con Riverpod)

## ✅ Checklist de Implementación

- [ ] Fase 1: Setup completado ✅
- [ ] Fase 2: Migrar Auth
- [ ] Fase 3: Migrar Store
- [ ] Fase 3: Migrar Orders
- [ ] Fase 4: Migrar otros controllers
- [ ] Testing completo
- [ ] Eliminar GetX controllers deprecated
- [ ] Performance profiling

## 📚 Referencia Rápida

**Para usar Riverpod en widget:**
```dart
// ConsumerWidget (sin estado)
class MyWidget extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(myProvider);
    return ...
  }
}

// ConsumerStatefulWidget (con estado local)
class MyWidget extends ConsumerStatefulWidget {
  @override
  ConsumerState<MyWidget> createState() => _MyWidgetState();
}

class _MyWidgetState extends ConsumerState<MyWidget> {
  @override
  Widget build(BuildContext context) {
    final data = ref.watch(myProvider);
    return ...
  }
}

// Listener para efectos secundarios
ref.listen(myProvider, (previous, next) {
  // Hacer algo cuando myProvider cambia
});
```

**Para actualizar estado:**
```dart
ref.read(myProvider.notifier).update(...);
```

---

**¿Prefieres Opción A o B?**
