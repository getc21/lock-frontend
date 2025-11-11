# 🔌 Guía de Integración con Backend

Esta guía explica cómo conectar el dashboard web de BellezApp con tu backend (Node.js o Spring Boot).

## 📁 Estructura de Servicios Recomendada

Crear los siguientes archivos en `lib/shared/services/`:

```
lib/shared/services/
├── api_service.dart          # Configuración base de HTTP
├── auth_service.dart         # Autenticación (login, logout)
├── product_service.dart      # CRUD de productos
├── order_service.dart        # CRUD de órdenes
├── customer_service.dart     # CRUD de clientes
├── report_service.dart       # Datos de reportes
└── storage_service.dart      # SharedPreferences para token
```

## 🔐 1. Servicio de Autenticación

### `lib/shared/services/auth_service.dart`

```dart
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'storage_service.dart';

class AuthService extends GetxController {
  static const String baseUrl = 'https://api.bellezapp.com'; // Cambiar por tu URL
  
  final storageService = Get.find<StorageService>();
  final isAuthenticated = false.obs;
  final currentUser = Rxn<User>();

  Future<bool> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];
        final user = User.fromJson(data['user']);
        
        // Guardar token
        await storageService.saveToken(token);
        
        // Actualizar estado
        isAuthenticated.value = true;
        currentUser.value = user;
        
        return true;
      }
      return false;
    } catch (e) {
      print('Error en login: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await storageService.removeToken();
    isAuthenticated.value = false;
    currentUser.value = null;
    Get.offAllNamed('/login');
  }

  String? getToken() {
    return storageService.getToken();
  }
}
```

### Actualizar `login_page.dart`

```dart
Future<void> _handleLogin() async {
  if (_formKey.currentState!.validate()) {
    setState(() => _isLoading = true);
    
    final authService = Get.find<AuthService>();
    final success = await authService.login(
      _emailController.text,
      _passwordController.text,
    );
    
    setState(() => _isLoading = false);
    
    if (success) {
      Get.offAllNamed('/dashboard');
    } else {
      Get.snackbar(
        'Error',
        'Credenciales incorrectas',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
```

## 📦 2. Servicio de Productos

### `lib/shared/services/product_service.dart`

```dart
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/product.dart';
import 'auth_service.dart';

class ProductService extends GetxController {
  static const String baseUrl = 'https://api.bellezapp.com';
  
  final authService = Get.find<AuthService>();

  Map<String, String> _getHeaders() {
    final token = authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Product>> getProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: _getHeaders(),
      );

      if (response.statusCode == 200) {
        final List data = json.decode(response.body);
        return data.map((json) => Product.fromJson(json)).toList();
      }
      throw Exception('Error al cargar productos');
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }

  Future<Product> createProduct(Product product) async {
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: _getHeaders(),
      body: json.encode(product.toJson()),
    );

    if (response.statusCode == 201) {
      return Product.fromJson(json.decode(response.body));
    }
    throw Exception('Error al crear producto');
  }

  Future<Product> updateProduct(int id, Product product) async {
    final response = await http.put(
      Uri.parse('$baseUrl/products/$id'),
      headers: _getHeaders(),
      body: json.encode(product.toJson()),
    );

    if (response.statusCode == 200) {
      return Product.fromJson(json.decode(response.body));
    }
    throw Exception('Error al actualizar producto');
  }

  Future<void> deleteProduct(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/products/$id'),
      headers: _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Error al eliminar producto');
    }
  }
}
```

## 🧾 3. Servicio de Órdenes

### `lib/shared/services/order_service.dart`

```dart
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/order.dart';
import 'auth_service.dart';

class OrderService extends GetxController {
  static const String baseUrl = 'https://api.bellezapp.com';
  
  final authService = Get.find<AuthService>();

  Map<String, String> _getHeaders() {
    final token = authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Order>> getOrders({String? status}) async {
    var url = '$baseUrl/orders';
    if (status != null && status != 'Todos') {
      url += '?status=$status';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Order.fromJson(json)).toList();
    }
    throw Exception('Error al cargar órdenes');
  }

  Future<Order> createOrder(Order order) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: _getHeaders(),
      body: json.encode(order.toJson()),
    );

    if (response.statusCode == 201) {
      return Order.fromJson(json.decode(response.body));
    }
    throw Exception('Error al crear orden');
  }

  Future<Order> updateOrderStatus(int id, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$id/status'),
      headers: _getHeaders(),
      body: json.encode({'status': status}),
    );

    if (response.statusCode == 200) {
      return Order.fromJson(json.decode(response.body));
    }
    throw Exception('Error al actualizar orden');
  }
}
```

## 👥 4. Servicio de Clientes

### `lib/shared/services/customer_service.dart`

```dart
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/customer.dart';
import 'auth_service.dart';

class CustomerService extends GetxController {
  static const String baseUrl = 'https://api.bellezapp.com';
  
  final authService = Get.find<AuthService>();

  Map<String, String> _getHeaders() {
    final token = authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Customer>> getCustomers({String? search}) async {
    var url = '$baseUrl/customers';
    if (search != null && search.isNotEmpty) {
      url += '?search=$search';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((json) => Customer.fromJson(json)).toList();
    }
    throw Exception('Error al cargar clientes');
  }

  Future<Customer> createCustomer(Customer customer) async {
    final response = await http.post(
      Uri.parse('$baseUrl/customers'),
      headers: _getHeaders(),
      body: json.encode(customer.toJson()),
    );

    if (response.statusCode == 201) {
      return Customer.fromJson(json.decode(response.body));
    }
    throw Exception('Error al crear cliente');
  }

  Future<Customer> updateCustomer(int id, Customer customer) async {
    final response = await http.put(
      Uri.parse('$baseUrl/customers/$id'),
      headers: _getHeaders(),
      body: json.encode(customer.toJson()),
    );

    if (response.statusCode == 200) {
      return Customer.fromJson(json.decode(response.body));
    }
    throw Exception('Error al actualizar cliente');
  }
}
```

