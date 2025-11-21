import 'package:flutter_riverpod/flutter_riverpod.dart';

class UserDetailState {
  final Map<String, dynamic>? user;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const UserDetailState({
    this.user,
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  UserDetailState copyWith({
    Map<String, dynamic>? user,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) =>
      UserDetailState(
        user: user ?? this.user,
        isLoading: isLoading ?? this.isLoading,
        error: error ?? this.error,
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

class UserDetailNotifier extends StateNotifier<UserDetailState> {
  UserDetailNotifier() : super(const UserDetailState());

  Future<void> load(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = {'id': id, 'name': 'User $id'};
      state = state.copyWith(
        user: user,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final userDetailProvider = StateNotifierProvider.family<
    UserDetailNotifier,
    UserDetailState,
    String>(
  (ref, id) => UserDetailNotifier(),
);
