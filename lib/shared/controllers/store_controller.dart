import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/store_provider.dart';
import 'auth_controller.dart';
// Imports de controladores que necesitan refrescarse
import 'product_controller.dart';
import 'order_controller.dart';
import 'customer_controller.dart';
import 'discount_controller.dart';
// import 'cash_controller.dart'; // No disponible en web
// import 'location_controller.dart'; // No disponible en web

class StoreController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  
  StoreProvider get _storeProvider => StoreProvider(_authController.token);

  // Estados observables
  final RxList<Map<String, dynamic>> _stores = <Map<String, dynamic>>[].obs;
  final Rx<Map<String, dynamic>?> _currentStore = Rx<Map<String, dynamic>?>(null);
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  List<Map<String, dynamic>> get stores => _stores;
  List<Map<String, dynamic>> get availableStores => _stores; // Alias para compatibilidad
  Map<String, dynamic>? get currentStore => _currentStore.value;
  Rx<Map<String, dynamic>?> get currentStoreRx => _currentStore; // Para observar cambios
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  bool get isAdmin => _authController.isAdmin;

  @override
  void onInit() {
    super.onInit();
    // No cargar tiendas automáticamente, solo cuando el usuario esté autenticado
    if (_authController.isLoggedIn) {
      loadStores();
    }
  }

  // Cargar tiendas
  Future<void> loadStores() async {
    // Verificar que haya un token antes de intentar cargar
    if (_authController.token.isEmpty) {
      _errorMessage.value = 'No hay sesión activa';
      return;
    }

    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _storeProvider.getStores();

      if (result['success']) {
        _stores.value = List<Map<String, dynamic>>.from(result['data']);
        
        // ⭐ MEJORAR LA SELECCIÓN DE TIENDA
        await _selectInitialStore();
      } else {
        _errorMessage.value = result['message'] ?? 'Error cargando tiendas';
        Get.snackbar(
          'Error',
          _errorMessage.value,
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      _errorMessage.value = 'Error de conexión: $e';
      Get.snackbar(
        'Error',
        _errorMessage.value,
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
    } finally {
      _isLoading.value = false;
    }
  }

  // ⭐ NUEVO MÉTODO PARA SELECCIONAR LA TIENDA INICIAL
  Future<void> _selectInitialStore() async {
    if (_stores.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStoreId = prefs.getString('selected_store_id');
      
      // Intentar restaurar la tienda previamente seleccionada
      if (savedStoreId != null) {
        final savedStore = _stores.firstWhere(
          (store) => store['_id'].toString() == savedStoreId,
          orElse: () => {},
        );
        
        if (savedStore.isNotEmpty) {
          _currentStore.value = savedStore;
          return;
        }
      }
      
      // Si no hay tienda guardada o no se encontró, seleccionar la primera
      _currentStore.value = _stores.first;
      await _saveSelectedStore(_stores.first);
      
    } catch (e) {
      // Fallback: seleccionar la primera tienda
      if (_stores.isNotEmpty) {
        _currentStore.value = _stores.first;
      }
    }
  }

  // ⭐ GUARDAR LA TIENDA SELECCIONADA
  Future<void> _saveSelectedStore(Map<String, dynamic> store) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_store_id', store['_id'].toString());
    } catch (e) {
      if (kDebugMode) {
        print('Error guardando tienda seleccionada: $e');
      }
    }
  }

  // Seleccionar tienda actual
  void selectStore(Map<String, dynamic> store) {
    final previousStore = _currentStore.value;
    _currentStore.value = store;
    
    // ⭐ GUARDAR LA SELECCIÓN AUTOMÁTICAMENTE
    _saveSelectedStore(store);    
    // ⭐ REFRESCAR TODOS LOS DATOS CUANDO CAMBIE LA TIENDA
    if (previousStore?['_id'] != store['_id']) {
      _refreshAllControllersData();
    }
  }

  // ⭐ NUEVO MÉTODO PARA REFRESCAR TODOS LOS CONTROLADORES
  Future<void> _refreshAllControllersData() async {    
    try {
      // Buscar y refrescar controladores que dependen de la tienda
      if (Get.isRegistered<ProductController>()) {
        final productController = Get.find<ProductController>();
        await productController.refreshForStore();
      }
      
      if (Get.isRegistered<OrderController>()) {
        final orderController = Get.find<OrderController>();
        await orderController.refreshForStore();
      }
      
      if (Get.isRegistered<CustomerController>()) {
        final customerController = Get.find<CustomerController>();
        await customerController.refreshForStore();
      }
      
      // CategoryController NO necesita refresh (es global)
      
      if (Get.isRegistered<DiscountController>()) {
        final discountController = Get.find<DiscountController>();
        await discountController.refreshForStore();
      }
      
      // CashController - Sistema de caja (No disponible en web)
      // if (Get.isRegistered<CashController>()) {
      //   final cashController = Get.find<CashController>();
      //   await cashController.refreshForStore();
      // }
      
      // LocationController - Ubicaciones por tienda (No disponible en web)
      // if (Get.isRegistered<LocationController>()) {
      //   final locationController = Get.find<LocationController>();
      //   await locationController.refreshForStore();
      // }
      
      Get.snackbar(
        'Tienda cambiada',
        'Datos actualizados para ${_currentStore.value?['name']}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      
    } catch (e) {
      if (kDebugMode) {
        print('Error refrescando datos para nueva tienda: $e');
      }
    }
  }

  // ⭐ LIMPIAR TIENDAS AL CERRAR SESIÓN
  void clearStores() {
    _stores.clear();
    _currentStore.value = null;
  }

  // Cambiar a otra tienda (alias para compatibilidad)
  Future<void> switchStore(dynamic store) async {
    if (store is Map<String, dynamic>) {
      selectStore(store);
    } else {
      // Si es un objeto Store, convertirlo a Map
      final storeMap = {
        '_id': (store as dynamic).id,
        'name': store.name,
        'address': store.address,
        'phone': store.phone,
        'email': store.email,
        'status': store.status,
        'createdAt': store.createdAt.toIso8601String(),
      };
      selectStore(storeMap);
    }
  }

  // Refrescar lista de tiendas
  Future<void> refreshStores() async {
    await loadStores();
  }

  // Obtener tienda por ID
  Future<Map<String, dynamic>?> getStoreById(String id) async {
    _isLoading.value = true;

    try {
      final result = await _storeProvider.getStoreById(id);

      if (result['success']) {
        return result['data'];
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error obteniendo tienda',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return null;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
      );
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  // Crear tienda (solo admin)
  Future<bool> createStore({
    required String name,
    String? address,
    String? phone,
    String? email,
  }) async {
    if (!_authController.isAdmin) {
      Get.snackbar(
        'Error',
        'No tienes permisos para crear tiendas',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    _isLoading.value = true;

    try {
      final result = await _storeProvider.createStore(
        name: name,
        address: address,
        phone: phone,
        email: email,
      );

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Tienda creada correctamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await loadStores();
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error creando tienda',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Actualizar tienda (solo admin)
  Future<bool> updateStore({
    required String id,
    String? name,
    String? address,
    String? phone,
    String? email,
  }) async {
    if (!_authController.isAdmin) {
      Get.snackbar(
        'Error',
        'No tienes permisos para actualizar tiendas',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    _isLoading.value = true;

    try {
      final result = await _storeProvider.updateStore(
        id: id,
        name: name,
        address: address,
        phone: phone,
        email: email,
      );

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Tienda actualizada correctamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await loadStores();
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error actualizando tienda',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Eliminar tienda (solo admin)
  Future<bool> deleteStore(String id) async {
    if (!_authController.isAdmin) {
      Get.snackbar(
        'Error',
        'No tienes permisos para eliminar tiendas',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }

    _isLoading.value = true;

    try {
      final result = await _storeProvider.deleteStore(id);

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Tienda eliminada correctamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        _stores.removeWhere((s) => s['_id'] == id);
        
        // Si eliminamos la tienda actual, seleccionar otra
        if (_currentStore.value?['_id'] == id && _stores.isNotEmpty) {
          _currentStore.value = _stores.first;
        }
        
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error eliminando tienda',
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Limpiar mensaje de error
  void clearError() {
    _errorMessage.value = '';
  }

  // Asignar usuario a tienda
  Future<bool> assignUserToStore(String userId, String storeId) async {
    try {
      final result = await _storeProvider.assignUserToStore(userId, storeId);

      if (result['success']) {
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error asignando usuario a tienda',
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }

  // Desasignar usuario de tienda
  Future<bool> unassignUserFromStore(String userId, String storeId) async {
    try {
      final result = await _storeProvider.unassignUserFromStore(userId, storeId);

      if (result['success']) {
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error desasignando usuario de tienda',
          snackPosition: SnackPosition.TOP,
        );
        return false;
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Error de conexión: $e',
        snackPosition: SnackPosition.TOP,
      );
      return false;
    }
  }
}
