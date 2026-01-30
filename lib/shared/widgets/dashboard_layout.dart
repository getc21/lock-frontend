import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../providers/riverpod/auth_notifier.dart';
import '../providers/riverpod/store_notifier.dart';
import '../providers/riverpod/theme_notifier.dart';
import '../providers/riverpod/currency_notifier.dart';
import '../providers/riverpod/product_notifier.dart';

// Provider para el estado de colapso del sidebar
final dashboardCollapseProvider = StateProvider<bool>((ref) => false);

class DashboardLayout extends ConsumerWidget {
  final Widget child;
  final String title;
  final String currentRoute;

  const DashboardLayout({
    super.key,
    required this.child,
    required this.title,
    required this.currentRoute,
  });

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(dialogContext).pop();
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  String? _getSelectedStoreId(dynamic storeState) {
    // Obtener el ID de la tienda actual si existe y está en la lista
    if (storeState.currentStore != null && storeState.stores.isNotEmpty) {
      final currentStoreId = storeState.currentStore['_id'];
      if (currentStoreId != null &&
          storeState.stores.any((s) => s['_id'] == currentStoreId)) {
        return currentStoreId as String?;
      }
    }
    // Si no hay tienda seleccionada válida, retornar la primera
    if (storeState.stores.isNotEmpty) {
      return storeState.stores.first['_id'] as String?;
    }
    return null;
  }