## 📊 5. Servicio de Reportes

### `lib/shared/services/report_service.dart`

```dart
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'auth_service.dart';

class ReportService extends GetxController {
  static const String baseUrl = 'https://api.bellezapp.com';
  
  final authService = Get.find<AuthService>();

  Map<String, String> _getHeaders() {
    final token = authService.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> getDashboardData() async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/dashboard'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Error al cargar dashboard');
  }

  Future<List<Map<String, dynamic>>> getSalesChart(String period) async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/sales?period=$period'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    }
    throw Exception('Error al cargar gráfico de ventas');
  }

  Future<Map<String, dynamic>> getTopProducts() async {
    final response = await http.get(
      Uri.parse('$baseUrl/reports/top-products'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    }
    throw Exception('Error al cargar top productos');
  }
}
```

## 💾 6. Storage Service

### `lib/shared/services/storage_service.dart`

```dart
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService extends GetxController {
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<void> saveToken(String token) async {
    await _prefs.setString('auth_token', token);
  }

  String? getToken() {
    return _prefs.getString('auth_token');
  }

  Future<void> removeToken() async {
    await _prefs.remove('auth_token');
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    await _prefs.setString('user_data', json.encode(user));
  }

  Map<String, dynamic>? getUser() {
    final userData = _prefs.getString('user_data');
    if (userData != null) {
      return json.decode(userData);
    }
    return null;
  }
}
```

## 🔄 7. Inicialización en main.dart

Agregar al `main.dart`:

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar Storage
  final storageService = StorageService();
  await storageService.init();
  Get.put(storageService);
  
  // Inicializar servicios
  Get.put(AuthService());
  Get.put(ProductService());
  Get.put(OrderService());
  Get.put(CustomerService());
  Get.put(ReportService());
  
  runApp(const BellezAppWeb());
}
```

## 📝 8. Modelos de Datos

Crear modelos en `lib/shared/models/`:

### `product.dart`
```dart
class Product {
  final int? id;
  final String code;
  final String name;
  final String category;
  final int stock;
  final double price;
  final bool isActive;

  Product({
    this.id,
    required this.code,
    required this.name,
    required this.category,
    required this.stock,
    required this.price,
    required this.isActive,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      code: json['code'],
      name: json['name'],
      category: json['category'],
      stock: json['stock'],
      price: json['price'].toDouble(),
      isActive: json['is_active'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'category': category,
      'stock': stock,
      'price': price,
      'is_active': isActive,
    };
  }
}
```

## 🌐 9. Configuración de CORS (Backend)

### Node.js + Express
```javascript
const cors = require('cors');

app.use(cors({
  origin: 'http://localhost:*', // Para desarrollo
  credentials: true
}));
```

### Spring Boot
```java
@Configuration
public class CorsConfig {
    @Bean
    public WebMvcConfigurer corsConfigurer() {
        return new WebMvcConfigurer() {
            @Override
            public void addCorsMappings(CorsRegistry registry) {
                registry.addMapping("/**")
                        .allowedOrigins("http://localhost:*")
                        .allowedMethods("GET", "POST", "PUT", "DELETE")
                        .allowCredentials(true);
            }
        };
    }
}
```

## 🔒 10. Middleware de Autenticación

### En GetX (opcional)
```dart
class AuthMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final authService = Get.find<AuthService>();
    if (!authService.isAuthenticated.value) {
      return const RouteSettings(name: '/login');
    }
    return null;
  }
}

// En main.dart, agregar a las rutas protegidas:
GetPage(
  name: '/dashboard',
  page: () => const DashboardPage(),
  middlewares: [AuthMiddleware()],
),
```

## 📡 11. Manejo de Errores

```dart
class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

// Uso en servicios:
try {
  final response = await http.get(...);
  if (response.statusCode != 200) {
    throw ApiException(
      'Error del servidor',
      response.statusCode,
    );
  }
} on SocketException {
  throw ApiException('Sin conexión a internet');
} on TimeoutException {
  throw ApiException('Tiempo de espera agotado');
} catch (e) {
  throw ApiException('Error inesperado: $e');
}
```

## ✅ Checklist de Integración

- [ ] Configurar URL base del API en cada servicio
- [ ] Implementar AuthService y login real
- [ ] Crear modelos de datos (Product, Order, Customer, etc.)
- [ ] Implementar ProductService con CRUD completo
- [ ] Implementar OrderService con CRUD completo
- [ ] Implementar CustomerService con CRUD completo
- [ ] Implementar ReportService para dashboard
- [ ] Configurar CORS en backend
- [ ] Probar endpoints con Postman antes de integrar
- [ ] Implementar manejo de errores
- [ ] Agregar loading states en UI
- [ ] Implementar refresh de datos
- [ ] Probar flujo completo de autenticación
- [ ] Validar tokens expirados

---

Una vez completada esta integración, tu dashboard tendrá datos reales del backend y CRUD completo funcional.
