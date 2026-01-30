import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/login_page.dart';
import '../../features/dashboard/dashboard_page.dart';
import '../../features/orders/orders_page.dart';
import '../../features/orders/create_order_page.dart';
import '../../features/products/products_page.dart';
import '../../features/reports/reports_page.dart';
import '../../features/categories/categories_page.dart';
import '../../features/locations/locations_page.dart';
import '../../features/users/users_page.dart';
import '../../features/suppliers/suppliers_page.dart';
import '../../features/customers/customers_page.dart';
import '../../features/stores/stores_page.dart';
import '../../features/settings/theme_settings_page.dart';
import '../../features/expenses/expense_report_page.dart';
import '../../features/expenses/expense_form_page.dart';
import '../../features/returns/pages/returns_list_page.dart';
import '../../features/returns/pages/create_return_page.dart';
import '../../shared/providers/riverpod/auth_notifier.dart';
import '../../shared/providers/riverpod/store_notifier.dart';
import 'route_transitions.dart';

/// Configuración de rutas optimizada para SPA
/// 
/// Utiliza go_router para:
/// - Manejo eficiente de navegación sin recargar la app
/// - Lazy loading de páginas bajo demanda
/// - Transiciones suaves con animaciones personalizadas
/// - Gestión centralizada de rutas y argumentos
class AppRouter {
  static final GoRouter router = GoRouter(
    redirect: _redirectLogic,
    routes: _buildRoutes(),
    initialLocation: '/',
    debugLogDiagnostics: false,
  );

  /// Lógica de redirección basada en estado de autenticación
  static String? _redirectLogic(BuildContext context, GoRouterState state) {
    final authState = _getAuthState(context);

    // Usuario no autenticado: redirigir a login
    if (!authState.isLoggedIn && state.matchedLocation != '/login') {
      return '/login';
    }

    // Usuario autenticado en login: ir a dashboard
    if (authState.isLoggedIn && state.matchedLocation == '/login') {
      return '/dashboard';
    }

    return null;
  }

  /// Obtiene el estado de autenticación desde Riverpod
  static AuthState _getAuthState(BuildContext context) {
    final container = ProviderScope.containerOf(context);
    return container.read(authProvider);
  }

