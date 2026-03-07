import 'package:flutter/material.dart';
import '../utils/responsive.dart';

/// Builder centralizado para diálogos de formulario consistentes.
///
/// Elimina la repetición de AlertDialog + SizedBox + SingleChildScrollView + Column
/// que se repite en 12+ páginas.
///
/// Uso:
/// ```dart
/// showDialog(
///   context: context,
///   builder: (_) => AppFormDialog(
///     title: 'Crear Producto',
///     preferredWidth: 600,
///     onSave: () => _save(),
///     onCancel: () => Navigator.pop(context),
///     saveLabel: 'Guardar',
///     isLoading: _isLoading,
///     children: [
///       TextField(...),
///       SizedBox(height: 16),
///       DropdownButton(...),
///     ],
///   ),
/// );
/// ```
class AppFormDialog extends StatelessWidget {
  /// Título del diálogo.
  final String title;

  /// Ancho preferido (se adapta a pantallas pequeñas con Responsive).
  final double preferredWidth;

  /// Widgets del formulario (campos, dropdowns, etc.).
  final List<Widget> children;

  /// Callback al presionar el botón de guardar.
  final VoidCallback? onSave;

  /// Callback al presionar cancelar. Si es null, usa `Navigator.pop`.
  final VoidCallback? onCancel;

  /// Texto del botón de guardar.
  final String saveLabel;

  /// Texto del botón de cancelar.
  final String cancelLabel;

  /// Si es true, muestra un indicador de carga en el botón de guardar.
  final bool isLoading;

  /// Widget extra para las acciones (e.g., botón de eliminar).
  final Widget? extraAction;

  /// CrossAxisAlignment para la columna de contenido.
  final CrossAxisAlignment crossAxisAlignment;

  const AppFormDialog({
    super.key,
    required this.title,
    this.preferredWidth = 500,
    required this.children,
    this.onSave,
    this.onCancel,
    this.saveLabel = 'Guardar',
    this.cancelLabel = 'Cancelar',
    this.isLoading = false,
    this.extraAction,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  @override
  Widget build(BuildContext context) {
    final r = Responsive(context);

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: r.dialogWidth(preferred: preferredWidth),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: crossAxisAlignment,
            children: children,
          ),
        ),
      ),
      actions: [
        if (extraAction != null) extraAction!,
        TextButton(
          onPressed: isLoading ? null : (onCancel ?? () => Navigator.pop(context)),
          child: Text(cancelLabel),
        ),
        if (onSave != null)
          ElevatedButton(
            onPressed: isLoading ? null : onSave,
            child: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(saveLabel),
          ),
      ],
    );
  }
}

/// Muestra un diálogo de confirmación estandarizado.
///
/// Devuelve `true` si el usuario confirma, `false` si cancela.
///
/// Uso:
/// ```dart
/// final confirmed = await showConfirmDialog(
///   context,
///   title: '¿Eliminar producto?',
///   message: 'Esta acción no se puede deshacer.',
///   confirmLabel: 'Eliminar',
///   isDestructive: true,
/// );
/// ```
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Confirmar',
  String cancelLabel = 'Cancelar',
  bool isDestructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(cancelLabel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: isDestructive
              ? ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error,
                  foregroundColor: Colors.white,
                )
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
