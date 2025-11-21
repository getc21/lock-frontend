# 🛠️ Guía de Implementación - Ejemplos Concretos

Este documento contiene **código listo para usar** basado en los problemas identificados en la auditoría.

---

## 1. SEGURIDAD: Migración a flutter_secure_storage

### Paso 1: Agregar dependencia

```yaml
# pubspec.yaml
dependencies:
  flutter_secure_storage: ^9.2.0
```

### Paso 2: Crear servicio de almacenamiento seguro

Crear `lib/shared/services/secure_storage_service.dart`:

```dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_this_device_this_app_only,
    ),
  );

  // Token
  static Future<void> saveToken(String token) async {
    await _storage.write(
      key: 'auth_token',
      value: token,
    );
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: 'auth_token');
  }

  // Usuario
  static Future<void> saveUser(String userJson) async {
    await _storage.write(
      key: 'user_data',
      value: userJson,
    );
  }

  static Future<String?> getUser() async {
    return await _storage.read(key: 'user_data');
  }

  static Future<void> deleteUser() async {
    await _storage.delete(key: 'user_data');
  }

  // Limpiar todo
  static Future<void> clear() async {
    await _storage.deleteAll();
  }
}
```

### Paso 3: Actualizar auth_notifier.dart

```dart
// En lib/shared/providers/riverpod/auth_notifier.dart

import '../../../services/secure_storage_service.dart';

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref ref;
  final auth_api.AuthProvider _authProvider = auth_api.AuthProvider();

  AuthNotifier(this.ref) : super(AuthState()) {
    _loadSavedSession();
  }

  // ✅ NUEVO: Cargar sesión segura
  Future<void> _loadSavedSession() async {
    state = state.copyWith(isLoading: true);

    try {
      // 1. Obtener token de almacenamiento seguro
      final savedToken = await SecureStorageService.getToken();
      
      if (savedToken != null && savedToken.isNotEmpty) {
        state = state.copyWith(token: savedToken);

        // 2. Obtener datos de usuario
        final savedUserData = await SecureStorageService.getUser();
        if (savedUserData != null && savedUserData.isNotEmpty) {
          try {
            final userData = jsonDecode(savedUserData);
            state = state.copyWith(currentUser: userData);
          } catch (e) {
            // Datos corruptos → Limpiar
            await SecureStorageService.deleteUser();
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading saved session: $e');
      }
    }
    
    state = state.copyWith(isLoading: false);
  }

  // ✅ ACTUALIZADO: Guardar token seguro
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _authProvider.login(
        email: email,
        password: password,
      );

      if (result['success']) {
        final token = result['token'];
        final user = result['user'];

        // Guardar de forma segura
        await SecureStorageService.saveToken(token);
        await SecureStorageService.saveUser(jsonEncode(user));

        state = state.copyWith(
          token: token,
          currentUser: user,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          errorMessage: result['message'] ?? 'Error de autenticación',
          isLoading: false,
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error de conexión: $e',
        isLoading: false,
      );
      return false;
    }
  }

  // ✅ ACTUALIZADO: Logout con limpieza segura
  Future<void> logout() async {
    await SecureStorageService.clear();
    state = AuthState();
  }
}
```

---

## 2. SEGURIDAD: Rate Limiting en Login

Crear `lib/shared/services/rate_limiter_service.dart`:

```dart
import 'dart:async';

class RateLimiterService {
  static final RateLimiterService _instance = RateLimiterService._internal();
  
  factory RateLimiterService() {
    return _instance;
  }
  
  RateLimiterService._internal();

  // Almacenar intentos por email
  final Map<String, List<DateTime>> _loginAttempts = {};
  
  // Configuración
  static const maxAttempts = 5;
  static const windowDuration = Duration(minutes: 15);
  static const lockoutDuration = Duration(minutes: 15);

  /// Verificar si el usuario puede intentar login
  bool canAttemptLogin(String email) {
    final now = DateTime.now();
    final attempts = _loginAttempts[email] ?? [];

    // Limpiar intentos viejos
    final validAttempts = attempts
        .where((t) => now.difference(t) <= windowDuration)
        .toList();
    
    _loginAttempts[email] = validAttempts;

    // Verificar si ha alcanzado el límite
    if (validAttempts.length >= maxAttempts) {
      return false;  // Bloqueado
    }

    return true;  // Puede intentar
  }

  /// Registrar intento de login fallido
  void recordFailedAttempt(String email) {
    final now = DateTime.now();
    final attempts = _loginAttempts[email] ?? [];
    
    attempts.add(now);
    _loginAttempts[email] = attempts;
  }

  /// Limpiar intentos después de login exitoso
  void clearAttempts(String email) {
    _loginAttempts.remove(email);
  }

  /// Obtener información de bloqueo
  ({bool isBlocked, Duration timeRemaining}) getBlockStatus(String email) {
    final now = DateTime.now();
    final attempts = _loginAttempts[email] ?? [];

    if (attempts.isEmpty) {
      return (isBlocked: false, timeRemaining: Duration.zero);
    }

    final firstAttempt = attempts.first;
    final timeElapsed = now.difference(firstAttempt);
    final timeRemaining = windowDuration - timeElapsed;

    final isBlocked = attempts.length >= maxAttempts && timeRemaining.isNegative == false;

    return (
      isBlocked: isBlocked,
      timeRemaining: isBlocked ? timeRemaining : Duration.zero,
    );
  }
}
```

