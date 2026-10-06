import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';

class TaskState {
  final bool isLoading;
  final List<dynamic> tasks;
  final String? error;

  const TaskState({this.isLoading = false, this.tasks = const [], this.error});

  TaskState copyWith({bool? isLoading, List<dynamic>? tasks, String? error}) {
    return TaskState(
      isLoading: isLoading ?? this.isLoading,
      tasks: tasks ?? this.tasks,
      error: error ?? this.error,
    );
  }
}

class TaskNotifier extends Notifier<TaskState> {
  @override
  TaskState build() => const TaskState();

  Future<void> fetchTasks(int projectId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ref.read(apiClientProvider)
          .get('/tasks', params: {'project_id': projectId.toString()});
      state = state.copyWith(
        isLoading: false,
        tasks: response is List ? response : [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> createTask(Map<String, dynamic> data) async {
    try {
      await ref.read(apiClientProvider).post('/tasks', data);
      final pid = data['project_id'];
      if (pid != null) await fetchTasks(pid as int);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> updateTask(int id, Map<String, dynamic> data, int projectId) async {
    try {
      await ref.read(apiClientProvider).put('/tasks/$id', data);
      await fetchTasks(projectId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  Future<bool> deleteTask(int id, int projectId) async {
    try {
      await ref.read(apiClientProvider).delete('/tasks/$id');
      await fetchTasks(projectId);
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final taskProvider = NotifierProvider<TaskNotifier, TaskState>(() => TaskNotifier());
