import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';

class ProfileState {
  final bool isLoading;

  const ProfileState({this.isLoading = false});

  ProfileState copyWith({bool? isLoading}) {
    return ProfileState(isLoading: isLoading ?? this.isLoading);
  }
}

class ProfileNotifier extends Notifier<ProfileState> {
  @override
  ProfileState build() => const ProfileState();

  Future<void> updateProfile(String name, String phone, {String? avatarUrl}) async {
    state = state.copyWith(isLoading: true);
    try {
      final body = <String, dynamic>{
        'name': name,
        'phone': phone,
      };
      if (avatarUrl != null) body['avatar_url'] = avatarUrl;
      await ref.read(apiClientProvider).put('/auth/profile', body);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> changePassword(String currentPassword, String newPassword) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).put('/auth/password', {
        'current_password': currentPassword,
        'new_password': newPassword,
      });
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).post('/auth/forgot-password', {
        'email': email,
      });
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> resetPassword(String token, String newPassword) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).post('/auth/reset-password', {
        'token': token,
        'new_password': newPassword,
      });
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, ProfileState>(() => ProfileNotifier());