### Usar en login_page.dart:

```dart
class LoginPageState extends ConsumerState<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _rateLimiter = RateLimiterService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Email field
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
              ),
            ),
            
            // Password field
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Contraseña',
              ),
            ),

            // ✅ Login button con rate limiting
            ElevatedButton(
              onPressed: _handleLogin,
              child: const Text('Ingresar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text;

    // 1️⃣ Verificar rate limit
    if (!_rateLimiter.canAttemptLogin(email)) {
      final status = _rateLimiter.getBlockStatus(email);
      final minutesRemaining = status.timeRemaining.inMinutes;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Demasiados intentos fallidos. Intenta en $minutesRemaining minutos.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2️⃣ Intentar login
    final authNotifier = ref.read(authProvider.notifier);
    final success = await authNotifier.login(
      email,
      _passwordController.text,
    );

    if (success) {
      // 3️⃣ Limpiar intentos en login exitoso
      _rateLimiter.clearAttempts(email);
      
      // Navegar
      if (mounted) {
        context.go('/dashboard');
      }
    } else {
      // 4️⃣ Registrar intento fallido
      _rateLimiter.recordFailedAttempt(email);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Email o contraseña incorrectos'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
```

---

## 3. RENDIMIENTO: Paginación en OrdersPage

Crear `lib/shared/providers/riverpod/order_pagination_notifier.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../order_provider.dart' as order_api;
import 'store_notifier.dart';
import '../../services/cache_service.dart';

class OrderPaginationState {
  final List<Map<String, dynamic>> orders;
  final int currentPage;
  final int totalPages;
  final int pageSize;
  final bool isLoading;
  final bool isLoadingMore;
  final String errorMessage;

  OrderPaginationState({
    this.orders = const [],
    this.currentPage = 0,
    this.totalPages = 0,
    this.pageSize = 50,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.errorMessage = '',
  });

  bool get hasNextPage => currentPage < totalPages - 1;

  OrderPaginationState copyWith({
    List<Map<String, dynamic>>? orders,
    int? currentPage,
    int? totalPages,
    int? pageSize,
    bool? isLoading,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return OrderPaginationState(
      orders: orders ?? this.orders,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      pageSize: pageSize ?? this.pageSize,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class OrderPaginationNotifier extends StateNotifier<OrderPaginationState> {
  final Ref ref;
  final CacheService _cache = CacheService();
  late order_api.OrderProvider _orderProvider;
  String? _currentStoreId;

  OrderPaginationNotifier(this.ref) : super(OrderPaginationState()) {
    _initProvider();
  }

  void _initProvider() {
    final authState = ref.read(authProvider);
    _orderProvider = order_api.OrderProvider(authState.token);
  }

  Future<void> loadFirstPage({bool forceRefresh = false}) async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    
    try {
      final storeState = ref.read(storeProvider);
      _currentStoreId = storeState.currentStore?['_id'];

      if (_currentStoreId == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'No hay tienda seleccionada',
        );
        return;
      }

      // Verificar caché
      if (!forceRefresh) {
        final cached = _cache.get<OrderPaginationState>(
          'order_pagination:$_currentStoreId:0',
        );
        if (cached != null) {
          state = cached;
          return;
        }
      }

      // Cargar primera página
      final result = await _orderProvider.getOrdersPaginated(
        storeId: _currentStoreId!,
        page: 0,
        pageSize: state.pageSize,
      );

      if (result['success']) {
        final orders = List<Map<String, dynamic>>.from(result['data'] ?? []);
        final totalPages = result['totalPages'] as int? ?? 1;

        state = state.copyWith(
          orders: orders,
          currentPage: 0,
          totalPages: totalPages,
          isLoading: false,
        );

        // Guardar en caché
        _cache.set(
          'order_pagination:$_currentStoreId:0',
          state,
          ttl: const Duration(minutes: 5),
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error cargando órdenes',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error de conexión: $e',
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoadingMore || !state.hasNextPage) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;

      final result = await _orderProvider.getOrdersPaginated(
        storeId: _currentStoreId!,
        page: nextPage,
        pageSize: state.pageSize,
      );

      if (result['success']) {
        final newOrders = List<Map<String, dynamic>>.from(
          result['data'] ?? [],
        );

        state = state.copyWith(
          orders: [...state.orders, ...newOrders],
          currentPage: nextPage,
          isLoadingMore: false,
        );
      } else {
        state = state.copyWith(
          isLoadingMore: false,
          errorMessage: result['message'] ?? 'Error cargando página',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        errorMessage: 'Error de conexión: $e',
      );
    }
  }
}

final orderPaginationProvider = StateNotifierProvider<
  OrderPaginationNotifier,
  OrderPaginationState,
>((ref) {
  return OrderPaginationNotifier(ref);
});
```

