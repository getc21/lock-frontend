import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../providers/reports_provider.dart';
import 'auth_controller.dart';
import 'store_controller.dart';

class ReportsController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();
  final StoreController _storeController = Get.find<StoreController>();

  ReportsProvider get _reportsProvider =>
      ReportsProvider(_authController.token);

  // Estados observables
  final RxBool _isLoading = false.obs;
  final RxString _errorMessage = ''.obs;

  // Datos de reportes
  final RxMap<String, dynamic> _inventoryRotationData = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> _profitabilityData = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> _salesTrendsData = <String, dynamic>{}.obs;
  final RxMap<String, dynamic> _periodsComparisonData = <String, dynamic>{}.obs;

  // Getters
  bool get isLoading => _isLoading.value;
  String get errorMessage => _errorMessage.value;
  Map<String, dynamic> get inventoryRotationData => _inventoryRotationData;
  Map<String, dynamic> get profitabilityData => _profitabilityData;
  Map<String, dynamic> get salesTrendsData => _salesTrendsData;
  Map<String, dynamic> get periodsComparisonData => _periodsComparisonData;

  @override
  void onInit() {
    super.onInit();

    if (Get.isRegistered<StoreController>()) {
      final storeController = Get.find<StoreController>();
      if (kDebugMode) {
        print(
          'ReportsController.onInit - Current store: ${storeController.currentStore}',
        );
      }
    }
  }

  // Obtener ID de tienda actual
  String? get _currentStoreId {
    final currentStore = _storeController.currentStore;
    return currentStore?['_id'] ?? currentStore?['id'];
  }

  // 📦 Cargar análisis de rotación de inventario
  Future<void> loadInventoryRotationAnalysis({
    required String startDate,
    required String endDate,
    String period = 'monthly',
  }) async {
    final storeId = _currentStoreId;
    if (storeId == null) {
      _errorMessage.value = 'No hay tienda seleccionada';
      return;
    }

    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _reportsProvider.getInventoryRotationAnalysis(
        storeId: storeId,
        startDate: startDate,
        endDate: endDate,
        period: period,
      );

      if (result['success']) {
        _inventoryRotationData.value = result['data'];
      } else {
        _errorMessage.value = result['message'];
      }
    } catch (e) {
      _errorMessage.value = 'Error de conexión: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  // 💰 Cargar análisis de rentabilidad
  Future<void> loadProfitabilityAnalysis({
    required String startDate,
    required String endDate,
  }) async {
    final storeId = _currentStoreId;
    if (storeId == null) {
      _errorMessage.value = 'No hay tienda seleccionada';
      return;
    }

    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _reportsProvider.getProfitabilityAnalysis(
        storeId: storeId,
        startDate: startDate,
        endDate: endDate,
      );

      if (result['success']) {
        _profitabilityData.value = result['data'];
      } else {
        _errorMessage.value = result['message'];
      }
    } catch (e) {
      _errorMessage.value = 'Error de conexión: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  // 📈 Cargar análisis de tendencias
  Future<void> loadSalesTrendsAnalysis({
    required String startDate,
    required String endDate,
    String period = 'daily',
  }) async {
    final storeId = _currentStoreId;
    if (storeId == null) {
      _errorMessage.value = 'No hay tienda seleccionada';
      return;
    }

    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _reportsProvider.getSalesTrendsAnalysis(
        storeId: storeId,
        startDate: startDate,
        endDate: endDate,
        period: period,
      );

      if (result['success']) {
        _salesTrendsData.value = result['data'];
      } else {
        _errorMessage.value = result['message'];
      }
    } catch (e) {
      _errorMessage.value = 'Error de conexión: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  // 🔄 Cargar comparación de períodos
  Future<void> loadPeriodsComparison({
    required String currentStartDate,
    required String currentEndDate,
    required String previousStartDate,
    required String previousEndDate,
  }) async {
    final storeId = _currentStoreId;
    if (storeId == null) {
      _errorMessage.value = 'No hay tienda seleccionada';
      return;
    }

    _isLoading.value = true;
    _errorMessage.value = '';

    try {
      final result = await _reportsProvider.getPeriodsComparison(
        storeId: storeId,
        currentStartDate: currentStartDate,
        currentEndDate: currentEndDate,
        previousStartDate: previousStartDate,
        previousEndDate: previousEndDate,
      );

      if (result['success']) {
        _periodsComparisonData.value = result['data'];
      } else {
        _errorMessage.value = result['message'];
      }
    } catch (e) {
      _errorMessage.value = 'Error de conexión: $e';
    } finally {
      _isLoading.value = false;
    }
  }

  // Limpiar datos
  void clearData() {
    _inventoryRotationData.clear();
    _profitabilityData.clear();
    _salesTrendsData.clear();
    _periodsComparisonData.clear();
    _errorMessage.value = '';
  }

  // Refrescar para nueva tienda
  Future<void> refreshForStore() async {
    clearData();
    // Los datos se cargarán cuando el usuario navegue a las páginas específicas
  }
}
