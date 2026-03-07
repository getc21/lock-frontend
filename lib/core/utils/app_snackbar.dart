import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Tipos de SnackBar disponibles en la aplicación.
enum SnackBarType { success, error, warning, info }

/// Utilidad centralizada para mostrar SnackBars consistentes en toda la app.
///
/// Uso:
/// ```dart
/// AppSnackbar.show(context, message: 'Producto creado', type: SnackBarType.success);
/// AppSnackbar.error(context, 'Error al guardar');
/// AppSnackbar.success(context, 'Guardado correctamente');
/// ```
class AppSnackbar {
  AppSnackbar._();

  /// Muestra un SnackBar con estilo según el [type].
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration? duration,
    SnackBarAction? action,
  }) {
    if (!context.mounted) return;

    final colors = _colorsForType(type);
    final icon = _iconForType(type);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: colors,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          duration: duration ?? _durationForType(type),
          action: action,
        ),
      );
  }

  /// Atajo para SnackBar de éxito.
  static void success(BuildContext context, String message, {Duration? duration}) {
    show(context, message: message, type: SnackBarType.success, duration: duration);
  }

  /// Atajo para SnackBar de error.
  static void error(BuildContext context, String message, {Duration? duration}) {
    show(context, message: message, type: SnackBarType.error, duration: duration);
  }

  /// Atajo para SnackBar de advertencia.
  static void warning(BuildContext context, String message, {Duration? duration}) {
    show(context, message: message, type: SnackBarType.warning, duration: duration);
  }

  /// Atajo para SnackBar informativo.
  static void info(BuildContext context, String message, {Duration? duration}) {
    show(context, message: message, type: SnackBarType.info, duration: duration);
  }

  static Color _colorsForType(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return AppColors.success;
      case SnackBarType.error:
        return AppColors.error;
      case SnackBarType.warning:
        return AppColors.warning;
      case SnackBarType.info:
        return AppColors.info;
    }
  }

  static IconData _iconForType(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return Icons.check_circle_outline;
      case SnackBarType.error:
        return Icons.error_outline;
      case SnackBarType.warning:
        return Icons.warning_amber_rounded;
      case SnackBarType.info:
        return Icons.info_outline;
    }
  }

  static Duration _durationForType(SnackBarType type) {
    switch (type) {
      case SnackBarType.success:
        return const Duration(seconds: 3);
      case SnackBarType.error:
        return const Duration(seconds: 5);
      case SnackBarType.warning:
        return const Duration(seconds: 4);
      case SnackBarType.info:
        return const Duration(seconds: 3);
    }
  }
}
