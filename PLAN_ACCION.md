# ⚡ PLAN DE ACCIÓN: Reutilizar Código de App Móvil

## 🎯 Objetivo

Llevar el dashboard web de **datos demo** a **datos reales y CRUD completo** en **2-4 horas**, reutilizando TODO el código ya implementado en la app móvil `bellezapp`.

---

## ✅ Lo que YA TIENES

### En `bellezapp` (App Móvil)
- ✅ **Controllers completos** con GetX:
  - `ProductController` - CRUD productos
  - `OrderController` - CRUD órdenes  
  - `CustomerController` - CRUD clientes
  - `DiscountController` - Gestión de descuentos
  - `UserController` - Autenticación
  - `StoreController` - Tiendas

- ✅ **Models con serialización**:
  - `Product`, `Order`, `Customer`, `Discount`, `User`, `Store`
  - Métodos `toMap()`, `fromMap()`, `toJson()`, `fromJson()`

- ✅ **Database Helper**:
  - SQLite completamente funcional
  - Métodos CRUD para todas las entidades
  - Migraciones y validaciones

- ✅ **Servicios**:
  - PDF Service (facturas, reportes)
  - Excel Service (exportación)
  - Backup Service

- ✅ **Formularios**:
  - Formulario de productos
  - Formulario de órdenes
  - Formulario de clientes
  - Con validaciones completas

### En `bellezapp-frontend` (Dashboard Web)
- ✅ **UI completa** con datos demo
- ✅ **Layout profesional** con sidebar
- ✅ **Páginas** listas para conectar datos
- ✅ **Gráficos y tablas** funcionando
- ✅ **Routing con GetX**

---

## 🚀 PASO A PASO RÁPIDO

### 🔥 Opción 1: Automatizada (Recomendado)

```powershell
# Desde bellezapp-frontend/
.\copiar_codigo_movil.ps1
```

Este script copia automáticamente:
- ✅ Todos los modelos
- ✅ Todos los controllers
- ✅ Database helper
- ✅ Servicios (si existen)

### 🔧 Opción 2: Manual

Copiar estos directorios:

```
bellezapp/lib/models/          → bellezapp-frontend/lib/shared/models/
bellezapp/lib/controllers/     → bellezapp-frontend/lib/shared/controllers/
bellezapp/lib/database/        → bellezapp-frontend/lib/shared/database/
bellezapp/lib/services/        → bellezapp-frontend/lib/shared/services/
```

---

## 📝 Checklist de Integración

### 1️⃣ Copiar Archivos (5 minutos)
- [ ] Ejecutar `copiar_codigo_movil.ps1` O copiar manualmente
- [ ] Verificar que todos los archivos se copiaron
- [ ] Revisar imports rotos (actualizar rutas si es necesario)

### 2️⃣ Actualizar main.dart (10 minutos)

**Archivo:** `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

// Imports agregados
import 'shared/controllers/product_controller.dart';
import 'shared/controllers/order_controller.dart';
import 'shared/controllers/customer_controller.dart';
import 'shared/controllers/discount_controller.dart';
import 'shared/controllers/user_controller.dart';
import 'shared/controllers/store_controller.dart';
import 'shared/database/database_helper.dart';

// ... otros imports

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🔥 AGREGAR ESTO
  // Inicializar base de datos
  await DatabaseHelper.instance.database;
  
  // Inicializar controllers
  Get.put(ProductController());
  Get.put(OrderController());
  Get.put(CustomerController());
  Get.put(DiscountController());
  Get.put(UserController());
  Get.put(StoreController());
  
  runApp(const BellezAppWeb());
}
```

### 3️⃣ Conectar Products Page (30 minutos)

**Archivo:** `lib/features/products/products_page.dart`

**REEMPLAZAR** la sección de datos hardcoded:

```dart
// ❌ BORRAR ESTO:
final products = [
  {'code': 'PROD-001', 'name': 'Shampoo...', ...},
];

// ✅ AGREGAR ESTO:
class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final productController = Get.find<ProductController>();
    
    // Cargar productos al iniciar
    productController.loadProducts();
    
    return DashboardLayout(
      title: 'Productos',
      currentRoute: '/products',
      child: Column(
        children: [
          // ... header con búsqueda ...
          
          // 🔥 TABLA CON DATOS REALES
          Expanded(
            child: Obx(() {
              // Filtrar productos según búsqueda
              final filteredProducts = productController.products
                  .where((p) => _searchQuery.isEmpty ||
                                p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
                  .toList();
              
              return Card(
                child: DataTable2(
                  columns: [...],
                  rows: filteredProducts.map((product) {
                    return DataRow2(
                      cells: [
                        DataCell(Text(product.code)),
                        DataCell(Text(product.name)),
                        DataCell(Text(product.category)),
                        DataCell(Text('${product.stock}')),
                        DataCell(Text('\$${product.price.toStringAsFixed(2)}')),
                        DataCell(_buildStatusChip(product.isActive)),
                        DataCell(_buildActions(product)),
                      ],
                    );
                  }).toList(),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
```

