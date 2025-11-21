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
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.pink.withOpacity(0.1),
                  Colors.purple.withOpacity(0.05),
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
                          Colors.pink.shade400,
                          Colors.pink.shade300,
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
                  const Text(
                    'BellezApp',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Restaurando tu sesión...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(
                    width: 40,
                    height: 40,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFEC407A),
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
