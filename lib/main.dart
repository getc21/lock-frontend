import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'shared/widgets/loading_indicator.dart';
import 'features/auth/login_page.dart';
import 'features/dashboard/dashboard_page.dart';
import 'features/orders/orders_page.dart';
import 'features/orders/create_order_page.dart';
import 'features/reports/reports_page.dart';
import 'features/categories/categories_page.dart';
import 'features/locations/locations_page.dart';
import 'features/users/users_page.dart';
import 'features/suppliers/suppliers_page.dart';
import 'shared/providers/riverpod/auth_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: BellezAppWeb(),
    ),
  );
}

class BellezAppWeb extends ConsumerWidget {
  const BellezAppWeb({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    
    return MaterialApp(
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
      home: authState.isLoading
          ? const Scaffold(
              body: LoadingIndicator(
                message: 'Inicializando...',
              ),
            )
          : authState.isLoggedIn
              ? const DashboardPage()
              : const LoginPage(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/dashboard': (context) => const DashboardPage(),
        '/orders': (context) => const OrdersPage(),
        '/orders/create': (context) => const CreateOrderPage(),
        '/reports': (context) => const ReportsPage(),
        '/categories': (context) => const CategoriesPage(),
        '/locations': (context) => const LocationsPage(),
        '/suppliers': (context) => const SuppliersPage(),
        '/users': (context) => const UsersPage(),
      },
    );
  }
}