**AGREGAR** método para nuevo producto:

```dart
void _showAddProductDialog(BuildContext context) {
  final productController = Get.find<ProductController>();
  // ... crear formulario (copiar de app móvil o adaptar)
  
  // Al guardar:
  await productController.addProduct(newProduct);
  Get.back();
  Get.snackbar('Éxito', 'Producto agregado');
}
```

### 4️⃣ Conectar Orders Page (30 minutos)

**Similar a products, pero con OrderController**

```dart
final orderController = Get.find<OrderController>();
orderController.loadOrders();

// En el body:
Obx(() {
  final filteredOrders = orderController.orders
      .where((o) => _statusFilter == 'Todos' || o.status == _statusFilter)
      .toList();
  
  return DataTable2(...);
})
```

### 5️⃣ Conectar Customers Page (30 minutos)

```dart
final customerController = Get.find<CustomerController>();
customerController.loadCustomers();

Obx(() {
  final filteredCustomers = customerController.customers
      .where((c) => c.name.contains(_searchQuery))
      .toList();
  
  return DataTable2(...);
})
```

### 6️⃣ Conectar Dashboard Page (30 minutos)

```dart
final orderController = Get.find<OrderController>();
final productController = Get.find<ProductController>();
final customerController = Get.find<CustomerController>();

// Calcular KPIs reales:
Obx(() {
  final totalSales = orderController.orders
      .fold<double>(0, (sum, order) => sum + order.total);
  
  final totalOrders = orderController.orders.length;
  
  final totalCustomers = customerController.customers.length;
  
  final totalProducts = productController.products.length;
  
  return Column(
    children: [
      _buildKPICard('Ventas Hoy', '\$$totalSales', ...),
      _buildKPICard('Órdenes', '$totalOrders', ...),
      // ...
    ],
  );
})
```

### 7️⃣ Conectar Reports Page (30 minutos)

```dart
// Usar datos reales para gráficos:
final orders = Get.find<OrderController>().orders;

// Agrupar por mes
final salesByMonth = _groupOrdersByMonth(orders);

// Gráfico con datos reales
BarChart(
  BarChartData(
    barGroups: salesByMonth.entries.map((entry) {
      return _buildBarGroup(entry.key, entry.value);
    }).toList(),
  ),
)
```

### 8️⃣ Adaptar Formularios Móviles (1 hora)

Copiar formularios de app móvil y adaptarlos:

**Diferencias:**
- `showModalBottomSheet` → `showDialog`
- Agregar `width: 600` al Dialog
- Mantener misma lógica de validación

**Ejemplo:**

```dart
// MÓVIL:
showModalBottomSheet(
  context: context,
  builder: (context) => ProductFormWidget(),
);

// WEB:
showDialog(
  context: context,
  builder: (context) => Dialog(
    child: Container(
      width: 600,
      padding: EdgeInsets.all(24),
      child: ProductFormWidget(), // Mismo widget!
    ),
  ),
);
```

---

## ⏱️ Tiempo Estimado Total

| Tarea | Tiempo |
|-------|--------|
| Copiar archivos | 5 min |
| Actualizar main.dart | 10 min |
| Conectar Products Page | 30 min |
| Conectar Orders Page | 30 min |
| Conectar Customers Page | 30 min |
| Conectar Dashboard | 30 min |
| Conectar Reports | 30 min |
| Adaptar formularios | 60 min |
| **TOTAL** | **⏱️ 3-4 horas** |

---

## 🎯 Resultado Final

Después de completar estos pasos tendrás:

✅ **Dashboard web completamente funcional**
✅ **CRUD real de productos, órdenes y clientes**
✅ **Base de datos SQLite funcionando**
✅ **Gráficos con datos reales**
✅ **Formularios con validaciones**
✅ **Exportación PDF/Excel (si copiaste servicios)**
✅ **Misma lógica de negocio en móvil y web**

---

## 🐛 Troubleshooting

### Error: "Can't find controller"
```dart
// Asegúrate de inicializar en main.dart:
Get.put(ProductController());
```

### Error: "Database not initialized"
```dart
// Debe estar ANTES de runApp():
await DatabaseHelper.instance.database;
```

### Error: Import no encontrado
```dart
// Actualizar rutas de imports:
import '../models/product.dart';
// a:
import '../../shared/models/product.dart';
```

### SQLite no funciona en Web
```yaml
# Agregar al pubspec.yaml:
dependencies:
  sqflite_common_ffi_web: ^0.4.3
```

---

## 📚 Referencias

- **Guía completa:** `REUTILIZAR_CODIGO_MOVIL.md`
- **Script de copia:** `copiar_codigo_movil.ps1`
- **Integración backend (futuro):** `INTEGRACION_BACKEND.md`

---

## 🚀 ¡Empieza Ahora!

```powershell
# Paso 1: Copiar código
.\copiar_codigo_movil.ps1

# Paso 2: Actualizar main.dart
code .\lib\main.dart

# Paso 3: Conectar páginas una por una
# Empezar por products_page.dart
```

**¡En 3-4 horas tendrás todo funcionando!** 🎉
