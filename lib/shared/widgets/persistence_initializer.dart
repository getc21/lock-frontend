import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/riverpod/auth_notifier.dart';
import '../providers/riverpod/theme_notifier.dart';
import '../providers/riverpod/currency_notifier.dart';
import '../utils/theme_utils.dart';

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
      // Esperar a que se inicialicen todos los notifiers desde SharedPreferences
      await Future.wait([
        ref.read(authProvider.notifier).initializeAuth(),
        ref.read(themeProvider.notifier).initializeTheme(),
        ref.read(currencyProvider.notifier).initializeCurrency(),
      ]);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      if (kDebugMode) {

      }
      // Marcar como inicializado incluso en caso de error para no bloquear la app
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
      final isDarkMode = ThemeUtils.isDarkMode(themeState.themeMode, brightness);
      
      final bgColor = isDarkMode ? Colors.grey[900] : Colors.white;
      final textColor = isDarkMode ? Colors.white : Colors.black87;
      final secondaryTextColor = ThemeUtils.getSecondaryTextColor(isDarkMode);

      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'naturalMARKET',
        home: Scaffold(
          backgroundColor: bgColor,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDarkMode
                    ? [
                        currentTheme.primaryColor.withValues(alpha: 0.15),
                        currentTheme.accentColor.withValues(alpha: 0.08),
                      ]
                    : [
                        currentTheme.primaryColor.withValues(alpha: 0.1),
                        currentTheme.accentColor.withValues(alpha: 0.05),
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

