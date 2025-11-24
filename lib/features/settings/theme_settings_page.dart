import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../shared/widgets/dashboard_layout.dart';
import '../../shared/providers/riverpod/theme_notifier.dart';
import '../../shared/providers/riverpod/currency_notifier.dart';

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final currencyState = ref.watch(currencyProvider);
    final currencyNotifier = ref.read(currencyProvider.notifier);

    if (!themeState.isInitialized) {
      return const DashboardLayout(
        title: 'Configuración de Temas',
        currentRoute: '/theme-settings',
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return DashboardLayout(
      title: 'Configuración de Temas',
      currentRoute: '/theme-settings',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Título
            const Text(
              'Personalización de Temas',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSizes.spacing8),
            const Text(
              'Selecciona un tema para cambiar la apariencia de la aplicación',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSizes.spacing32),

            // Modo de tema
            const Text(
              'Modo de Visualización',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSizes.spacing16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacing16),
                child: Column(
                  children: [
                    _buildThemeModeOption(
                      context,
                      themeNotifier,
                      themeState,
                      ThemeMode.light,
                      'Modo Claro',
                      'Siempre usar tema claro',
                      Icons.light_mode,
                    ),
                    const Divider(height: 32),
                    _buildThemeModeOption(
                      context,
                      themeNotifier,
                      themeState,
                      ThemeMode.dark,
                      'Modo Oscuro',
                      'Siempre usar tema oscuro',
                      Icons.dark_mode,
                    ),
                    const Divider(height: 32),
                    _buildThemeModeOption(
                      context,
                      themeNotifier,
                      themeState,
                      ThemeMode.system,
                      'Automático',
                      'Seguir configuración del sistema',
                      Icons.auto_mode,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spacing32),

            // Temas disponibles
            const Text(
              'Temas Disponibles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSizes.spacing16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: themeNotifier.availableThemes.length,
              itemBuilder: (context, index) {
                final theme = themeNotifier.availableThemes[index];
                final isSelected = themeState.currentThemeId == theme.id;

                return _buildThemeCard(
                  context,
                  theme,
                  isSelected,
                  () => themeNotifier.changeTheme(theme.id),
                );
              },
            ),
            const SizedBox(height: AppSizes.spacing32),

            // Selector de Moneda
            const Text(
              'Configuración de Moneda',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSizes.spacing16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.spacing16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Selecciona la moneda para mostrar valores monetarios',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.spacing16),
                    DropdownButton<String>(
                      value: currencyState.currentCurrencyId,
                      isExpanded: true,
                      items: currencyNotifier.availableCurrencies.map((currency) {
                        return DropdownMenuItem(
                          value: currency.id,
                          child: Row(
                            children: [
                              Text(
                                currency.symbol,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      currency.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      currency.code,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (currencyId) {
                        if (currencyId != null) {
                          currencyNotifier.changeCurrency(currencyId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                'Moneda cambiada a ${currencyNotifier.currentCurrency.name}',
                              ),
                              backgroundColor: Colors.green,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSizes.spacing32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showResetDialog(context, themeNotifier),
                icon: const Icon(Icons.refresh),
                label: const Text('Restablecer Tema'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: AppColors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.spacing24,
                    vertical: AppSizes.spacing16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeModeOption(
    BuildContext context,
    ThemeNotifier notifier,
    ThemeState state,
    ThemeMode mode,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = state.themeMode == mode;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Theme.of(context).primaryColor : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary),
      ),
      trailing: GestureDetector(
        onTap: () => notifier.changeThemeMode(mode),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected ? Theme.of(context).primaryColor : AppColors.border,
              width: 2,
            ),
          ),
          child: isSelected
              ? Icon(
                  Icons.check,
                  size: 14,
                  color: Theme.of(context).primaryColor,
                )
              : null,
        ),
      ),
      onTap: () => notifier.changeThemeMode(mode),
    );
  }

  Widget _buildThemeCard(
    BuildContext context,
    ThemeModel theme,
    bool isSelected,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.primaryColor : AppColors.border,
            width: isSelected ? 3 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Card(
          elevation: isSelected ? 8 : 2,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.primaryColor.withValues(alpha: 0.8),
                  theme.accentColor.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSizes.spacing16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview color
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: theme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: theme.accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Spacer(),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                    ],
                  ),
                  // Nombre y descripción
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        theme.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showResetDialog(BuildContext context, ThemeNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Restablecer Tema'),
        content: const Text('¿Estás seguro de que deseas restablecer el tema a la configuración por defecto?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await notifier.resetTheme();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Tema restablecido a la configuración por defecto'),
                    backgroundColor: Colors.green,
                  ),
                );
                // Navegar al dashboard
                Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (_) => false);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );
  }
}