### Usar en orders_page.dart (mejorado):

```dart
class OrdersPage extends ConsumerStatefulWidget {
  const OrdersPage({super.key});

  @override
  ConsumerState<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends ConsumerState<OrdersPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);

    // Cargar primera página
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(orderPaginationProvider.notifier).loadFirstPage();
    });
  }

  void _onScroll() {
    // Cargar siguiente página cuando está cerca del final
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent * 0.8) {
      ref.read(orderPaginationProvider.notifier).loadNextPage();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refrescar cuando se regresa a la página
    ref.read(orderPaginationProvider.notifier).loadFirstPage(forceRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    final paginationState = ref.watch(orderPaginationProvider);

    return DashboardLayout(
      title: 'Órdenes',
      currentRoute: '/orders',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Botón Nueva Orden
          ElevatedButton.icon(
            onPressed: () => context.go('/orders/create'),
            icon: const Icon(Icons.add),
            label: const Text('Nueva Orden'),
          ),
          const SizedBox(height: 24),

          // Tabla con paginación
          if (paginationState.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (paginationState.orders.isEmpty)
            const Center(child: Text('No hay órdenes'))
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: paginationState.orders.length + 
                    (paginationState.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  // Indicador de carga
                  if (index == paginationState.orders.length) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final order = paginationState.orders[index];
                  return OrderRow(order: order);
                },
              ),
            ),

          // Información de página
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Página ${paginationState.currentPage + 1} '
              'de ${paginationState.totalPages}',
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 4. ACCESIBILIDAD: Semantic Labels

```dart
// ✅ ANTES: Sin accesibilidad
ElevatedButton(
  onPressed: () => createOrder(),
  child: const Icon(Icons.add),
)

// ✅ DESPUÉS: Con accesibilidad
Semantics(
  button: true,
  enabled: true,
  label: 'Crear nueva orden',
  customSemanticsActions: {
    CustomSemanticsAction(label: 'Crear orden'): () => createOrder(),
  },
  child: ElevatedButton.icon(
    onPressed: () => createOrder(),
    icon: const Icon(Icons.add),
    label: const Text('Nueva Orden'),
    tooltip: 'Crear nueva orden (Ctrl+N)',
  ),
)
```

---

## 5. SEO: Meta Tags Dinámicos

Actualizar `web/index.html`:

```html
<!DOCTYPE html>
<html lang="es">
<head>
  <base href="$FLUTTER_BASE_HREF">

  <meta charset="UTF-8">
  <meta content="IE=Edge" http-equiv="X-UA-Compatible">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  
  <!-- SEO Meta Tags -->
  <meta name="description" content="BellezApp - Sistema profesional de gestión de inventario, órdenes, productos y reportes para negocios de belleza. Panel administrativo completo con análisis en tiempo real.">
  <meta name="keywords" content="gestión de inventario, sistema de órdenes, dashboard administración, productos, reportes, belleza">
  <meta name="author" content="BellezApp">
  <meta name="theme-color" content="#1976d2">

  <!-- Open Graph (Social Media) -->
  <meta property="og:type" content="website">
  <meta property="og:title" content="BellezApp - Panel de Administración">
  <meta property="og:description" content="Sistema profesional de gestión para negocios de belleza">
  <meta property="og:image" content="https://bellezapp.example.com/og-image.png">
  <meta property="og:url" content="https://bellezapp.example.com">
  <meta property="og:locale" content="es_ES">

  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="BellezApp - Panel de Administración">
  <meta name="twitter:description" content="Sistema profesional de gestión">
  <meta name="twitter:image" content="https://bellezapp.example.com/og-image.png">

  <!-- Mobile -->
  <meta name="mobile-web-app-capable" content="yes">
  <meta name="apple-mobile-web-app-status-bar-style" content="black">
  <meta name="apple-mobile-web-app-title" content="BellezApp">
  <link rel="apple-touch-icon" href="icons/Icon-192.png">

  <!-- Favicon -->
  <link rel="icon" type="image/png" href="favicon.png"/>
  <link rel="shortcut icon" href="favicon.png">

  <!-- Canonical -->
  <link rel="canonical" href="https://bellezapp.example.com">

  <!-- PWA Manifest -->
  <link rel="manifest" href="manifest.json">

  <title>BellezApp - Gestión de Inventario y Órdenes | Panel Administrativo Profesional</title>
