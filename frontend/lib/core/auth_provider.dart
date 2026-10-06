import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_client.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

class AuthState {
  final bool isLoading;
  final Map<String, dynamic>? currentUser;
  final Map<String, dynamic>? currentTenant;
  final String? token;

  const AuthState({
    this.isLoading = false,
    this.currentUser,
    this.currentTenant,
    this.token,
  });

  bool get isAuthenticated => token != null;
  bool get isSuperAdmin => currentUser != null && currentUser!['role'] == 'SuperAdmin';
  bool get isVendor => currentUser != null && currentUser!['role'] == 'Vendor';

  bool isFeatureEnabled(String featureKey) {
    if (isSuperAdmin) return true;
    if (currentTenant == null) return false;
    final flagsStr = currentTenant!['feature_flags'];
    if (flagsStr == null) return false;
    try {
      Map<String, dynamic> flags;
      if (flagsStr is String) {
        flags = const JsonDecoder().convert(flagsStr) as Map<String, dynamic>;
      } else {
        flags = Map<String, dynamic>.from(flagsStr);
      }
      return flags[featureKey] == true;
    } catch (_) {
      return false;
    }
  }

  AuthState copyWith({
    bool? isLoading,
    Map<String, dynamic>? currentUser,
    Map<String, dynamic>? currentTenant,
    String? token,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      currentUser: currentUser ?? this.currentUser,
      currentTenant: currentTenant ?? this.currentTenant,
      token: token ?? this.token,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Timer? _refreshTimer;

  @override
  AuthState build() {
    _loadToken();
    
    // Auto-refresh token every 12 hours
    ref.onDispose(() => _refreshTimer?.cancel());
    _refreshTimer = Timer.periodic(const Duration(hours: 12), (_) {
      if (state.isAuthenticated) {
        refreshToken();
      }
    });

    return const AuthState();
  }

  Future<void> _loadToken() async {
    try {
      final storedToken = await _storage.read(key: 'auth_token');
      final storedUser = await _storage.read(key: 'current_user');
      if (storedToken != null && storedUser != null) {
        final user = jsonDecode(storedUser) as Map<String, dynamic>;
        state = state.copyWith(
          token: storedToken,
          currentUser: user,
          currentTenant: user['tenant'],
        );
        ref.read(apiClientProvider).setToken(storedToken);
      }
    } catch (e) {
      // Keychain not accessible (macOS entitlement) — start unauthenticated
    }
  }

  Future<void> _saveToken() async {
    try {
      if (state.token != null) {
        await _storage.write(key: 'auth_token', value: state.token);
      }
      if (state.currentUser != null) {
        await _storage.write(key: 'current_user', value: jsonEncode(state.currentUser));
      }
    } catch (e) {
      // Keychain not accessible on macOS without entitlements — skip persisting
    }
  }

  Future<void> _clearToken() async {
    try {
      await _storage.delete(key: 'auth_token');
      await _storage.delete(key: 'current_user');
    } catch (e) {
      // macOS may throw PlatformException(-34018) if Keychain entitlements
      // are missing. Ignore — the in-memory state is already cleared.
    }
  }

  bool isFeatureEnabled(String featureKey) {
    if (state.isSuperAdmin) return true;
    if (state.currentTenant == null) return false;

    final flagsStr = state.currentTenant!['feature_flags'];
    if (flagsStr == null) return false;

    try {
      Map<String, dynamic> flags;
      if (flagsStr is String) {
        flags = jsonDecode(flagsStr) as Map<String, dynamic>;
      } else {
        flags = Map<String, dynamic>.from(flagsStr);
      }
      return flags[featureKey] == true;
    } catch (_) {
      return false;
    }
  }


  Future<void> handleUnauthorized() async {
    state = AuthState(isLoading: false);
    ref.read(apiClientProvider).setToken(null);
    ref.read(apiClientProvider).clearCache();
    await _clearToken();
  }

  Future<void> setSession(String token, Map<String, dynamic> user) async {
    state = state.copyWith(
      token: token,
      currentUser: user,
      currentTenant: user['tenant'],
    );
    ref.read(apiClientProvider).setToken(token);
    await _saveToken();
  }

  Future<void> refreshToken() async {
    if (state.token == null) return;
    try {
      final response = await ref.read(apiClientProvider).post('/auth/refresh', {});
      if (response != null && response['token'] != null) {
        final newToken = response['token'] as String;
        state = state.copyWith(token: newToken);
        ref.read(apiClientProvider).setToken(newToken);
        await _saveToken();
      }
    } catch (e) {
      await handleUnauthorized(); // Token expired or invalid
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ref.read(apiClientProvider).post('/auth/login', {
        'email': email,
        'password': password,
      });
      if (response != null && response['require_2fa'] == true) {
        state = state.copyWith(isLoading: false);
        throw Exception("2FA required");
      }
      final token = response['token'] as String;
      final user = response['user'] as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        token: token,
        currentUser: user,
        currentTenant: user['tenant'],
      );
      ref.read(apiClientProvider).setToken(token);
      await _saveToken();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> loginWith2FA(String email, String password, String totpCode) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ref.read(apiClientProvider).post(
        '/auth/login', 
        {
          'email': email,
          'password': password,
        },
        headers: {'X-TOTP-Code': totpCode},
      );
      final token = response['token'] as String;
      final user = response['user'] as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        token: token,
        currentUser: user,
        currentTenant: user['tenant'],
      );
      ref.read(apiClientProvider).setToken(token);
      await _saveToken();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> signup(
    String companyName,
    String slug,
    String ownerName,
    String email,
    String password,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ref.read(apiClientProvider).post('/auth/signup', {
        'company_name': companyName,
        'slug': slug,
        'owner_name': ownerName,
        'email': email,
        'password': password,
      });
      final token = response['token'] as String;
      final user = response['user'] as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        token: token,
        currentUser: user,
        currentTenant: user['tenant'],
      );
      ref.read(apiClientProvider).setToken(token);
      await _saveToken();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> ssoLogin(String provider, String email) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ref.read(apiClientProvider).post('/auth/sso/$provider', {
        'email': email,
      });
      final token = response['token'] as String;
      final user = response['user'] as Map<String, dynamic>;
      state = state.copyWith(
        isLoading: false,
        token: token,
        currentUser: user,
        currentTenant: user['tenant'],
      );
      ref.read(apiClientProvider).setToken(token);
      await _saveToken();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> logout() async {
    // First, set a temporary loading state so any listener knows state changed
    state = AuthState(isLoading: true);
    ref.read(apiClientProvider).setToken(null);
    ref.read(apiClientProvider).clearCache();
    await _clearToken();
    // Set to definitively unauthenticated — non-const to guarantee Riverpod detects the change
    state = AuthState(isLoading: false, currentUser: null, currentTenant: null, token: null);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(() => AuthNotifier());
