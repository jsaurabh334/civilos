import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';

class MachineryState {
  final bool isLoading;
  final List<dynamic> machinery;
  final String? error;

  const MachineryState({this.isLoading = false, this.machinery = const [], this.error});

  MachineryState copyWith({bool? isLoading, List<dynamic>? machinery, String? error}) {
    return MachineryState(
      isLoading: isLoading ?? this.isLoading,
      machinery: machinery ?? this.machinery,
      error: error ?? this.error,
    );
  }
}

class MachineryNotifier extends Notifier<MachineryState> {
  @override
  MachineryState build() => const MachineryState();

  Future<void> fetchMachinery({String? category, String? status}) async {
    state = state.copyWith(isLoading: true);
    try {
      final params = <String, String>{};
      if (category != null && category != 'All') params['category'] = category;
      if (status != null && status != 'All') params['status'] = status;
      final response = await ref.read(apiClientProvider).get('/machinery', params: params);
      state = state.copyWith(
        isLoading: false,
        machinery: response is List ? response : [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> createMachinery(String name, String model, double rate) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).post('/machinery', {
        'name': name,
        'model_number': model,
        'hourly_rate': rate,
      });
      await fetchMachinery();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> updateMachinery(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).put('/machinery/$id', data);
      await fetchMachinery();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> deleteMachinery(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).delete('/machinery/$id');
      await fetchMachinery();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> recordMachineryLog(int macId, String date, double hours, double fuel, String notes) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).post('/machinery/$macId/logs', {
        'date': date,
        'hours_run': hours,
        'fuel_used': fuel,
        'notes': notes,
      });
      await fetchMachinery();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }
}

final machineryProvider = NotifierProvider<MachineryNotifier, MachineryState>(() => MachineryNotifier());
