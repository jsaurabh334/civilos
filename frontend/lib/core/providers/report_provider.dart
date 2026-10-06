import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';

class ReportState {
  final bool isLoading;
  final Map<String, dynamic>? costReport;
  final Map<String, dynamic>? laborReport;
  final Map<String, dynamic>? machineryReport;
  final String? error;

  const ReportState({
    this.isLoading = false,
    this.costReport,
    this.laborReport,
    this.machineryReport,
    this.error,
  });

  ReportState copyWith({
    bool? isLoading,
    Map<String, dynamic>? costReport,
    Map<String, dynamic>? laborReport,
    Map<String, dynamic>? machineryReport,
    String? error,
    bool clearCost = false,
    bool clearLabor = false,
    bool clearMachinery = false,
  }) {
    return ReportState(
      isLoading: isLoading ?? this.isLoading,
      costReport: clearCost ? null : (costReport ?? this.costReport),
      laborReport: clearLabor ? null : (laborReport ?? this.laborReport),
      machineryReport: clearMachinery ? null : (machineryReport ?? this.machineryReport),
      error: error ?? this.error,
    );
  }
}

class ReportNotifier extends Notifier<ReportState> {
  @override
  ReportState build() => const ReportState();

  Future<void> fetchCostReport({String? year, String? month}) async {
    state = state.copyWith(isLoading: true, clearCost: true);
    try {
      final params = <String, String>{};
      if (year != null) params['year'] = year;
      if (month != null) params['month'] = month;
      final response = await ref.read(apiClientProvider).get('/reports/cost', params: params);
      state = state.copyWith(
        isLoading: false,
        costReport: response is Map ? Map<String, dynamic>.from(response) : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchLaborReport() async {
    state = state.copyWith(isLoading: true, clearLabor: true);
    try {
      final response = await ref.read(apiClientProvider).get('/reports/labor');
      state = state.copyWith(
        isLoading: false,
        laborReport: response is Map ? Map<String, dynamic>.from(response) : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> fetchMachineryReport() async {
    state = state.copyWith(isLoading: true, clearMachinery: true);
    try {
      final response = await ref.read(apiClientProvider).get('/reports/machinery');
      state = state.copyWith(
        isLoading: false,
        machineryReport: response is Map ? Map<String, dynamic>.from(response) : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final reportProvider = NotifierProvider<ReportNotifier, ReportState>(() => ReportNotifier());
