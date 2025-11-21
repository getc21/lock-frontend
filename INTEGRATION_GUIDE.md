# 🔧 Guía de Integración: .family Providers en Tus Páginas

**Propósito:** Pasos concretos para integrar los `.family` providers en tus páginas de detalle existentes

---

## 🎯 3 Escenarios de Integración

### Escenario 1: No tienes páginas de detalle (Crear nuevas)

**Usa el archivo de ejemplo:**
```
lib/shared/examples/family_providers_example.dart
```

Copiar:
- `OrderDetailPageExample` → `OrderDetailPage`
- `ProductDetailPageExample` → `ProductDetailPage`  
- `CustomerDetailPageExample` → `CustomerDetailPage`

Adaptar a tu UI y listo.

---

### Escenario 2: Tienes páginas de detalle sin Riverpod (Refactorizar)

**Si tu página es un StatefulWidget:**

```dart
// ❌ ANTES
class OrderDetailPage extends StatefulWidget {
  final String orderId;
  
  OrderDetailPage({required this.orderId});

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  Map<String, dynamic>? order;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    // Manual API call...
  }

  @override
  Widget build(BuildContext context) {
    // ...
  }
}
```

**✅ DESPUÉS: Convertir a ConsumerStatefulWidget**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/providers/riverpod/order_detail_notifier.dart';

class OrderDetailPage extends ConsumerStatefulWidget {
  final String orderId;
  
  const OrderDetailPage({required this.orderId});

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  @override
  void initState() {
    super.initState();
    // El provider se carga automático en build()
    // Pero si quieres iniciar explícitamente:
    Future.microtask(() {
      ref.read(orderDetailProvider(widget.orderId).notifier)
          .loadOrderDetail();
    });
  }

  @override
  Widget build(BuildContext context) {
    // En lugar de State manual, usa el provider
    final orderDetail = ref.watch(orderDetailProvider(widget.orderId));

    // Simplemente sigue el patrón:
    if (orderDetail.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (orderDetail.error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle')),
        body: Center(child: Text(orderDetail.error!)),
      );
    }

    if (orderDetail.order != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle')),
        body: OrderDetailContent(order: orderDetail.order!),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle')),
      body: const SizedBox.shrink(),
    );
  }
}
```

**Cambios principales:**
- `StatefulWidget` → `ConsumerStatefulWidget`
- `State` → `ConsumerState`
- Eliminar variables de estado manual (`order`, `isLoading`)
- Usar `ref.watch()` en lugar de `setState()`
- Eliminar métodos `_loadOrder()` manuales

---

### Escenario 3: Tienes páginas con FutureBuilder (Simplificar)

**❌ ANTES: Caótico con FutureBuilder**

```dart
class OrderDetailPage extends StatelessWidget {
  final String orderId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalle')),
      body: FutureBuilder(
        future: _orderProvider.getOrderById(orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.hasData) {
            return OrderDetailContent(order: snapshot.data);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
```

**✅ DESPUÉS: Limpio con Riverpod**

```dart
class OrderDetailPage extends ConsumerWidget {
  final String orderId;
  
  const OrderDetailPage({required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderDetail = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle')),
      body: orderDetail.isLoading
          ? const Center(child: CircularProgressIndicator())
          : orderDetail.error != null
              ? Center(child: Text('Error: ${orderDetail.error}'))
              : orderDetail.order != null
                  ? OrderDetailContent(order: orderDetail.order!)
                  : const SizedBox.shrink(),
    );
  }
}
```

**Beneficios:**
- Menos líneas de código
- Mejor manejo de estado
- Caché automático
- Sin memory leaks de Future

---

## 📍 Paso a Paso: Integración Completa

### Paso 1: Agregar importación
```dart
import 'package:bellezapp/shared/providers/riverpod/order_detail_notifier.dart';
```

### Paso 2: Cambiar clase base
```dart
// ❌ De esto:
class OrderDetailPage extends StatefulWidget {
  // ...
}

// ✅ A esto:
class OrderDetailPage extends ConsumerStatefulWidget {
  // ...
}
```

### Paso 3: Cambiar State
```dart
// ❌ De esto:
class _OrderDetailPageState extends State<OrderDetailPage> {
  // ...
}

// ✅ A esto:
class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  // ...
}
```

### Paso 4: Reemplazar build()
```dart
// ❌ ANTES: Variables de estado
@override
Widget build(BuildContext context) {
  return Scaffold(
    body: isLoading ? LoadingWidget() : OrderContent(order: order),
  );
}

// ✅ DESPUÉS: Observar provider
@override
Widget build(BuildContext context, WidgetRef ref) {
  final orderDetail = ref.watch(orderDetailProvider(widget.orderId));
  
  return Scaffold(
    body: orderDetail.isLoading 
        ? LoadingWidget() 
        : OrderContent(order: orderDetail.order!),
  );
}
```

### Paso 5: Actualizar métodos
```dart
// ❌ ANTES: setState manual
Future<void> _updateStatus(String newStatus) async {
  setState(() => isLoading = true);
  try {
    await _orderProvider.updateStatus(orderId, newStatus);
    setState(() => isLoading = false);
  } catch (e) {
    setState(() => isLoading = false);
  }
}

// ✅ DESPUÉS: Provider se actualiza automático
Future<void> _updateStatus(String newStatus) async {
  await ref.read(orderDetailProvider(widget.orderId).notifier)
      .updateOrderStatus(status: newStatus);
  // ¡El estado se actualiza automático en build()!
}
```

---

## 🗂️ Ejemplo Real: OrdersPage → OrderDetailPage

### OrdersPage (lista)
```dart
// Mostrar lista de órdenes
class OrdersPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Cargar lista (sin detalles)
    final orders = ref.watch(orderProvider.select((s) => s.orders));

    return Scaffold(
      appBar: AppBar(title: const Text('Órdenes')),
      body: ListView.builder(
        itemCount: orders.length,
        itemBuilder: (context, index) {
          final order = orders[index];
          return ListTile(
            title: Text('Orden ${order['_id']}'),
            subtitle: Text('Total: \$${order['total']}'),
            onTap: () {
              // ✅ Navegar a detalle (lazy loading)
              Navigator.push(context, MaterialPageRoute(
                builder: (_) => OrderDetailPage(
                  orderId: order['_id'],
                ),
              ));
            },
          );
        },
      ),
    );
  }
}
```

### OrderDetailPage (detalle)
```dart
// Mostrar detalle de una orden específica
class OrderDetailPage extends ConsumerStatefulWidget {
  final String orderId;
  
