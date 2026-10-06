import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';

class LaborState {
  final bool isLoading;
  final List<dynamic> workers;
  final List<dynamic> payroll;

  const LaborState({
    this.isLoading = false,
    this.workers = const [],
    this.payroll = const [],
  });

  LaborState copyWith({
    bool? isLoading,
    List<dynamic>? workers,
    List<dynamic>? payroll,
  }) {
    return LaborState(
      isLoading: isLoading ?? this.isLoading,
      workers: workers ?? this.workers,
      payroll: payroll ?? this.payroll,
    );
  }
}

class LaborNotifier extends Notifier<LaborState> {
  @override
  LaborState build() => const LaborState();

  Future<void> fetchWorkers() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ref.read(apiClientProvider).get('/labor');
      state = state.copyWith(
        isLoading: false,
        workers: response is List ? response : [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> createWorker(String name, String skill, double rate) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).post('/labor', {
        'name': name,
        'skill_category': skill,
        'daily_rate': rate,
      });
      await fetchWorkers();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> updateWorker(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).put('/labor/$id', data);
      await fetchWorkers();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteWorker(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).delete('/labor/$id');
      await fetchWorkers();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> recordAttendance(int workerId, String date, String status, double otHours) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).post('/labor/attendance', {
        'labor_worker_id': workerId,
        'date': date,
        'status': status,
        'overtime_hours': otHours,
      });
      await fetchWorkers();
      await fetchPayroll();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> fetchPayroll() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ref.read(apiClientProvider).get('/labor/payroll');
      state = state.copyWith(
        isLoading: false,
        payroll: response is List ? response : [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> markPayrollPaid(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).put('/labor/payroll/$id/pay', {});
      await fetchPayroll();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final laborProvider = NotifierProvider<LaborNotifier, LaborState>(() => LaborNotifier());
