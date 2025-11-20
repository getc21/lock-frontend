import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/loading_indicator.dart';
import 'features/auth/login_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/products/products_page.dart';
import 'features/orders/orders_page.dart';
import 'features/orders/create_order_page.dart';
import 'features/customers/customers_page.dart';
import 'features/reports/reports_page.dart';
import 'features/categories/categories_page.dart';
import 'features/locations/locations_page.dart';
import 'features/users/users_page.dart';
import 'features/suppliers/suppliers_page.dart';

// Importar controllers
import 'shared/controllers/auth_controller.dart';
import 'shared/controllers/store_controller.dart';
import 'shared/controllers/product_controller.dart';
import 'shared/controllers/order_controller.dart';
import 'shared/controllers/customer_controller.dart';
import 'shared/controllers/discount_controller.dart';
import 'shared/controllers/reports_controller.dart';
import 'shared/controllers/category_controller.dart';
import 'shared/controllers/location_controller.dart';
import 'shared/controllers/user_controller.dart';
import 'shared/controllers/supplier_controller.dart';

void main() async {
  // Asegurar que Flutter esté inicializado
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializar AuthController y esperar a que cargue la sesión
  final authController = Get.put(AuthController());
  
  // Inicializar otros controllers
  Get.put(StoreController());
  Get.put(ProductController());
  Get.put(OrderController());
  Get.put(CustomerController());
  Get.put(DiscountController());
  Get.put(ReportsController());
  Get.put(CategoryController());
  Get.put(LocationController());
  Get.put(UserController());
  Get.put(SupplierController());
  
  runApp(
    ProviderScope(
      child: BellezAppWeb(authController: authController),
    ),
  );
}

class BellezAppWeb extends StatelessWidget {
  final AuthController authController;
  
  const BellezAppWeb({super.key, required this.authController});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BellezApp - Panel de Administración',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      locale: const Locale('es', 'ES'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'),
        Locale('en', 'US'),
      ],
      home: Obx(() {
        // Mostrar splash mientras carga
        if (authController.isLoading) {
          return const Scaffold(
            body: LoadingIndicator(
              message: 'Inicializando...',
            ),
          );
        }
        
        // Si está autenticado, ir al dashboard, si no al login
        return authController.isLoggedIn 
            ? const DashboardPage() 
            : const LoginPage();
      }),
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/dashboard', page: () => const DashboardPage()),
        GetPage(name: '/products', page: () => const ProductsPage()),
        GetPage(name: '/orders', page: () => const OrdersPage()),
        GetPage(name: '/orders/create', page: () => const CreateOrderPage()),
        GetPage(name: '/customers', page: () => const CustomersPage()),
        GetPage(name: '/reports', page: () => const ReportsPage()),
        GetPage(name: '/categories', page: () => const CategoriesPage()),
        GetPage(name: '/locations', page: () => const LocationsPage()),
        GetPage(name: '/suppliers', page: () => const SuppliersPage()),
        GetPage(name: '/users', page: () => const UsersPage()),
      ],
    );
  }
}
