import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../providers/discount_provider.dart';
import 'auth_controller.dart';
import 'store_controller.dart';

class DiscountController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final StoreController _storeController = Get.find<StoreController>();
  
  DiscountProvider get _discountProvider => DiscountProvider(_authController.token);

  // Estados observables
  final RxList<Map<String, dynamic>> _discounts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _filteredDiscounts = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> _applicableDiscounts = <Map<String, dynamic>>[].obs;
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;
  final RxString _searchQuery = ''.obs;

  // Getters
  List<Map<String, dynamic>> get discounts => _discounts;
  List<Map<String, dynamic>> get filteredDiscounts => _filteredDiscounts;
  List<Map<String, dynamic>> get applicableDiscounts => _applicableDiscounts;
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  String get searchQuery => _searchQuery.value;

  @override
  void onInit() {
    super.onInit();
    
    if (Get.isRegistered<StoreController>()) {
    }
    
    loadDiscounts();
    ever(_searchQuery, (_) => filterDiscounts());
  }

  // Filtrar descuentos
  void filterDiscounts() {
    
    if (_searchQuery.value.isEmpty) {
      _filteredDiscounts.value = _discounts;
    } else {
      final query = _searchQuery.value.toLowerCase();
      _filteredDiscounts.value = _discounts.where((discount) {
        final name = discount['name']?.toString().toLowerCase() ?? '';
        final description = discount['description']?.toString().toLowerCase() ?? '';
        return name.contains(query) || description.contains(query);
      }).toList();
    }
  }

  // Buscar descuentos
  void searchDiscounts(String query) {
    _searchQuery.value = query;
  }

  // Limpiar búsqueda
  void clearSearch() {
    _searchQuery.value = '';
  }

  // Toggle estado del descuento
  Future<bool> toggleDiscountStatus(String id) async {
    final discount = _discounts.firstWhere((d) => d['_id'] == id);
    final currentStatus = discount['isActive'] ?? false;
    
    return updateDiscount(
      id: id,
      isActive: !currentStatus,
    );
  }

  // Refrescar lista
  @override
  Future<void> refresh() async {
    await loadDiscounts();
  }

  // ⭐ MÉTODO PARA REFRESCAR CUANDO CAMBIE LA TIENDA
  Future<void> refreshForStore() async {
    await loadDiscounts();
  }

  // ⭐ MÉTODO DE PRUEBA: Cargar TODOS los descuentos sin filtro de tienda
  Future<void> loadAllDiscountsForTesting() async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _discountProvider.getDiscounts(
        active: null,
        storeId: null, // ⭐ SIN FILTRO DE TIENDA
      );


      if (result['success']) {
        final discountsData = List<Map<String, dynamic>>.from(result['data']);
        _discounts.value = discountsData;
        filterDiscounts();
      } else {
        _errorMessage.value = result['message'] ?? 'Error cargando descuentos';
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

  // Actualizar descuentos aplicables según monto total
  void updateApplicableDiscounts(double totalAmount) {
    
    final now = DateTime.now();
    final applicableList = _discounts.where((discount) {
      
      // Verificar si está activo
      if (discount['isActive'] != true) {
        return false;
      }
      
      // Verificar monto mínimo
      final minAmount = discount['minimumAmount'];
      if (minAmount != null && totalAmount < minAmount) {
        return false;
      }
      
      // Verificar fecha de inicio
      final startDateStr = discount['startDate'];
      if (startDateStr != null) {
        final startDate = DateTime.parse(startDateStr);
        if (now.isBefore(startDate)) {
          return false;
        }
      }
      
      // Verificar fecha de fin
      final endDateStr = discount['endDate'];
      if (endDateStr != null) {
        final endDate = DateTime.parse(endDateStr);
        if (now.isAfter(endDate)) {
          return false;
        }
      }
      
      return true;
    }).toList();
    
    _applicableDiscounts.value = applicableList;
  }

  // Cargar descuentos
  Future<void> loadDiscounts({bool? active}) async {
    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      // ⭐ OBTENER EL STORE ID ACTUAL (opcional)
      final currentStoreId = _storeController.currentStore?['_id'];
      
      // ⭐ PERMITIR CARGAR DESCUENTOS INCLUSO SIN TIENDA SELECCIONADA
      final result = await _discountProvider.getDiscounts(
        active: active,
        storeId: currentStoreId, // Puede ser null
      );


      if (result['success']) {
        final discountsData = List<Map<String, dynamic>>.from(result['data']);
        _discounts.value = discountsData;
        filterDiscounts();
      } else {
        _errorMessage.value = result['message'] ?? 'Error cargando descuentos';
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

  // Crear descuento
  Future<bool> createDiscount({
    required String name,
    String? description,
    required String type,
    required double value,
    double? minimumAmount,
    double? maximumDiscount,
    DateTime? startDate,
    DateTime? endDate,
    bool? active,
  }) async {
    _isLoading.value = true;

    try {
      // ⭐ OBTENER EL STORE ID ACTUAL PARA ASIGNAR AL DESCUENTO
      final currentStoreId = _storeController.currentStore?['_id'];
      
      final result = await _discountProvider.createDiscount(
        name: name,
        description: description,
        type: type,
        value: value,
        minimumAmount: minimumAmount,
        maximumDiscount: maximumDiscount,
        startDate: startDate?.toIso8601String(),
        endDate: endDate?.toIso8601String(),
        active: active,
        storeId: currentStoreId, // ⭐ AGREGAR STORE ID
      );


      if (result['success']) {
        Get.snackbar(
          'Éxito', 
          'Descuento creado correctamente', 
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await loadDiscounts();
        return true;
      } else {
        Get.snackbar(
          'Error', 
          result['message'] ?? 'Error creando descuento', 
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

  // Alias para compatibilidad con add_discount_page
  Future<bool> addDiscount({
    required String name,
    required String description,
    required dynamic type,  // Accept DiscountType enum
    required double value,
    double? minimumAmount,
    double? maximumDiscount,
    DateTime? startDate,
    DateTime? endDate,
    required bool isActive,
  }) async {
    
    // Convert DiscountType enum to string if necessary
    final typeStr = type.toString().contains('.') 
        ? type.toString().split('.').last 
        : type.toString();
    
    // ⭐ OBTENER EL STORE ID ACTUAL   
    return createDiscount(
      name: name,
      description: description,
      type: typeStr,
      value: value,
      minimumAmount: minimumAmount,
      maximumDiscount: maximumDiscount,
      startDate: startDate,
      endDate: endDate,
      active: isActive,
    );
  }

  // Actualizar descuento
  Future<bool> updateDiscount({
    required String id,
    String? name,
    String? description,
    dynamic type,  // Accept DiscountType enum or String
    double? value,
    double? minimumAmount,
    double? maximumDiscount,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) async {
    _isLoading.value = true;

    try {
      // Convert DiscountType enum to string if necessary
      String? typeStr;
      if (type != null) {
        typeStr = type.toString().contains('.') 
            ? type.toString().split('.').last 
            : type.toString();
      }


      final result = await _discountProvider.updateDiscount(
        id: id,
        name: name,
        description: description,
        type: typeStr,
        value: value,
        minimumAmount: minimumAmount,
        maximumDiscount: maximumDiscount,
        startDate: startDate?.toIso8601String(),
        endDate: endDate?.toIso8601String(),
        active: isActive,
      );


      if (result['success']) {
        Get.snackbar(
          'Éxito', 
          'Descuento actualizado correctamente', 
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        await loadDiscounts();
        return true;
      } else {
        Get.snackbar(
          'Error', 
          result['message'] ?? 'Error actualizando descuento', 
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

  // Eliminar descuento
  Future<bool> deleteDiscount(String id) async {
    _isLoading.value = true;

    try {
      final result = await _discountProvider.deleteDiscount(id);

      if (result['success']) {
        _discounts.removeWhere((d) => d['_id'] == id);
        // Forzar actualización de filtros
        filterDiscounts();
        
        Get.snackbar(
          'Éxito', 
          'Descuento eliminado correctamente', 
          snackPosition: SnackPosition.TOP,
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );
        return true;
      } else {
        Get.snackbar(
          'Error', 
          result['message'] ?? 'Error eliminando descuento', 
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

  void clearError() {
    _errorMessage.value = '';
  }
}
