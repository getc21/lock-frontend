import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/cache_service.dart';

class UserListState {
  final List<Map<String, dynamic>> users;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  UserListState({
    this.users = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  UserListState copyWith({
    List<Map<String, dynamic>>? users,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return UserListState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

class UserListNotifier extends StateNotifier<UserListState> {
  final CacheService _cache = CacheService();

  UserListNotifier() : super(UserListState());

  Future<void> loadUsers({bool forceRefresh = false}) async {
    const cacheKey = 'user_list';

    if (!forceRefresh && state.lastUpdated != null) {
      final cachedData = _cache.get<List<Map<String, dynamic>>>(cacheKey);
      if (cachedData != null) {
        state = state.copyWith(users: cachedData);
        return;
      }
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      await Future.delayed(Duration(milliseconds: 500));
      
      final newUsers = <Map<String, dynamic>>[
        {'id': '1', 'name': 'User 1', 'email': 'user1@example.com', 'phone': '1234567890', 'role': 'admin', 'isActive': true, 'avatar': ''},
        {'id': '2', 'name': 'User 2', 'email': 'user2@example.com', 'phone': '0987654321', 'role': 'user', 'isActive': true, 'avatar': ''},
      ];

      _cache.set(
        cacheKey,
        newUsers,
        ttl: const Duration(minutes: 5),
      );

      state = state.copyWith(
        users: newUsers,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void invalidate() {
    _cache.invalidate('user_list');
    state = UserListState();
  }
}

final userListProvider = StateNotifierProvider<UserListNotifier, UserListState>(
  (ref) => UserListNotifier(),
);
