import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';

class InspectionState {
  final bool isLoading;
  final List<dynamic> inspections;
  final String? error;

  const InspectionState({
    this.isLoading = false,
    this.inspections = const [],
    this.error,
  });

  InspectionState copyWith({
    bool? isLoading,
    List<dynamic>? inspections,
    String? error,
  }) {
    return InspectionState(
      isLoading: isLoading ?? this.isLoading,
      inspections: inspections ?? this.inspections,
      error: error ?? this.error,
    );
  }
}

class InspectionNotifier extends Notifier<InspectionState> {
  @override
  InspectionState build() {
    return const InspectionState();
  }

  Future<void> fetchInspections() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ref.read(apiClientProvider).get('/inspections');
      state = state.copyWith(isLoading: false, inspections: res is List ? res : []);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createInspection(String title, String description, int projectId, String dateStr) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(apiClientProvider).post('/inspections', {
        'title': title,
        'description': description,
        'project_id': projectId,
        'date': dateStr,
      });
      await fetchInspections();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> deleteInspection(int id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(apiClientProvider).delete('/inspections/$id');
      await fetchInspections();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }
}

final inspectionProvider = NotifierProvider<InspectionNotifier, InspectionState>(InspectionNotifier.new);
