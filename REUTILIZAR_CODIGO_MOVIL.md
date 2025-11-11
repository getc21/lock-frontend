# 🔄 Guía para Reutilizar Código de la App Móvil

Esta guía explica cómo **copiar y adaptar** el código ya funcional de la app móvil `bellezapp` al dashboard web `bellezapp-frontend`.

## 📦 Estrategia de Reutilización

La app móvil ya tiene **TODA la lógica implementada**:
- ✅ Controllers (GetX) con toda la lógica de negocio
- ✅ Models con serialización JSON
- ✅ Database Helper (SQLite)
- ✅ Servicios de gestión (PDF, Excel, backup)
- ✅ Validaciones y reglas de negocio
- ✅ Formularios completos

**NO necesitas crear backend** - Puedes usar la misma base de datos SQLite o migrar a un backend real más adelante.

---

## 🗂️ Paso 1: Copiar Modelos

### Desde: `bellezapp/lib/models/`
### Hacia: `bellezapp-frontend/lib/shared/models/`

**Modelos a copiar:**
```bash
# Copiar estos archivos tal cual
bellezapp/lib/models/product.dart          → bellezapp-frontend/lib/shared/models/product.dart
bellezapp/lib/models/order.dart            → bellezapp-frontend/lib/shared/models/order.dart
bellezapp/lib/models/customer.dart         → bellezapp-frontend/lib/shared/models/customer.dart
bellezapp/lib/models/discount.dart         → bellezapp-frontend/lib/shared/models/discount.dart
bellezapp/lib/models/user.dart             → bellezapp-frontend/lib/shared/models/user.dart
bellezapp/lib/models/store.dart            → bellezapp-frontend/lib/shared/models/store.dart
bellezapp/lib/models/order_product.dart    → bellezapp-frontend/lib/shared/models/order_product.dart
bellezapp/lib/models/category.dart         → bellezapp-frontend/lib/shared/models/category.dart
```

**Sin modificaciones necesarias** - Los modelos ya tienen:
- `fromJson()` y `toJson()` para API
- `fromMap()` y `toMap()` para SQLite
- Validaciones
- Campos calculados

---

## 🎮 Paso 2: Copiar Controllers

### Desde: `bellezapp/lib/controllers/`
### Hacia: `bellezapp-frontend/lib/shared/controllers/`

**Controllers a copiar:**
```bash
bellezapp/lib/controllers/product_controller.dart    → bellezapp-frontend/lib/shared/controllers/product_controller.dart
bellezapp/lib/controllers/order_controller.dart      → bellezapp-frontend/lib/shared/controllers/order_controller.dart
bellezapp/lib/controllers/customer_controller.dart   → bellezapp-frontend/lib/shared/controllers/customer_controller.dart
bellezapp/lib/controllers/discount_controller.dart   → bellezapp-frontend/lib/shared/controllers/discount_controller.dart
bellezapp/lib/controllers/user_controller.dart       → bellezapp-frontend/lib/shared/controllers/user_controller.dart
bellezapp/lib/controllers/store_controller.dart      → bellezapp-frontend/lib/shared/controllers/store_controller.dart
```

### Modificaciones Menores

Los controllers ya usan **GetX** y están listos, solo necesitas:

1. **Actualizar imports** de rutas:
```dart
// Cambiar:
import '../models/product.dart';
// Por:
import '../models/product.dart'; // Ya está bien si copias a shared/
```

2. **Opcional - Cambiar navegación móvil por web:**
```dart
// Cambiar:
Get.to(() => ProductDetailPage());
// Por:
Get.toNamed('/products/detail');
```

---

## 💾 Paso 3: Copiar Database Helper

### Desde: `bellezapp/lib/database/`
### Hacia: `bellezapp-frontend/lib/shared/database/`

**Archivos a copiar:**
```bash
bellezapp/lib/database/database_helper.dart → bellezapp-frontend/lib/shared/database/database_helper.dart
```

### ⚠️ Consideración Importante

**SQLite funciona en Flutter Web**, pero la base de datos se guarda en:
- **IndexedDB** del navegador (no es un archivo `.db`)
- Los datos son por navegador/usuario
- Se pierden si el usuario borra caché del navegador

**Alternativa para Producción:**
- Usar backend con PostgreSQL/MySQL
- Convertir `database_helper.dart` a servicios HTTP
- Los datos estarán centralizados

**Para Desarrollo/Demo:**
- Puedes usar SQLite web
- Agregar al `pubspec.yaml`:
```yaml
dependencies:
  sqflite_common_ffi_web: ^0.4.3  # SQLite para web
```

---

## 📄 Paso 4: Copiar Servicios Útiles

### Desde: `bellezapp/lib/services/`
### Hacia: `bellezapp-frontend/lib/shared/services/`

