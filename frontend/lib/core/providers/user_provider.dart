import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';

class UserState {
  final bool isLoading;
  final List<dynamic> users;

  const UserState({this.isLoading = false, this.users = const []});

  UserState copyWith({bool? isLoading, List<dynamic>? users}) {
    return UserState(
      isLoading: isLoading ?? this.isLoading,
      users: users ?? this.users,
    );
  }
}

class UserNotifier extends Notifier<UserState> {
  @override
  UserState build() => const UserState();

  Future<void> fetchUsers() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ref.read(apiClientProvider).get('/users');
      state = state.copyWith(
        isLoading: false,
        users: response is List ? response : [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> inviteUser(String name, String email, String role, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).post('/users/invite', {
        'name': name,
        'email': email,
        'role': role,
        'password': password,
      });
      await fetchUsers();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteUser(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).delete('/users/$id');
      await fetchUsers();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> updateUser(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).put('/users/$id', data);
      await fetchUsers();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final userProvider = NotifierProvider<UserNotifier, UserState>(() => UserNotifier());
