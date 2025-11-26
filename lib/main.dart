import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'shared/config/app_router.dart';
import 'shared/providers/riverpod/theme_notifier.dart';
import 'shared/widgets/persistence_initializer.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      child: PersistenceInitializer(
        child: BellezAppWeb(),
      ),
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
      title: 'naturalMARKET',
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

