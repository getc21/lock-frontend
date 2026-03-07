import 'package:flutter/foundation.dart' show kIsWeb;

/// Configuración centralizada de la API.
///
/// Contiene la URL base con detección automática dev/prod,
/// y getters tipados para todos los endpoints del backend.
class ApiConfig {
  ApiConfig._();

  // ─── Configuración de entorno ────────────────────────────
  
  /// IP de tu computadora en la red local (para desarrollo móvil).
  static const String _localIP = '192.168.0.48';
  
  /// Puerto del backend (desarrollo local).
  static const String _port = '3000';
  
  /// Modo desarrollo: `true` = apunta a localhost, `false` = producción.
  static const bool _devMode = true;

  /// URL base de producción.
  static const String _prodUrl = 'https://api.naturalmarkets.net/api';

  // ─── URL Base ────────────────────────────────────────────

  /// Detecta automáticamente si estamos en web o dispositivo móvil
  /// y devuelve la URL base correspondiente (dev o prod).
  static String get baseUrl {
    if (kIsWeb) {
      return _devMode ? 'http://localhost:$_port/api' : _prodUrl;
    }
    return _devMode ? 'http://$_localIP:$_port/api' : _prodUrl;
  }

  // ─── Endpoints: Auth ─────────────────────────────────────

  static String get authLogin => '$baseUrl/auth/login';
  static String get authRegister => '$baseUrl/auth/register';
  static String get authLogout => '$baseUrl/auth/logout';
  static String get authRefresh => '$baseUrl/auth/refresh';

  // ─── Endpoints: Products ─────────────────────────────────

  static String get products => '$baseUrl/products';
  static String product(String id) => '$baseUrl/products/$id';
  static String productStock(String id) => '$baseUrl/products/$id/stock';
  static String productStocks(String id) => '$baseUrl/products/$id/stocks';
  static String productSearch(String query) => '$baseUrl/products/search/$query';

  // ─── Endpoints: Categories ───────────────────────────────

  static String get categories => '$baseUrl/categories';
  static String category(String id) => '$baseUrl/categories/$id';

  // ─── Endpoints: Suppliers ────────────────────────────────

  static String get suppliers => '$baseUrl/suppliers';
  static String supplier(String id) => '$baseUrl/suppliers/$id';

  // ─── Endpoints: Orders ───────────────────────────────────

  static String get orders => '$baseUrl/orders';
  static String order(String id) => '$baseUrl/orders/$id';

  // ─── Endpoints: Stores ───────────────────────────────────

  static String get stores => '$baseUrl/stores';
  static String store(String id) => '$baseUrl/stores/$id';

  // ─── Endpoints: Users ────────────────────────────────────

  static String get users => '$baseUrl/users';
  static String user(String id) => '$baseUrl/users/$id';

  // ─── Endpoints: Customers ────────────────────────────────

  static String get customers => '$baseUrl/customers';
  static String customer(String id) => '$baseUrl/customers/$id';

  // ─── Endpoints: Brands ───────────────────────────────────

  static String get brands => '$baseUrl/brands';
  static String brand(String id) => '$baseUrl/brands/$id';

  // ─── Endpoints: Locations ────────────────────────────────

  static String get locations => '$baseUrl/locations';
  static String location(String id) => '$baseUrl/locations/$id';

  // ─── Endpoints: Expenses ─────────────────────────────────

  static String get expenses => '$baseUrl/expenses';
  static String expense(String id) => '$baseUrl/expenses/$id';
  static String get expenseCategories => '$baseUrl/expenses/categories';

  // ─── Endpoints: Quotations ───────────────────────────────

  static String get quotations => '$baseUrl/quotations';
  static String quotation(String id) => '$baseUrl/quotations/$id';

  // ─── Endpoints: Discounts ────────────────────────────────

  static String get discounts => '$baseUrl/discounts';
  static String discount(String id) => '$baseUrl/discounts/$id';

  // ─── Endpoints: Cash Register ────────────────────────────

  static String get cashRegisters => '$baseUrl/cash-register';

  // ─── Endpoints: Reports ──────────────────────────────────

  static String get reports => '$baseUrl/reports';

  // ─── Endpoints: Receipts ─────────────────────────────────

  static String get receipts => '$baseUrl/receipts';

  // ─── Endpoints: Returns ──────────────────────────────────

  static String get returns => '$baseUrl/returns';

  // ─── Config ──────────────────────────────────────────────

  /// Timeout por defecto para peticiones HTTP.
  static const Duration timeout = Duration(seconds: 30);

  /// Headers por defecto para peticiones JSON.
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  /// Devuelve la URL para un modo específico (útil para debugging).
  static String getUrlForMode({required bool useProduction}) {
    return useProduction ? _prodUrl : 'http://$_localIP:$_port/api';
  }

  /// Información de debug del estado de la configuración.
  static Map<String, dynamic> getDebugInfo() {
    return <String, dynamic>{
      'isWeb': kIsWeb,
      'baseUrl': baseUrl,
      'devMode': _devMode,
      'localIP': _localIP,
      'port': _port,
    };
  }
}
