import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';

class ChecklistState {
  final bool isLoading;
  final List<dynamic> checklists;
  final String? error;

  const ChecklistState({
    this.isLoading = false,
    this.checklists = const [],
    this.error,
  });

  ChecklistState copyWith({
    bool? isLoading,
    List<dynamic>? checklists,
    String? error,
  }) {
    return ChecklistState(
      isLoading: isLoading ?? this.isLoading,
      checklists: checklists ?? this.checklists,
      error: error ?? this.error,
    );
  }
}

class ChecklistNotifier extends Notifier<ChecklistState> {
  @override
  ChecklistState build() {
    return const ChecklistState();
  }

  Future<void> fetchChecklists() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final res = await ref.read(apiClientProvider).get('/checklists');
      state = state.copyWith(isLoading: false, checklists: res is List ? res : []);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createChecklist(String title, String category, int projectId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await ref.read(apiClientProvider).post('/checklists', {
        'title': title,
        'category': category,
        'project_id': projectId,
      });
      await fetchChecklists();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return false;
    }
  }

  Future<bool> toggleChecklist(int id) async {
    // Optimistic UI update
    final currentChecklists = List.from(state.checklists);
    final index = currentChecklists.indexWhere((c) => c['id'] == id);
    if (index != -1) {
      currentChecklists[index]['completed'] = !(currentChecklists[index]['completed'] ?? false);
      state = state.copyWith(checklists: currentChecklists);
    }
    
    try {
      await ref.read(apiClientProvider).put('/checklists/$id/toggle', {});
      // No need to fetch again if optimistic update worked, but fetching ensures sync
      await fetchChecklists();
      return true;
    } catch (e) {
      // Revert on failure
      await fetchChecklists();
      return false;
    }
  }
}

final checklistProvider = NotifierProvider<ChecklistNotifier, ChecklistState>(ChecklistNotifier.new);
