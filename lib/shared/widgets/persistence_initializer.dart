import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/riverpod/auth_notifier.dart';
import '../providers/riverpod/theme_notifier.dart';
import '../providers/riverpod/currency_notifier.dart';

/// Widget que se muestra mientras se inicializa la persistencia
class PersistenceInitializer extends ConsumerStatefulWidget {
  final Widget child;

  const PersistenceInitializer({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<PersistenceInitializer> createState() =>
      _PersistenceInitializerState();
}

class _PersistenceInitializerState
    extends ConsumerState<PersistenceInitializer> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePersistence();
  }

  Future<void> _initializePersistence() async {
    try {
      // Esperar a que los providers se inicialicen con la persistencia
      // Los providers cargan automáticamente en su constructor
      await Future.wait([
        Future.delayed(const Duration(milliseconds: 500)), // Dar tiempo para cargar
      ]);

      // Verificar que todo esté cargado
      final authState = ref.read(authProvider);
      final themeState = ref.read(themeProvider);
      final currencyState = ref.read(currencyProvider);

      debugPrint('✅ Persistencia inicializada:');
      debugPrint('   - Sesión: ${authState.isLoggedIn ? 'Cargada' : 'No cargada'}');
      debugPrint('   - Tema: ${themeState.isInitialized ? 'Cargado' : 'No cargado'}');
      debugPrint('   - Moneda: ${currencyState.isInitialized ? 'Cargada' : 'No cargada'}');

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('❌ Error en PersistenceInitializer: $e');
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      // Leer el tema actual
      final themeState = ref.watch(themeProvider);
      final themeNotifier = ref.watch(themeProvider.notifier);
      final currentTheme = themeNotifier.currentTheme;
      
      // Determinar si es modo oscuro
      final brightness = MediaQuery.of(context).platformBrightness;
      final isDarkMode = themeState.themeMode == ThemeMode.dark ||
          (themeState.themeMode == ThemeMode.system && brightness == Brightness.dark);
      
      final bgColor = isDarkMode ? Colors.grey[900] : Colors.white;
      final textColor = isDarkMode ? Colors.white : Colors.black87;
      final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[600];

      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: bgColor,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        currentTheme.primaryColor.withOpacity(0.15),
                        currentTheme.accentColor.withOpacity(0.08),
                      ]
                    : [
                        currentTheme.primaryColor.withOpacity(0.1),
                        currentTheme.accentColor.withOpacity(0.05),
                      ],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          currentTheme.primaryColor,
                          currentTheme.accentColor,
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.spa,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'BellezApp',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Restaurando tu sesión...',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        currentTheme.primaryColor,
                      ),
                      strokeWidth: 2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return widget.child;
  }
}