  void _showThemeModal(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSizes.radiusLarge),
        ),
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.spacing24,
          vertical: AppSizes.spacing24,
        ),
        child: _buildThemeModalContent(dialogContext, ref),
      ),
    );
  }

  Widget _buildThemeModalContent(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final themeNotifier = ref.read(themeProvider.notifier);
    final currencyState = ref.watch(currencyProvider);
    final currencyNotifier = ref.read(currencyProvider.notifier);

    if (!themeState.isInitialized) {
      return Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing24),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Configuración de Temas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.spacing24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Modo de tema
                  const Text(
                    'Modo de Visualización',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                  const SizedBox(height: AppSizes.spacing24),

                  // Temas disponibles
                  const Text(
                    'Temas Disponibles',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSizes.spacing16),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
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
                  const SizedBox(height: AppSizes.spacing24),

                  // Selector de Moneda
                  const Text(
                    'Configuración de Moneda',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSizes.spacing16),
                          DropdownButton<String>(
                            value: currencyState.currentCurrencyId,
                            isExpanded: true,
                            items: currencyNotifier.availableCurrencies.map((
                              currency,
                            ) {
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
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            currency.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 13,
                                            ),
                                          ),
                                          Text(
                                            currency.code,
                                            style: const TextStyle(
                                              fontSize: 11,
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
                ],
              ),
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(AppSizes.spacing24),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _showResetDialog(context, themeNotifier),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Restablecer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: AppColors.white,
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSidebarCollapsed = screenWidth < AppSizes.tabletBreakpoint
        ? true
        : ref.watch(dashboardCollapseProvider);

    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(context, ref, isSidebarCollapsed),
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(context, ref),
                // Content Area
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.background,
                          Theme.of(
                            context,
                          ).primaryColor.withValues(alpha: 0.03),
                        ],
                      ),
                    ),
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSizes.spacing24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppSizes.maxContentWidth,
                        ),
                        child: child,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(
    BuildContext context,
    WidgetRef ref,
    bool isSidebarCollapsed,
  ) {
    final authState = ref.watch(authProvider);
    final userRole = authState.currentUser?['role'] ?? '';
    final isAdmin = userRole == 'admin';
    final isManager = userRole == 'manager';

    return _SidebarWidget(
      isAdmin: isAdmin,
      isManager: isManager,
      currentRoute: currentRoute,
      isSidebarCollapsed: isSidebarCollapsed,
      onToggle: () {
        ref.read(dashboardCollapseProvider.notifier).state =
            !isSidebarCollapsed;
      },
    );
  }

  Widget _buildTopBar(BuildContext context, WidgetRef ref) {
    final storeState = ref.watch(storeProvider);
    final authState = ref.watch(authProvider);
    final isAdmin = authState.currentUser?['role'] == 'admin';

    return Container(
      height: AppSizes.appBarHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.white,
            Theme.of(context).primaryColor.withValues(alpha: 0.08),
          ],
        ),
        border: const Border(bottom: BorderSide(color: AppColors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing24),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSizes.spacing24),

          // ⭐ SELECTOR DE TIENDA - SOLO PARA ADMINISTRADORES
          if (isAdmin)
            Tooltip(
              message: storeState.stores.isEmpty
                  ? 'Por favor, añade una tienda primero'
                  : 'Cambiar tienda',
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.spacing12,
                  vertical: AppSizes.spacing4,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.store,
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ),
                    const SizedBox(width: AppSizes.spacing8),
                    if (storeState.stores.isEmpty)
                      Text(
                        'Sin tiendas',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      DropdownButton<String>(
                        value: _getSelectedStoreId(storeState),
                        underline: const SizedBox(),
                        isDense: true,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                        items: storeState.stores.map((store) {
                          return DropdownMenuItem<String>(
                            value: store['_id'] as String?,
                            child: Text(store['name'] ?? 'Sin nombre'),
                          );
                        }).toList(),
                        onChanged: (storeId) async {
                          if (storeId != null) {
                            final store = storeState.stores.firstWhere(
                              (s) => s['_id'] == storeId,
                              orElse: () => {},
                            );
                            if (store.isNotEmpty) {
                              ref.read(storeProvider.notifier).selectStore(store);
                              // Recargar productos para la nueva tienda
                              await ref.read(productProvider.notifier).loadProductsForCurrentStore(forceRefresh: true);
                            }
                          }
                        },
                      ),
                  ],
                ),
              ),
            )
          else if (!isAdmin && storeState.currentStore != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing12,
                vertical: AppSizes.spacing8,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                border: Border.all(
                  color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.store,
                    size: 16,
                    color: Theme.of(context).primaryColor,
                  ),
                  const SizedBox(width: AppSizes.spacing8),
                  Text(
                    storeState.currentStore?['name'] ?? 'Sin tienda',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          const Spacer(),

          // ⭐ INFORMACIÓN DEL USUARIO Y CERRAR SESIÓN
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nombre del usuario
              Text(
                authState.userFullName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: AppSizes.spacing12),

              // Avatar con iniciales
              CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                radius: 16,
                child: Text(
                  authState.userInitials,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const SizedBox(width: AppSizes.spacing8),

              // Botón de configuración de temas
              IconButton(
                icon: const Icon(Icons.palette_outlined),
                onPressed: () => _showThemeModal(context, ref),
                tooltip: 'Configuración de temas',
              ),

              // Botón de cerrar sesión
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => _confirmLogout(context, ref),
                tooltip: 'Cerrar sesión',
              ),
            ],
          ),
        ],
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
        color: isSelected
            ? Theme.of(context).primaryColor
            : AppColors.textSecondary,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? Theme.of(context).primaryColor
              : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
      ),
      trailing: GestureDetector(
        onTap: () => notifier.changeThemeMode(mode),
        child: Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : AppColors.border,
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        theme.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        theme.description,
                        style: const TextStyle(
                          fontSize: 11,
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
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restablecer Tema'),
        content: const Text(
          '¿Estás seguro de que deseas restablecer el tema a la configuración por defecto?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              await notifier.resetTheme();
              if (context.mounted) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Tema restablecido a la configuración por defecto',
                    ),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// WIDGET AISLADO PARA EL SIDEBAR
// ============================================================================

class _SidebarWidget extends StatelessWidget {
  final bool isAdmin;
  final bool isManager;
  final String currentRoute;
  final bool isSidebarCollapsed;
  final VoidCallback onToggle;

  const _SidebarWidget({
    required this.isAdmin,
    required this.isManager,
    required this.currentRoute,
    required this.isSidebarCollapsed,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: isSidebarCollapsed
          ? AppSizes.sidebarCollapsedWidth
          : AppSizes.sidebarWidth,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
        child: Column(
          children: [
            // Logo
            Container(
              height: AppSizes.appBarHeight,
              padding: EdgeInsets.symmetric(
                horizontal: isSidebarCollapsed
                    ? AppSizes.spacing4
                    : AppSizes.spacing16,
              ),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: isSidebarCollapsed
                  ? Center(
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMedium,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            AppSizes.radiusMedium,
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMedium,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(
                                AppSizes.radiusMedium,
                              ),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.spacing12),
                          SizedBox(
                            width: 100,
                            child: Image.asset(
                              'assets/images/NOMBRE.png',
                              height: 24,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            // Navigation Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 0),
                children: [
                  _buildNavItem(
                    context: context,
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    route: '/dashboard',
                    isSidebarCollapsed: isSidebarCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.inventory_2_outlined,
                    label: 'Productos',
                    route: '/products',
                    isSidebarCollapsed: isSidebarCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.category_outlined,
                    label: 'Categorías',
                    route: '/categories',
                    isSidebarCollapsed: isSidebarCollapsed,
                  ),
                  // ⭐ PROVEEDORES - SOLO PARA ADMIN Y MANAGER
                  if (isAdmin || isManager)
                    _buildNavItem(
                      context: context,
                      icon: Icons.local_shipping_outlined,
                      label: 'Proveedores',
                      route: '/suppliers',
                      isSidebarCollapsed: isSidebarCollapsed,
                    ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.location_on_outlined,
                    label: 'Ubicaciones',
                    route: '/locations',
                    isSidebarCollapsed: isSidebarCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.receipt_long_outlined,
                    label: 'Ventas',
                    route: '/orders',
                    isSidebarCollapsed: isSidebarCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.assignment_return_outlined,
                    label: 'Devoluciones',
                    route: '/returns',
                    isSidebarCollapsed: isSidebarCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.people_outline,
                    label: 'Clientes',
                    route: '/customers',
                    isSidebarCollapsed: isSidebarCollapsed,
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.trending_down_outlined,
                    label: 'Gastos',
                    route: '/expenses/report',
                    isSidebarCollapsed: isSidebarCollapsed,
                  ),
                  // ⭐ SOLO MOSTRAR TIENDAS, USUARIOS Y REPORTES PARA ADMINISTRADORES
                  if (isAdmin) ...[
                    _buildNavItem(
                      context: context,
                      icon: Icons.store_outlined,
                      label: 'Tiendas',
                      route: '/stores',
                      isSidebarCollapsed: isSidebarCollapsed,
                    ),
                    _buildNavItem(
                      context: context,
                      icon: Icons.person_outline,
                      label: 'Usuarios',
                      route: '/users',
                      isSidebarCollapsed: isSidebarCollapsed,
                    ),
                    _buildNavItem(
                      context: context,
                      icon: Icons.analytics_outlined,
                      label: 'Reportes',
                      route: '/reports',
                      isSidebarCollapsed: isSidebarCollapsed,
                    ),
                  ],
                ],
              ),
            ),
            // Bottom Actions
            const Divider(height: 1),
            // Botón de colapsar
            Padding(
              padding: const EdgeInsets.all(AppSizes.spacing8),
              child: IconButton(
                icon: Icon(
                  isSidebarCollapsed ? Icons.chevron_right : Icons.chevron_left,
                ),
                onPressed: onToggle,
                tooltip: isSidebarCollapsed ? 'Expandir menú' : 'Colapsar menú',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
    required bool isSidebarCollapsed,
  }) {
    final isSelected = currentRoute == route;

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: isSidebarCollapsed ? 0 : AppSizes.spacing8,
        vertical: AppSizes.spacing4,
      ),
      child: Material(
        color: isSelected
            ? Theme.of(context).primaryColor.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Tooltip(
          message: label,
          showDuration: const Duration(seconds: 3),
          preferBelow: false,
          verticalOffset: 10,
          child: InkWell(
            onTap: () => context.go(route),
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isSidebarCollapsed
                    ? AppSizes.spacing4
                    : AppSizes.spacing16,
                vertical: AppSizes.spacing8,
              ),
              child: isSidebarCollapsed
                  ? Center(
                      child: Icon(
                        icon,
                        color: isSelected
                            ? Theme.of(context).primaryColor
                            : AppColors.textSecondary,
                        size: AppSizes.iconMedium,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          icon,
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : AppColors.textSecondary,
                          size: AppSizes.iconMedium,
                        ),
                        const SizedBox(width: AppSizes.spacing12),
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : AppColors.textPrimary,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