  const OrderDetailPage({required this.orderId});

  @override
  ConsumerState<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends ConsumerState<OrderDetailPage> {
  @override
  void initState() {
    super.initState();
    // Cargar al entrar
    Future.microtask(() {
      ref.read(orderDetailProvider(widget.orderId).notifier)
          .loadOrderDetail();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderDetail = ref.watch(orderDetailProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: Text('Orden ${widget.orderId}'),
        actions: [
          if (!orderDetail.isLoading)
            PopupMenuButton(
              itemBuilder: (_) => [
                const PopupMenuItem(
                  child: Text('Cambiar a Pendiente'),
                  value: 'pending',
                ),
                const PopupMenuItem(
                  child: Text('Cambiar a Completado'),
                  value: 'completed',
                ),
              ],
              onSelected: (status) async {
                final success = await ref
                    .read(orderDetailProvider(widget.orderId).notifier)
                    .updateOrderStatus(status: status);
                
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Estado actualizado')),
                  );
                }
              },
            ),
        ],
      ),
      body: orderDetail.isLoading
          ? const Center(child: CircularProgressIndicator())
          : orderDetail.error != null
              ? Center(child: Text('Error: ${orderDetail.error}'))
              : OrderDetailContent(order: orderDetail.order!),
    );
  }
}

// Widget reutilizable
class OrderDetailContent extends StatelessWidget {
  final Map<String, dynamic> order;
  
  const OrderDetailContent({required this.order});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ID: ${order['_id']}'),
          Text('Total: \$${order['total']}'),
          Text('Estado: ${order['status']}'),
          Text('Cliente: ${order['customerId']}'),
          // Más detalles...
        ],
      ),
    );
  }
}
```

---

## ✅ Checklist de Integración

Para cada página de detalle:

- [ ] Cambiar `StatefulWidget` → `ConsumerStatefulWidget`
- [ ] Cambiar `State` → `ConsumerState`
- [ ] Agregar `import` del provider
- [ ] Reemplazar variables de estado con `ref.watch()`
- [ ] Eliminar `setState()` calls
- [ ] Eliminar métodos de carga manual
- [ ] Probar que funciona
- [ ] Verificar que el caché funciona (abrir/cerrar/abrir)
- [ ] Probar actualizaciones (editar/actualizar)

---

## 🐛 Debugging

Si algo no funciona:

1. **Agregar debug print:**
```dart
@override
void initState() {
  super.initState();
  print('OrderDetailPage opened for: ${widget.orderId}');
  Future.microtask(() {
    ref.read(orderDetailProvider(widget.orderId).notifier)
        .loadOrderDetail();
  });
}
```

2. **Ver logs en console:**
```
✅ Orden obtenida del caché
✅ Orden cargada del servidor
❌ Error en loadOrderDetail: Connection refused
```

3. **Forzar recarga:**
```dart
// En botón o menú:
ref.refresh(orderDetailProvider(widget.orderId));
```

---

## 🎯 Resumen Rápido

| Cambio | Antes | Después | Beneficio |
|--------|-------|---------|-----------|
| Clase base | `StatefulWidget` | `ConsumerStatefulWidget` | Riverpod integrado |
| Estado | Variables locales | `ref.watch()` | Reactive |
| Carga | Manual en initState | Automático en build | Más simple |
| Caché | Ninguno | TTL 15min | 85% más rápido |
| Actualización | setState() | Automático | Menos código |

---

**Tiempo estimado de integración por página:** 30 minutos  
**Páginas a actualizar:** 3 (Orders, Products, Customers)  
**Tiempo total:** 1.5 horas
