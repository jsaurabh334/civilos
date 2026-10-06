import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';

class DashboardState {
  final bool isLoading;
  final Map<String, dynamic>? stats;

  const DashboardState({this.isLoading = false, this.stats});

  DashboardState copyWith({bool? isLoading, Map<String, dynamic>? stats}) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
    );
  }
}

class DashboardNotifier extends Notifier<DashboardState> {
  @override
  DashboardState build() => const DashboardState();

  Future<void> fetchDashboardStats() async {
    try {
      final response = await ref.read(apiClientProvider).get('/dashboard/stats');
      if (response is Map) {
        state = state.copyWith(stats: Map<String, dynamic>.from(response));
      }
    } catch (_) {}
  }
}

final dashboardProvider = NotifierProvider<DashboardNotifier, DashboardState>(() => DashboardNotifier());
