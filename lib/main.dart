import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/login_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/products/products_page.dart';
import 'features/orders/orders_page.dart';
import 'features/customers/customers_page.dart';
import 'features/reports/reports_page.dart';
import 'features/reports/advanced_reports_page.dart';

// Importar controllers
import 'shared/controllers/auth_controller.dart';
import 'shared/controllers/store_controller.dart';
import 'shared/controllers/product_controller.dart';
import 'shared/controllers/order_controller.dart';
import 'shared/controllers/customer_controller.dart';
import 'shared/controllers/discount_controller.dart';
import 'shared/controllers/reports_controller.dart';

void main() {
  // Inicializar controllers de GetX
  Get.put(AuthController());
  Get.put(StoreController());
  Get.put(ProductController());
  Get.put(OrderController());
  Get.put(CustomerController());
  Get.put(DiscountController());
  Get.put(ReportsController());
  
  runApp(const BellezAppWeb());
}

class BellezAppWeb extends StatelessWidget {
  const BellezAppWeb({super.key});

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
      initialRoute: '/login',
      getPages: [
        GetPage(name: '/login', page: () => const LoginPage()),
        GetPage(name: '/dashboard', page: () => const DashboardPage()),
        GetPage(name: '/products', page: () => const ProductsPage()),
        GetPage(name: '/orders', page: () => const OrdersPage()),
        GetPage(name: '/customers', page: () => const CustomersPage()),
        GetPage(name: '/reports', page: () => const ReportsPage()),
        GetPage(name: '/advanced-reports', page: () => const AdvancedReportsPage()),
      ],
    );
  }
}
