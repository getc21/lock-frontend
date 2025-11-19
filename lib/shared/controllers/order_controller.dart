import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../providers/order_provider.dart';
import 'auth_controller.dart';
import 'store_controller.dart';
import 'customer_controller.dart';

class OrderController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final StoreController _storeController = Get.find<StoreController>();
  
  OrderProvider get _orderProvider => OrderProvider(_authController.token);

  // Estados observables
  final RxList<Map<String, dynamic>> _orders = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  List<Map<String, dynamic>> get orders => _orders;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;

  @override
  void onInit() {
    super.onInit();
    if (kDebugMode) {
      print('=== OrderController onInit ===');
      final token = _authController.token;
      print('AuthController token: ${token.isNotEmpty ? token.substring(0, token.length > 20 ? 20 : token.length) : "vacío"}...');
      print('StoreController currentStore: ${_storeController.currentStore?['_id']}');
      print('Is logged in: ${_authController.isLoggedIn}');
    }
    
    // ⭐ NO CARGAR ÓRDENES AUTOMÁTICAMENTE - ESPERAR A QUE SE ESTABLEZCA LA TIENDA
    // Las órdenes se cargarán cuando se establezca currentStore a través del listener
    
    // ⭐ ESCUCHAR CAMBIOS EN LA TIENDA ACTUAL
    ever(_storeController.currentStoreRx, (store) {
      if (kDebugMode) {
        print('🔵 OrderController: Store changed to ${store?['name']}');
      }
      if (store != null && _authController.isLoggedIn) {
        loadOrders(storeId: store['_id']);
      }
    });
  }

  // ⭐ MÉTODO PARA REFRESCAR CUANDO CAMBIE LA TIENDA
  Future<void> refreshForStore() async {
    await loadOrdersForCurrentStore();
  }

  // ⭐ CARGAR ÓRDENES DE LA TIENDA ACTUAL
  Future<void> loadOrdersForCurrentStore() async {
    if (kDebugMode) {
      print('=== loadOrdersForCurrentStore ===');
    }
    final currentStore = _storeController.currentStore;
    if (kDebugMode) {
      print('Current store: $currentStore');
    }
    
    // Siempre cargar por tienda, igual que en versión móvil
    if (currentStore != null) {
      await loadOrders(storeId: currentStore['_id']);
    } else {
      if (kDebugMode) {
        print('No hay tienda seleccionada, limpiando órdenes');
      }
      _orders.clear();
    }
  }

  // Cargar órdenes
  Future<void> loadOrders({
    String? storeId,
    String? customerId,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // ⭐ ASEGURAR QUE SIEMPRE SE USE EL STORE ID ACTUAL
      final effectiveStoreId = storeId ?? _storeController.currentStore?['_id'];
      
      if (kDebugMode) {
        print('=== loadOrders ===');
        print('effectiveStoreId: $effectiveStoreId');
        print('startDate: $startDate, endDate: $endDate');
      }
      
      // ✅ Validar que hay un storeId antes de cargar (igual que móvil)
      if (effectiveStoreId == null) {
        if (kDebugMode) {
          print('No hay storeId, limpiando órdenes');
        }
        _orders.clear();
        return;
      }
      
      if (kDebugMode) {
        print('Llamando a _orderProvider.getOrders');
      }
      
      final result = await _orderProvider.getOrders(
        storeId: effectiveStoreId, // ⭐ Siempre usar storeId
        customerId: customerId,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );

      if (kDebugMode) {
        print('Resultado de getOrders: success=${result['success']}, data length=${(result['data'] as List?)?.length ?? 0}');
      }

      if (result['success']) {
        // ⭐ VALIDAR que todas las órdenes pertenecen a la tienda correcta
        for (final order in List<Map<String, dynamic>>.from(result['data'])) {
          final orderStoreId = order['storeId'];
          if (orderStoreId != effectiveStoreId) {
          }
        }
        
        _orders.value = List<Map<String, dynamic>>.from(result['data']);
      } else {
        _errorMessage.value = result['message'] ?? 'Error cargando órdenes';
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

  // Obtener orden por ID
  Future<Map<String, dynamic>?> getOrderById(String id) async {
    _isLoading.value = true;

    try {
      final result = await _orderProvider.getOrderById(id);

      if (result['success']) {
        return result['data'];
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error obteniendo orden',
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
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return null;
    } finally {
      _isLoading.value = false;
    }
  }

  // Crear orden
  Future<bool> createOrder({
    required String storeId,
    String? customerId,
    required List<Map<String, dynamic>> items,
    required String paymentMethod,
    String? cashRegisterId,
    String? discountId,
  }) async {
    _isLoading.value = true;

    try {
      final result = await _orderProvider.createOrder(
        storeId: storeId,
        customerId: customerId,
        items: items,
        paymentMethod: paymentMethod,
        cashRegisterId: cashRegisterId,
        discountId: discountId,
      );

      if (result['success']) {        
        // Refrescar lista de órdenes
        await loadOrders(storeId: storeId);
        
        // ⭐ Refrescar estadísticas de clientes si hay CustomerController instanciado
        try {
          final customerController = Get.find<CustomerController>();
          await customerController.loadCustomers();
        } catch (e) {
          if (kDebugMode) {
            print('ℹ️ OrderController: CustomerController no está instanciado');
          }
        }
        
        Get.snackbar(
          'Éxito',
          'Orden creada correctamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error creando orden',
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
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Actualizar estado de orden
  Future<bool> updateOrderStatus({
    required String id,
    required String status,
  }) async {
    _isLoading.value = true;

    try {
      final result = await _orderProvider.updateOrderStatus(
        id: id,
        status: status,
      );

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Estado actualizado correctamente',
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await loadOrders();
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error actualizando estado',
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
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return false;
    } finally {
      _isLoading.value = false;
    }
  }

  // Obtener reporte de ventas
  Future<Map<String, dynamic>?> getSalesReport({
    String? storeId,
    String? startDate,
    String? endDate,
    String? groupBy,
  }) async {
    _isLoading.value = true;

    try {
      final result = await _orderProvider.getSalesReport(
        storeId: storeId,
        startDate: startDate,
        endDate: endDate,
        groupBy: groupBy,
      );

      if (result['success']) {
        return result['data'];
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error obteniendo reporte',
          snackPosition: SnackPosition.TOP,
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

  // Eliminar orden
  Future<bool> deleteOrder(String id) async {
    _isLoading.value = true;

    try {
      final result = await _orderProvider.deleteOrder(id);

      if (result['success']) {
        Get.snackbar(
          'Éxito',
          'Orden eliminada correctamente',
          snackPosition: SnackPosition.TOP,
        );
        _orders.removeWhere((o) => o['_id'] == id);
        return true;
      } else {
        Get.snackbar(
          'Error',
          result['message'] ?? 'Error eliminando orden',
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

  // Limpiar órdenes (útil para cambios de tienda)
  void clearOrders() {
    _orders.clear();
  }
}
