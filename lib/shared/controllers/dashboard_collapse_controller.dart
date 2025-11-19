import 'package:get/get.dart';

/// Controlador para manejar el estado de colapso del sidebar del dashboard.
/// Esto evita reconstrucciones innecesarias del layout completo cuando solo
/// cambia el estado del sidebar.
class DashboardCollapseController extends GetxController {
  /// Indica si el sidebar está colapsado
  final RxBool isSidebarCollapsed = false.obs;

  /// Toggle del estado del sidebar
  void toggleSidebar() {
    isSidebarCollapsed.value = !isSidebarCollapsed.value;
    print('✅ DRAWER TOGGLED - Collapsed: ${isSidebarCollapsed.value}');
  }

  /// Colapsar el sidebar
  void collapseSidebar() {
    isSidebarCollapsed.value = true;
    print('✅ DRAWER COLLAPSED');
  }

  /// Expandir el sidebar
  void expandSidebar() {
    isSidebarCollapsed.value = false;
    print('✅ DRAWER EXPANDED');
  }
}