**Servicios a copiar:**

```bash
# Servicio de PDF (si usas printing)
bellezapp/lib/services/pdf_service.dart → bellezapp-frontend/lib/shared/services/pdf_service.dart

# Servicio de Excel (si usas excel)
bellezapp/lib/services/excel_service.dart → bellezapp-frontend/lib/shared/services/excel_service.dart

# Servicio de backup
bellezapp/lib/services/backup_service.dart → bellezapp-frontend/lib/shared/services/backup_service.dart
```

**Estos servicios YA tienen implementado:**
- ✅ Generación de PDFs (facturas, reportes)
- ✅ Exportación a Excel
- ✅ Backup de base de datos
- ✅ Restauración de datos

---

## 🎨 Paso 5: Adaptar Widgets/Formularios

### Opción A: Usar Widgets Móviles (Rápido)

Puedes copiar los widgets/formularios de la app móvil y funcionarán en web:

```bash
bellezapp/lib/widgets/product_form.dart → bellezapp-frontend/lib/shared/widgets/product_form.dart
bellezapp/lib/widgets/order_form.dart → bellezapp-frontend/lib/shared/widgets/order_form.dart
bellezapp/lib/widgets/customer_form.dart → bellezapp-frontend/lib/shared/widgets/customer_form.dart
```

**Ajuste necesario:**
```dart
// En lugar de showModalBottomSheet (móvil):
showModalBottomSheet(context: context, builder: (context) => FormWidget());

// Usar showDialog (web):
showDialog(
  context: context,
  builder: (context) => Dialog(
    child: Container(
      width: 600,  // Ancho fijo para web
      padding: EdgeInsets.all(24),
      child: FormWidget(),
    ),
  ),
);
```

### Opción B: Diseño Web Nativo (Óptimo)

Crear formularios optimizados para web basándote en la lógica móvil:
- Usar campos más anchos
- Layout horizontal en lugar de vertical
- Múltiples columnas
- Validaciones iguales pero UI diferente

---

## 🔌 Paso 6: Inicializar en main.dart

Agregar los controllers al inicio de la app web:

```dart
// bellezapp-frontend/lib/main.dart

import 'package:get/get.dart';
import 'shared/controllers/product_controller.dart';
import 'shared/controllers/order_controller.dart';
import 'shared/controllers/customer_controller.dart';
import 'shared/controllers/discount_controller.dart';
import 'shared/controllers/user_controller.dart';
import 'shared/controllers/store_controller.dart';
import 'shared/database/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Database
  await DatabaseHelper.instance.database;
  
  // Inicializar Controllers
  Get.put(ProductController());
  Get.put(OrderController());
  Get.put(CustomerController());
  Get.put(DiscountController());
  Get.put(UserController());
  Get.put(StoreController());
  
  runApp(const BellezAppWeb());
}
```

---

## 📊 Paso 7: Conectar Dashboard con Datos Reales

Reemplazar los datos hardcodeados por datos del controller:

### Ejemplo: products_page.dart

**ANTES (datos hardcoded):**
```dart
final products = [
  {'code': 'PROD-001', 'name': 'Shampoo Keratina Pro', ...},
  {'code': 'PROD-002', 'name': 'Tinte Castaño Natural', ...},
];
```

**DESPUÉS (datos reales del controller):**
```dart
class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final productController = Get.find<ProductController>();
    
    return DashboardLayout(
      title: 'Productos',
      currentRoute: '/products',
      child: Obx(() => Column(
        children: [
          // ... header
          
          // Tabla con datos reales
          Expanded(
            child: Card(
              child: DataTable2(
                columns: [...],
                rows: productController.products.map((product) {
                  return DataRow2(
                    cells: [
                      DataCell(Text(product.code)),
                      DataCell(Text(product.name)),
                      DataCell(Text(product.category)),
                      DataCell(Text('${product.stock}')),
                      DataCell(Text('\$${product.price.toStringAsFixed(2)}')),
                      // ... más cells
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      )),
    );
  }
}
```

---

## 🔄 Paso 8: Implementar Formularios con Lógica Existente

### Ejemplo: Agregar Producto

