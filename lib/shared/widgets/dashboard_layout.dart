import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';

class DashboardLayout extends StatefulWidget {
  final Widget child;
  final String title;
  final String currentRoute;

  const DashboardLayout({
    super.key,
    required this.child,
    required this.title,
    required this.currentRoute,
  });

  @override
  State<DashboardLayout> createState() => _DashboardLayoutState();
}

class _DashboardLayoutState extends State<DashboardLayout> {
  bool _isSidebarCollapsed = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= AppSizes.tabletBreakpoint;
    
    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          if (isDesktop)
            _buildSidebar()
          else
            NavigationRail(
              selectedIndex: _getSelectedIndex(),
              onDestinationSelected: _onDestinationSelected,
              labelType: NavigationRailLabelType.all,
              destinations: _getNavigationDestinations(),
            ),
          
          // Main Content
          Expanded(
            child: Column(
              children: [
                // Top Bar
                _buildTopBar(),
                
                // Content Area
                Expanded(
                  child: Container(
                    color: AppColors.background,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSizes.spacing24),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: AppSizes.maxContentWidth,
                        ),
                        child: widget.child,
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

  Widget _buildSidebar() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: _isSidebarCollapsed 
          ? AppSizes.sidebarCollapsedWidth 
          : AppSizes.sidebarWidth,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          right: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        children: [
          // Logo
          Container(
            height: AppSizes.appBarHeight,
            padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                    ),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
                  ),
                  child: const Icon(Icons.spa, color: AppColors.white, size: 24),
                ),
                if (!_isSidebarCollapsed) ...[
                  const SizedBox(width: AppSizes.spacing12),
                  const Expanded(
                    child: Text(
                      'BellezApp',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.spacing8),
              children: [
                _buildNavItem(
                  icon: Icons.dashboard_outlined,
                  label: 'Dashboard',
                  route: '/dashboard',
                ),
                _buildNavItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Productos',
                  route: '/products',
                ),
                _buildNavItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'Órdenes',
                  route: '/orders',
                ),
                _buildNavItem(
                  icon: Icons.people_outline,
                  label: 'Clientes',
                  route: '/customers',
                ),
                _buildNavItem(
                  icon: Icons.analytics_outlined,
                  label: 'Reportes',
                  route: '/reports',
                ),
              ],
            ),
          ),
          
          // Bottom Actions
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(AppSizes.spacing8),
            child: Column(
              children: [
                if (!_isSidebarCollapsed)
                  ListTile(
                    leading: const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, color: AppColors.white),
                    ),
                    title: const Text('Usuario'),
                    subtitle: const Text('admin@bellezapp.com'),
                    trailing: IconButton(
                      icon: const Icon(Icons.logout),
                      onPressed: () => Get.offAllNamed('/login'),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.person),
                    onPressed: () => Get.offAllNamed('/login'),
                  ),
                IconButton(
                  icon: Icon(_isSidebarCollapsed 
                      ? Icons.chevron_right 
                      : Icons.chevron_left),
                  onPressed: () {
                    setState(() {
                      _isSidebarCollapsed = !_isSidebarCollapsed;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required String route,
  }) {
    final isSelected = widget.currentRoute == route;
    
    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSizes.spacing8,
        vertical: AppSizes.spacing4,
      ),
      child: Material(
        color: isSelected ? AppColors.primaryLight.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: InkWell(
          onTap: () => Get.offAllNamed(route),
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.spacing16,
              vertical: AppSizes.spacing12,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  size: AppSizes.iconLarge,
                ),
                if (!_isSidebarCollapsed) ...[
                  const SizedBox(width: AppSizes.spacing12),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: AppSizes.appBarHeight,
      decoration: const BoxDecoration(
        color: AppColors.white,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.spacing24),
      child: Row(
        children: [
          Text(
            widget.title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          const SizedBox(width: AppSizes.spacing8),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  int _getSelectedIndex() {
    switch (widget.currentRoute) {
      case '/dashboard':
        return 0;
      case '/products':
        return 1;
      case '/orders':
        return 2;
      case '/customers':
        return 3;
      case '/reports':
        return 4;
      default:
        return 0;
    }
  }

  void _onDestinationSelected(int index) {
    final routes = ['/dashboard', '/products', '/orders', '/customers', '/reports'];
    Get.offAllNamed(routes[index]);
  }

  List<NavigationRailDestination> _getNavigationDestinations() {
    return const [
      NavigationRailDestination(
        icon: Icon(Icons.dashboard_outlined),
        label: Text('Dashboard'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.inventory_2_outlined),
        label: Text('Productos'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.receipt_long_outlined),
        label: Text('Órdenes'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.people_outline),
        label: Text('Clientes'),
      ),
      NavigationRailDestination(
        icon: Icon(Icons.analytics_outlined),
        label: Text('Reportes'),
      ),
    ];
  }
}
