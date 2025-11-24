import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth_provider.dart' as auth_api;

// Estado de autenticación
class AuthState {
  final Map<String, dynamic>? currentUser;
  final bool isLoading;
  final String errorMessage;
  final String token;

  AuthState({
    this.currentUser,
    this.isLoading = false,
    this.errorMessage = '',
    this.token = '',
  });

  bool get isLoggedIn => token.isNotEmpty && currentUser != null;

  // Información del usuario
  String get userFullName {
    if (currentUser == null) return 'Usuario';
    final firstName = currentUser?['firstName'] ?? '';
    final lastName = currentUser?['lastName'] ?? '';
    return '$firstName $lastName'.trim();
  }

  String get userInitials {
    if (currentUser == null) return 'U';
    final firstName = currentUser?['firstName'] ?? '';
    final lastName = currentUser?['lastName'] ?? '';
    String initials = '';
    if (firstName.isNotEmpty) initials += firstName[0].toUpperCase();
    if (lastName.isNotEmpty) initials += lastName[0].toUpperCase();
    return initials.isEmpty ? 'U' : initials;
  }

  String get userRoleDisplay {
    final role = currentUser?['role'];
    switch (role) {
      case 'admin':
        return 'Administrador';
      case 'manager':
        return 'Gerente';
      case 'employee':
        return 'Empleado';
      default:
        return 'Usuario';
    }
  }

  bool get isAdmin => currentUser?['role'] == 'admin';
  bool get isManager => currentUser?['role'] == 'manager';
  bool get isEmployee => currentUser?['role'] == 'employee';
  String? get userRole => currentUser?['role'];

  AuthState copyWith({
    Map<String, dynamic>? currentUser,
    bool? isLoading,
    String? errorMessage,
    String? token,
  }) {
    return AuthState(
      currentUser: currentUser ?? this.currentUser,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      token: token ?? this.token,
    );
  }
}

// Notifier para manejar la lógica de autenticación
class AuthNotifier extends StateNotifier<AuthState> {
  final auth_api.AuthProvider _authProvider = auth_api.AuthProvider();

  AuthNotifier() : super(AuthState()) {
    _loadSavedSession();
  }

  // Cargar sesión guardada
  Future<void> _loadSavedSession() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authProvider.loadToken();

      final prefs = await SharedPreferences.getInstance();
      final savedToken = prefs.getString('auth_token');
      final savedUserData = prefs.getString('user_data');

      if (savedToken != null && savedToken.isNotEmpty) {
        state = state.copyWith(token: savedToken);

        // Si hay datos de usuario guardados, usarlos primero
        if (savedUserData != null && savedUserData.isNotEmpty) {
          try {
            final userData = jsonDecode(savedUserData);
            state = state.copyWith(currentUser: userData);

            // Verificar token en segundo plano
            _verifyTokenInBackground();
            return;
          } catch (e) {
          }
        }

        // Si no hay datos guardados, cargar desde API
        await _loadUserFromAPI();
      }
    } catch (e) {
      await logout();
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  // Cargar usuario desde API
  Future<void> _loadUserFromAPI() async {
    try {
      final result = await _authProvider.getProfile();
      if (result['success']) {
        final userData = result['data'];
        state = state.copyWith(currentUser: userData);
        await _saveUserData(userData);
      } else {
        await logout();
      }
    } catch (e) {
      await logout();
    }
  }

  // Verificar token en segundo plano
  Future<void> _verifyTokenInBackground() async {
    try {
      final result = await _authProvider.getProfile();
      if (!result['success']) {
        await logout();
      }
    } catch (e) {
      // No hacer logout aquí para evitar interrumpir al usuario
    }
  }

  // Guardar datos del usuario
  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(userData));
    } catch (e) {
    }
  }

  // Limpiar datos del usuario
  Future<void> _clearUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_data');
    } catch (e) {
    }
  }

  // Login
  Future<bool> login(String username, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_store_id');

      final result = await _authProvider.login(username, password);

      if (result['success']) {
        final token = result['data']['token'];
        final userData = result['data']['user'];

        state = state.copyWith(
          token: token,
          currentUser: userData,
          isLoading: false,
        );

        await _saveUserData(userData);

        return true;
      } else {
        final errorMsg = result['message'] ?? 'Error en el login';
        state = state.copyWith(isLoading: false, errorMessage: errorMsg);
        return false;
      }
    } catch (e) {
      final errorMsg = 'Error de conexión: $e';
      state = state.copyWith(isLoading: false, errorMessage: errorMsg);
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);

    try {
      await _authProvider.logout();
    } catch (e) {
    }

    try {
      await _clearUserData();
    } catch (e) {
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('selected_store_id');
    } catch (e) {
    }

    // Establecer estado limpio
    state = AuthState();
  }

  // Registrar nuevo usuario
  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? role,
    List<String>? storesToAssign,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _authProvider.register(
        username: username,
        email: email,
        password: password,
        firstName: firstName,
        lastName: lastName,
        role: role ?? 'employee',
        stores: storesToAssign ?? [],
      );

      if (result['success']) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        final errorMsg = result['message'] ?? 'Error creando usuario';
        state = state.copyWith(isLoading: false, errorMessage: errorMsg);
        return false;
      }
    } catch (e) {
      final errorMsg = 'Error de conexión: $e';
      state = state.copyWith(isLoading: false, errorMessage: errorMsg);
      return false;
    }
  }

  // Actualizar usuario existente
  Future<bool> updateUser(Map<String, dynamic> userData) async {
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _authProvider.updateUser(userData);

      if (result['success']) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        final errorMsg = result['message'] ?? 'Error actualizando usuario';
        state = state.copyWith(isLoading: false, errorMessage: errorMsg);
        return false;
      }
    } catch (e) {
      final errorMsg = 'Error de conexión: $e';
      state = state.copyWith(isLoading: false, errorMessage: errorMsg);
      return false;
    }
  }

  // Eliminar usuario
  Future<bool> deleteUser(String userId) async {
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _authProvider.deleteUser(userId);

      if (result['success']) {
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        final errorMsg = result['message'] ?? 'Error eliminando usuario';
        state = state.copyWith(isLoading: false, errorMessage: errorMsg);
        return false;
      }
    } catch (e) {
      final errorMsg = 'Error de conexión: $e';
      state = state.copyWith(isLoading: false, errorMessage: errorMsg);
      return false;
    }
  }

  // Obtener todos los usuarios
  Future<List<Map<String, dynamic>>> getAllUsers() async {
    try {
      final result = await _authProvider.getAllUsers();

      if (result['success']) {
        final data = result['data'];

        if (data is List) {
          return data.map((item) {
            if (item is Map<String, dynamic>) {
              return item;
            } else {
              return Map<String, dynamic>.from(item as Map);
            }
          }).toList();
        } else if (data is Map) {
          if (data.containsKey('users') && data['users'] is List) {
            return List<Map<String, dynamic>>.from(data['users']);
          } else if (data.containsKey('data') && data['data'] is List) {
            return List<Map<String, dynamic>>.from(data['data']);
          } else if (data.containsKey('items') && data['items'] is List) {
            return List<Map<String, dynamic>>.from(data['items']);
          } else {
            return [Map<String, dynamic>.from(data)];
          }
        } else {
          return [];
        }
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: '');
  }
}

// Provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

