import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../providers/riverpod/auth_notifier.dart';
import '../providers/riverpod/store_notifier.dart';

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
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ref.read(authProvider.notifier).logout();
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDesktop = MediaQuery.of(context).size.width >= AppSizes.tabletBreakpoint;
    final isSidebarCollapsed = ref.watch(dashboardCollapseProvider);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          if (isDesktop)
            _buildSidebar(context, ref, isSidebarCollapsed)
          else
            NavigationRail(
              selectedIndex: _getSelectedIndex(),
              onDestinationSelected: (index) => _onDestinationSelected(index),
              labelType: NavigationRailLabelType.all,
              destinations: _getNavigationDestinations(ref),
            ),
          
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
                          Theme.of(context).primaryColor.withOpacity(0.03),
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

  Widget _buildSidebar(BuildContext context, WidgetRef ref, bool isSidebarCollapsed) {
    final authState = ref.watch(authProvider);
    final isAdmin = authState.currentUser?['role'] == 'admin';
    
    return _SidebarWidget(
      isAdmin: isAdmin,
      currentRoute: currentRoute,
      isSidebarCollapsed: isSidebarCollapsed,
      onToggle: () {
        ref.read(dashboardCollapseProvider.notifier).state = !isSidebarCollapsed;
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
            Theme.of(context).primaryColor.withOpacity(0.08),
          ],
        ),
        border: const Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing24),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSizes.spacing24),
          
          // ⭐ SELECTOR DE TIENDA - SOLO PARA ADMINISTRADORES
          if (isAdmin && storeState.stores.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing12,
                vertical: AppSizes.spacing4,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
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
                  DropdownButton<String>(
                    value: storeState.currentStore?['_id'],
                    underline: const SizedBox(),
                    isDense: true,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                    items: storeState.stores.map((store) {
                      return DropdownMenuItem<String>(
                        value: store['_id'],
                        child: Text(store['name'] ?? 'Sin nombre'),
                      );
                    }).toList(),
                    onChanged: (storeId) {
                      if (storeId != null) {
                        final store = storeState.stores.firstWhere(
                          (s) => s['_id'] == storeId,
                        );
                        ref.read(storeProvider.notifier).selectStore(store);
                      }
                    },
                  ),
                ],
              ),
            )
          else if (!isAdmin && storeState.currentStore != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.spacing12,
                vertical: AppSizes.spacing8,
              ),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
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

  int _getSelectedIndex() {
    switch (currentRoute) {
      case '/dashboard':
        return 0;
      case '/products':
        return 1;
      case '/categories':
        return 2;
      case '/suppliers':
        return 3;
      case '/locations':
        return 4;
      case '/orders':
        return 5;
      case '/customers':
        return 6;
      case '/stores':
        return 7;
      case '/users':
        return 8;
      case '/reports':
        return 9;
      default:
        return 0;
    }
  }

  void _onDestinationSelected(int index) {
    final List<String> routes = [
      '/dashboard',
      '/products',
      '/categories',
      '/suppliers',
      '/locations',
      '/orders',
      '/customers',
      '/stores',
      '/users',
      '/reports',
    ];
    
    if (index >= 0 && index < routes.length) {
      // Note: This will be handled by the page routing system
      // The Navigator should be called from the pages themselves
    }
  }

  List<NavigationRailDestination> _getNavigationDestinations(WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isAdmin = authState.currentUser?['role'] == 'admin';
    
    final List<NavigationRailDestination> destinations = [
      const NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        label: Text('Dashboard'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.inventory_2_outlined),
        label: Text('Productos'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.category_outlined),
        label: Text('Categorías'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.local_shipping_outlined),
        label: Text('Proveedores'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.location_on_outlined),
        label: Text('Ubicaciones'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.receipt_long_outlined),
        label: Text('Órdenes'),
      ),
      const NavigationRailDestination(
        icon: Icon(Icons.people_outline),
        label: Text('Clientes'),
      ),
    ];
    
    if (isAdmin) {
      destinations.addAll([
        const NavigationRailDestination(
          icon: Icon(Icons.store_outlined),
          label: Text('Tiendas'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.person_outline),
          label: Text('Usuarios'),
        ),
        const NavigationRailDestination(
          icon: Icon(Icons.analytics_outlined),
          label: Text('Reportes'),
        ),
      ]);
    }
    
    return destinations;
  }
}

// ============================================================================
// WIDGET AISLADO PARA EL SIDEBAR
// ============================================================================

class _SidebarWidget extends StatelessWidget {
  final bool isAdmin;
  final String currentRoute;
  final bool isSidebarCollapsed;
  final VoidCallback onToggle;

  const _SidebarWidget({
    required this.isAdmin,
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
          border: Border(
            right: BorderSide(color: AppColors.border),
          ),
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
                  border: Border(
                    bottom: BorderSide(color: AppColors.border),
                  ),
                ),
                child: isSidebarCollapsed
                    ? Center(
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Theme.of(context).primaryColor,
                                Theme.of(context).colorScheme.secondary
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                                AppSizes.radiusMedium),
                          ),
                          child: const Icon(Icons.spa,
                              color: AppColors.white, size: 20),
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
                                gradient: LinearGradient(
                                  colors: [
                                    Theme.of(context).primaryColor,
                                    Theme.of(context).colorScheme.secondary
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(
                                    AppSizes.radiusMedium),
                              ),
                              child: const Icon(Icons.spa,
                                  color: AppColors.white, size: 20),
                            ),
                            const SizedBox(width: AppSizes.spacing12),
                            const Text(
                              'BellezApp',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
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
                      label: 'Órdenes',
                      route: '/orders',
                      isSidebarCollapsed: isSidebarCollapsed,
                    ),
                    _buildNavItem(
                      context: context,
                      icon: Icons.people_outline,
                      label: 'Clientes',
                      route: '/customers',
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
              // Botón de Configurar Temas
              Container(
                margin: EdgeInsets.symmetric(
                  horizontal: isSidebarCollapsed ? AppSizes.spacing4 : AppSizes.spacing8,
                  vertical: AppSizes.spacing4,
                ),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  child: InkWell(
                    onTap: () => context.go('/settings/theme'),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSidebarCollapsed ? AppSizes.spacing4 : AppSizes.spacing16,
                        vertical: AppSizes.spacing8,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.palette_outlined,
                              size: 20,
                              color: Theme.of(context).primaryColor,
                            ),
                            if (!isSidebarCollapsed) ...[
                              const SizedBox(width: AppSizes.spacing12),
                              const Text(
                                'Temas',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Botón de colapsar
              Padding(
                padding: const EdgeInsets.all(AppSizes.spacing8),
                child: IconButton(
                  icon: Icon(isSidebarCollapsed
                      ? Icons.chevron_right
                      : Icons.chevron_left),
                  onPressed: onToggle,
                  tooltip: isSidebarCollapsed
                      ? 'Expandir menú'
                      : 'Colapsar menú',
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
            ? Theme.of(context).primaryColor.withOpacity(0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: InkWell(
          onTap: () => context.go(route),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isSidebarCollapsed ? AppSizes.spacing4 : AppSizes.spacing16,
              vertical: AppSizes.spacing8,
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
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
                  if (!isSidebarCollapsed) ...[
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
