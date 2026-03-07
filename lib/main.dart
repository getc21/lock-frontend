import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'shared/config/app_router.dart';
import 'shared/providers/riverpod/theme_notifier.dart';
import 'shared/providers/riverpod/auth_notifier.dart';
import 'shared/providers/riverpod/currency_notifier.dart';
import 'shared/providers/riverpod/store_notifier.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Crear un ProviderContainer separado para inicializar los providers
  final container = ProviderContainer();
  
  try {
    // Inicializar auth primero (se necesita token para cargar tiendas)
    await container.read(authProvider.notifier).initializeAuth();
    
    // Luego inicializar otros providers que dependen de auth
    await Future.wait([
      container.read(themeProvider.notifier).initializeTheme(),
      container.read(currencyProvider.notifier).initializeCurrency(),
      container.read(storeProvider.notifier).initializeStore(),
    ]);
  } catch (e) {
    debugPrint('Error initializing persistence: $e');
  }
  
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BellezAppWeb(),
    ),
  );
}

class BellezAppWeb extends ConsumerWidget {
  const BellezAppWeb({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    
    final themeState = ref.watch(themeProvider);
    
    // Obtener el tema actual basado en los colores seleccionados
    ThemeData currentTheme;
    if (themeState.isInitialized) {
      final currentThemeId = themeState.currentThemeId;
      final notifier = ref.read(themeProvider.notifier);
      final theme = notifier.availableThemes.firstWhere(
        (t) => t.id == currentThemeId,
        orElse: () => notifier.availableThemes.first,
      );
      currentTheme = AppTheme.createTheme(
        primaryColor: theme.primaryColor,
        secondaryColor: theme.accentColor,
        brightness: themeState.themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light,
      );
    } else {
      currentTheme = AppTheme.lightTheme;
    }
    
    return MaterialApp.router(
      title: 'SynergyApp',
      debugShowCheckedModeBanner: false,
      theme: currentTheme,
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
      routerConfig: AppRouter.router,
    );
  }
}