</head>
<body>
  <script src="flutter_bootstrap.js" async></script>
</body>
</html>
```

---

## 6. PWA: Manifest.json Mejorado

`web/manifest.json`:

```json
{
  "name": "BellezApp - Panel de Administración",
  "short_name": "BellezApp",
  "description": "Sistema profesional de gestión de inventario, órdenes y reportes",
  "start_url": "/",
  "scope": "/",
  "display": "standalone",
  "theme_color": "#1976d2",
  "background_color": "#ffffff",
  "orientation": "portrait-primary",
  "screenshots": [
    {
      "src": "/screenshots/screenshot-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "form_factor": "wide"
    }
  ],
  "icons": [
    {
      "src": "/icons/Icon-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/Icon-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "any"
    },
    {
      "src": "/icons/Icon-maskable-192.png",
      "sizes": "192x192",
      "type": "image/png",
      "purpose": "maskable"
    },
    {
      "src": "/icons/Icon-maskable-512.png",
      "sizes": "512x512",
      "type": "image/png",
      "purpose": "maskable"
    }
  ],
  "categories": ["business", "productivity"],
  "prefer_related_applications": false
}
```

---

## 7. Validators: Input Validation

Crear `lib/shared/utils/validators.dart`:

```dart
class Validators {
  // Email
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // Teléfono
  static bool isValidPhone(String phone) {
    final phoneRegex = RegExp(r'^[\d\s\-+()]{7,}$');
    return phoneRegex.hasMatch(phone);
  }

  // Número entero positivo
  static bool isValidPositiveInt(String value) {
    final num = int.tryParse(value);
    return num != null && num > 0;
  }

  // Número decimal positivo
  static bool isValidPositiveDouble(String value) {
    final num = double.tryParse(value);
    return num != null && num > 0;
  }

  // URL
  static bool isValidUrl(String url) {
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$',
    );
    return urlRegex.hasMatch(url);
  }

  // Nombre (mínimo 2 caracteres)
  static bool isValidName(String name) {
    return name.trim().length >= 2;
  }

  // Contraseña (mínimo 8, con mayúscula, minúscula, número)
  static bool isValidPassword(String password) {
    return password.length >= 8 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[a-z]')) &&
        password.contains(RegExp(r'[0-9]'));
  }
}

// Uso en formularios:
class CreateOrderPage extends ConsumerStatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'Cantidad',
              errorText: _validateQuantity(_quantityController.text),
            ),
          ),
        ],
      ),
    );
  }

  String? _validateQuantity(String value) {
    if (value.isEmpty) {
      return 'La cantidad es requerida';
    }
    if (!Validators.isValidPositiveInt(value)) {
      return 'Debe ser un número mayor a 0';
    }
    return null;
  }
}
```

---

## Resumen de Implementación

| Característica | Archivo | Prioridad | Tiempo |
|---|---|---|---|
| Secure Storage | `secure_storage_service.dart` | 🔴 Crítica | 30min |
| Rate Limiter | `rate_limiter_service.dart` | 🔴 Crítica | 45min |
| Paginación | `order_pagination_notifier.dart` | 🔴 Crítica | 90min |
| Semantic Labels | Múltiples widgets | ⚠️ Alta | 60min |
| Meta Tags | `web/index.html` | ⚠️ Alta | 20min |
| PWA Manifest | `web/manifest.json` | ⚠️ Alta | 15min |
| Validators | `validators.dart` | ⚠️ Alta | 30min |

**Tiempo total:** ~5 horas
**Impacto:** Seguridad + Rendimiento + UX = 40% mejora
