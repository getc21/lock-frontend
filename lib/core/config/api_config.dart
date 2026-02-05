/// API Configuration for Frontend
/// 
/// Este archivo centraliza la configuración de URL de API
/// Cambia según el ambiente (desarrollo vs producción)

class ApiConfig {
  // Detectar ambiente
  static const String _isDev = String.fromEnvironment('FLUTTER_APP_ENV', defaultValue: 'development');
  
  // Base URL según ambiente
  static String get baseUrl {
    // En desarrollo local
    if (_isDev == 'development') {
      return 'http://localhost:3000';
    }
    
    // En producción
    return 'https://naturalmarkets.net';
  }

  // Endpoints
  static String get authLogin => '$baseUrl/api/auth/login';
  static String get authRegister => '$baseUrl/api/auth/register';
  static String get authLogout => '$baseUrl/api/auth/logout';
  static String get authRefresh => '$baseUrl/api/auth/refresh';

  // Products
  static String get products => '$baseUrl/api/products';
  static String product(String id) => '$baseUrl/api/products/$id';
  
  // Categories
  static String get categories => '$baseUrl/api/categories';
  static String category(String id) => '$baseUrl/api/categories/$id';

  // Suppliers
  static String get suppliers => '$baseUrl/api/suppliers';
  static String supplier(String id) => '$baseUrl/api/suppliers/$id';

  // Orders
  static String get orders => '$baseUrl/api/orders';
  static String order(String id) => '$baseUrl/api/orders/$id';

  // Stores
  static String get stores => '$baseUrl/api/stores';
  static String store(String id) => '$baseUrl/api/stores/$id';

  // Users
  static String get users => '$baseUrl/api/users';
  static String user(String id) => '$baseUrl/api/users/$id';

  // Add more endpoints as needed...

  // Timeout
  static const Duration timeout = Duration(seconds: 30);

  // Headers
  static Map<String, String> get headers => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };
}