  /// Construye el árbol de rutas de la aplicación
  /// 
  /// Cada ruta es lazy-loaded y puede tener transiciones personalizadas
  static List<RouteBase> _buildRoutes() {
    return [
      // Ruta de login
      GoRoute(
        path: '/login',
        name: 'login',
        pageBuilder: (context, state) => _buildPage(
          child: const LoginPage(),
          state: state,
          transitionType: RouteTransitionType.fade,
        ),
      ),

      // Ruta de dashboard
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        pageBuilder: (context, state) => _buildPage(
          child: const DashboardPage(),
          state: state,
          transitionType: RouteTransitionType.fade,
        ),
      ),

      // Rutas de órdenes
      GoRoute(
        path: '/orders',
        name: 'orders',
        pageBuilder: (context, state) => _buildPage(
          child: const OrdersPage(),
          state: state,
          transitionType: RouteTransitionType.fade,
        ),
        routes: [
          GoRoute(
            path: 'create',
            name: 'createOrder',
            pageBuilder: (context, state) => _buildPage(
              child: const CreateOrderPage(),
              state: state,
              transitionType: RouteTransitionType.fade,
            ),
          ),
        ],
      ),

      // Rutas de devoluciones
      GoRoute(
        path: '/returns',
        name: 'returns',
        pageBuilder: (context, state) {
          return _buildPage(
            child: const ReturnsListPage(),
            state: state,
            transitionType: RouteTransitionType.fade,
          );
        },
        routes: [
          GoRoute(
            path: 'create/:orderId',
            name: 'createReturn',
            pageBuilder: (context, state) {
              final orderId = state.pathParameters['orderId']!;
              final customerName = state.uri.queryParameters['customerName'] ?? 'Cliente';
              return _buildPage(
                child: CreateReturnPage(
                  orderId: orderId,
                  customerName: customerName,
                ),
                state: state,
                transitionType: RouteTransitionType.fade,
              );
            },
          ),
        ],
      ),

      // Ruta de productos
      GoRoute(
        path: '/products',
        name: 'products',
        pageBuilder: (context, state) => _buildPage(
          child: const ProductsPage(),
          state: state,
          transitionType: RouteTransitionType.fade,
        ),
      ),

      // Ruta de clientes
      GoRoute(
        path: '/customers',
        name: 'customers',
        pageBuilder: (context, state) => _buildPage(
          child: const CustomersPage(),
          state: state,
          transitionType: RouteTransitionType.fade,
        ),
      ),

      // Ruta de reportes
      GoRoute(
        path: '/reports',
        name: 'reports',
        pageBuilder: (context, state) => _buildPage(
          child: const ReportsPage(),
          state: state,
          transitionType: RouteTransitionType.fade,
        ),
      ),

      // Rutas de gastos
      GoRoute(
        path: '/expenses',
        name: 'expenses',
        pageBuilder: (context, state) => _buildPage(
          child: const ExpenseReportPage(),
          state: state,
          transitionType: RouteTransitionType.fade,
        ),
        routes: [
          GoRoute(
            path: 'report',
            name: 'expenseReport',
            pageBuilder: (context, state) => _buildPage(
              child: const ExpenseReportPage(),
              state: state,
              transitionType: RouteTransitionType.fade,
            ),
          ),
          GoRoute(
            path: 'new',
            name: 'newExpense',
            pageBuilder: (context, state) => _buildPage(
              child: const ExpenseFormPage(),
              state: state,
              transitionType: RouteTransitionType.fade,
            ),
          ),
        ],
      ),

      // Ruta de categorías
      GoRoute(
        path: '/categories',
        name: 'categories',
        pageBuilder: (context, state) => _buildPage(
          child: const CategoriesPage(),
          state: state,
          transitionType: RouteTransitionType.fade,
        ),
      ),

      // Ruta de ubicaciones
      GoRoute(
        path: '/locations',
        name: 'locations',
        pageBuilder: (context, state) => _buildPage(
          child: const LocationsPage(),
          state: state,
          transitionType: RouteTransitionType.fade,
        ),
      ),

      // Ruta de proveedores
      GoRoute(
        path: '/suppliers',
        name: 'suppliers',
        pageBuilder: (context, state) => _buildPage(
          child: const SuppliersPage(),
          state: state,
          transitionType: RouteTransitionType.fade,
        ),
      ),

      // Ruta de usuarios
      GoRoute(
        path: '/users',
        name: 'users',
        pageBuilder: (context, state) => _buildPage(
          child: const UsersPage(),
          state: state,
          transitionType: RouteTransitionType.fade,
        ),
      ),

      // Ruta de tiendas
      GoRoute(
        path: '/stores',
        name: 'stores',
        pageBuilder: (context, state) => _buildPage(
          child: const StoresPage(),
          state: state,
          transitionType: RouteTransitionType.fade,
        ),
      ),

      // Ruta de configuración de tema
      GoRoute(
        path: '/settings/theme',
        name: 'themeSettings',
        pageBuilder: (context, state) => _buildPage(
          child: const ThemeSettingsPage(),
          state: state,
          transitionType: RouteTransitionType.fade,
        ),
      ),

      // Ruta fallback (404 -> dashboard)
      GoRoute(
        path: '/',
        redirect: (context, state) => '/dashboard',
      ),
    ];
  }

  /// Constructor privado para prevenir instanciación
  AppRouter._();

  /// Construye una página con transición personalizada
  static Page _buildPage({
    required Widget child,
    required GoRouterState state,
    RouteTransitionType transitionType = RouteTransitionType.fade,
  }) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _getTransition(transitionType)(
          context,
          animation,
          secondaryAnimation,
          child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  /// Obtiene el builder de transición basado en el tipo
  static Widget Function(
    BuildContext,
    Animation<double>,
    Animation<double>,
    Widget,
  ) _getTransition(RouteTransitionType type) {
    return switch (type) {
      RouteTransitionType.fade => fadeTransition,
      RouteTransitionType.slideLeft => slideLeftTransition,
      RouteTransitionType.slideUp => slideUpTransition,
      RouteTransitionType.scale => scaleTransition,
    };
  }
}

/// Tipos de transiciones disponibles
enum RouteTransitionType {
  fade,
  slideLeft,
  slideUp,
  scale,
}