```dart
// En products_page.dart

void _showAddProductDialog() {
  final productController = Get.find<ProductController>();
  final formKey = GlobalKey<FormState>();
  
  final nameController = TextEditingController();
  final codeController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Nuevo Producto'),
      content: SizedBox(
        width: 500,
        child: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: codeController,
                decoration: const InputDecoration(labelText: 'Código'),
                validator: (value) => value?.isEmpty ?? true 
                    ? 'Campo requerido' 
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre'),
                validator: (value) => value?.isEmpty ?? true 
                    ? 'Campo requerido' 
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                decoration: const InputDecoration(labelText: 'Precio'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Campo requerido';
                  if (double.tryParse(value!) == null) return 'Precio inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: stockController,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) return 'Campo requerido';
                  if (int.tryParse(value!) == null) return 'Stock inválido';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              final product = Product(
                code: codeController.text,
                name: nameController.text,
                price: double.parse(priceController.text),
                stock: int.parse(stockController.text),
                category: 'General', // O agregar selector
                isActive: true,
              );
              
              // Usar método del controller que YA EXISTE
              await productController.addProduct(product);
              
              Navigator.pop(context);
              
              Get.snackbar(
                'Éxito',
                'Producto agregado correctamente',
                snackPosition: SnackPosition.BOTTOM,
              );
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    ),
  );
}
```

---

## 📥 Paso 9: Implementar Exportación (Ya Existe!)

Si copiaste los servicios de PDF y Excel, solo necesitas llamarlos:

```dart
// En reports_page.dart

void _exportToPDF() async {
  final pdfService = Get.find<PDFService>(); // Si lo pusiste en Get
  // O instanciar: final pdfService = PDFService();
  
  final orders = Get.find<OrderController>().orders;
  final customers = Get.find<CustomerController>().customers;
  
  await pdfService.generateSalesReport(
    orders: orders,
    customers: customers,
    period: _selectedPeriod,
  );
  
  Get.snackbar(
    'Éxito',
    'Reporte PDF generado',
    snackPosition: SnackPosition.BOTTOM,
  );
}

void _exportToExcel() async {
  final excelService = Get.find<ExcelService>();
  
  final products = Get.find<ProductController>().products;
  
  await excelService.exportProducts(products);
  
  Get.snackbar(
    'Éxito',
    'Reporte Excel generado',
    snackPosition: SnackPosition.BOTTOM,
  );
}
```

---

## ✅ Checklist de Migración

### Archivos Base
- [ ] Copiar todos los modelos de `bellezapp/lib/models/` a `lib/shared/models/`
- [ ] Copiar todos los controllers de `bellezapp/lib/controllers/` a `lib/shared/controllers/`
- [ ] Copiar `database_helper.dart` a `lib/shared/database/`

### Servicios Opcionales
- [ ] Copiar `pdf_service.dart` (si existe)
- [ ] Copiar `excel_service.dart` (si existe)
- [ ] Copiar `backup_service.dart` (si existe)

### Widgets Reutilizables
- [ ] Copiar formularios de la app móvil
- [ ] Adaptar `showModalBottomSheet` a `showDialog`
- [ ] Ajustar tamaños para web (width: 500-600)

### Integración
- [ ] Inicializar controllers en `main.dart`
- [ ] Inicializar DatabaseHelper
- [ ] Reemplazar datos hardcoded por `Obx(() => controller.data)`
- [ ] Conectar botones "Nuevo" con formularios reales
- [ ] Conectar botones "Editar" con formularios existentes
- [ ] Conectar botones "Eliminar" con `controller.delete()`

### Testing
- [ ] Probar agregar producto
- [ ] Probar editar producto
- [ ] Probar eliminar producto
- [ ] Probar crear orden
- [ ] Probar buscar cliente
- [ ] Probar exportar PDF
- [ ] Probar exportar Excel

---

## 🎯 Resultado Final

Una vez completada la migración, tendrás:

✅ **Dashboard web con datos reales de SQLite**
✅ **CRUD completo funcionando (copiar/pegar de móvil)**
✅ **Misma lógica de negocio en web y móvil**
✅ **Exportación PDF/Excel funcionando**
✅ **Validaciones y reglas de negocio idénticas**
✅ **Sin necesidad de backend (por ahora)**

---

## 💡 Ventajas de esta Estrategia

1. **Reutilización de código**: No duplicas lógica
2. **Misma base de datos**: Web y móvil comparten datos (si están en la misma máquina)
3. **Mantenimiento simple**: Un cambio en controller aplica a ambos
4. **Migración gradual**: Puedes mover a backend después sin reescribir UI

---

## 🚀 Siguiente Nivel: Migrar a Backend Real

Cuando estés listo para un backend centralizado:

1. Mantén los controllers (GetX)
2. Reemplaza llamadas a `DatabaseHelper` por llamadas HTTP
3. Los modelos ya tienen `toJson()` y `fromJson()` listos
4. La UI no cambia, solo cambia la fuente de datos

**Ejemplo:**
```dart
// ANTES (SQLite):
await DatabaseHelper.instance.insertProduct(product.toMap());

// DESPUÉS (Backend):
await http.post('$baseUrl/products', body: product.toJson());
```

---

**En resumen:** ¡Ya tienes TODO hecho! Solo copia y conecta. 🎉
