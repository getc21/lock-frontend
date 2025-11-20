import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../user_provider.dart' as user_api;

class UserState {
  final List<Map<String, dynamic>> users;
  final bool isLoading;
  final String errorMessage;

  UserState({
    this.users = const [],
    this.isLoading = false,
    this.errorMessage = '',
  });

  UserState copyWith({
    List<Map<String, dynamic>>? users,
    bool? isLoading,
    String? errorMessage,
  }) {
    return UserState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class UserNotifier extends StateNotifier<UserState> {
  final Ref ref;

  UserNotifier(this.ref) : super(UserState());

  late user_api.UserProvider _userProvider;

  void _initUserProvider() {
    _userProvider = user_api.UserProvider();
  }

  Future<void> loadUsers() async {
    _initUserProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _userProvider.getUsers();

      if (result['success']) {
        final users = List<Map<String, dynamic>>.from(result['data'] ?? []);
        state = state.copyWith(users: users);
      } else {
        state = state.copyWith(
          errorMessage: result['message'] ?? 'Error cargando usuarios',
        );
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error de conexión: $e',
      );
    }
    
    state = state.copyWith(isLoading: false);
  }

  Future<Map<String, dynamic>?> getUserById(String id) async {
    _initUserProvider();

    try {
      final result = await _userProvider.getUserById(id);

      if (result['success']) {
        return result['data'];
      } else {
        state = state.copyWith(
          errorMessage: result['message'] ?? 'Error obteniendo usuario',
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Error de conexión: $e',
      );
      return null;
    }
  }

  Future<bool> createUser({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String role,
  }) async {
    _initUserProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _userProvider.createUser(
        username,
        firstName,
        lastName,
        email,
        password,
        role,
      );

      if (result['success']) {
        await loadUsers();
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error creando usuario',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error de conexión: $e',
      );
      return false;
    }
  }

  Future<bool> updateUser({
    required String id,
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String role,
    String? password,
  }) async {
    _initUserProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _userProvider.updateUser(
        id,
        username,
        firstName,
        lastName,
        email,
        role,
        password,
      );

      if (result['success']) {
        await loadUsers();
        state = state.copyWith(isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error actualizando usuario',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error de conexión: $e',
      );
      return false;
    }
  }

  Future<bool> deleteUser(String id) async {
    _initUserProvider();
    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final result = await _userProvider.deleteUser(id);

      if (result['success']) {
        state = state.copyWith(
          users: state.users.where((u) => u['_id'] != id).toList(),
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: result['message'] ?? 'Error eliminando usuario',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error de conexión: $e',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: '');
  }

  void clearUsers() {
    state = UserState();
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  return UserNotifier(ref);
});
