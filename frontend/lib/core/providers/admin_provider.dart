import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';

class AdminState {
  final bool isLoading;
  final List<dynamic> tenants;
  final Map<String, dynamic> analytics;
  final List<dynamic> systemHealth;
  final List<dynamic> auditLogs;
  final List<dynamic> globalUsers;
  final List<dynamic> supportTickets;

  const AdminState({
    this.isLoading = false, 
    this.tenants = const [],
    this.analytics = const {'total_mrr': 0.0, 'active_users': 0},
    this.systemHealth = const [],
    this.auditLogs = const [],
    this.globalUsers = const [],
    this.supportTickets = const [],
  });

  AdminState copyWith({
    bool? isLoading, 
    List<dynamic>? tenants, 
    Map<String, dynamic>? analytics,
    List<dynamic>? systemHealth,
    List<dynamic>? auditLogs,
    List<dynamic>? globalUsers,
    List<dynamic>? supportTickets,
  }) {
    return AdminState(
      isLoading: isLoading ?? this.isLoading,
      tenants: tenants ?? this.tenants,
      analytics: analytics ?? this.analytics,
      systemHealth: systemHealth ?? this.systemHealth,
      auditLogs: auditLogs ?? this.auditLogs,
      globalUsers: globalUsers ?? this.globalUsers,
      supportTickets: supportTickets ?? this.supportTickets,
    );
  }
}

class AdminNotifier extends Notifier<AdminState> {
  @override
  AdminState build() => const AdminState();

  Future<void> fetchTenants() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ref.read(apiClientProvider).get('/admin/tenants?page=1&limit=50');
      final analyticsResp = await ref.read(apiClientProvider).get('/admin/analytics');
      final healthResp = await ref.read(apiClientProvider).get('/admin/health');
      final auditResp = await ref.read(apiClientProvider).get('/admin/audit-logs?page=1&limit=50');
      final usersResp = await ref.read(apiClientProvider).get('/admin/users?page=1&limit=50');
      final ticketsResp = await ref.read(apiClientProvider).get('/admin/tickets');
      
      final tenantsData = (response is Map && response['data'] is List) ? response['data'] as List : [];
      final auditData = (auditResp is Map && auditResp['data'] is List) ? auditResp['data'] as List : [];
      final usersData = (usersResp is Map && usersResp['data'] is List) ? usersResp['data'] as List : [];
      final ticketsData = ticketsResp is List ? ticketsResp : [];

      state = state.copyWith(
        isLoading: false,
        tenants: tenantsData,
        analytics: analyticsResp is Map<String, dynamic> ? analyticsResp : {},
        systemHealth: healthResp is List ? healthResp : [],
        auditLogs: auditData,
        globalUsers: usersData,
        supportTickets: ticketsData,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> impersonateTenant(int tenantId, WidgetRef ref) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ref.read(apiClientProvider).post('/admin/tenants/$tenantId/impersonate', {});
      if (response != null && response['token'] != null && response['user'] != null) {
        final token = response['token'] as String;
        final user = response['user'] as Map<String, dynamic>;
        await ref.read(authProvider.notifier).setSession(token, user);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> toggleFeatureFlag(int tenantId, String featureFlagsJson) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).post('/admin/tenants/$tenantId/features', {
        'feature_flags': featureFlagsJson,
      });
      await fetchTenants();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final adminProvider = NotifierProvider<AdminNotifier, AdminState>(() => AdminNotifier());
