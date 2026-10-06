import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';

class CurrentProjectNotifier extends Notifier<Map<String, dynamic>?> {
  @override
  Map<String, dynamic>? build() => null;
  void setProject(Map<String, dynamic>? project) => state = project;
}

final currentProjectProvider = NotifierProvider<CurrentProjectNotifier, Map<String, dynamic>?>(CurrentProjectNotifier.new);

class ProjectState {
  final bool isLoading;
  final List<dynamic> projects;
  final List<dynamic> diaries;

  final int currentPage;
  final bool hasMore;

  const ProjectState({
    this.isLoading = false,
    this.projects = const [],
    this.diaries = const [],
    this.currentPage = 1,
    this.hasMore = true,
  });

  ProjectState copyWith({
    bool? isLoading,
    List<dynamic>? projects,
    List<dynamic>? diaries,
    int? currentPage,
    bool? hasMore,
  }) {
    return ProjectState(
      isLoading: isLoading ?? this.isLoading,
      projects: projects ?? this.projects,
      diaries: diaries ?? this.diaries,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class ProjectNotifier extends Notifier<ProjectState> {
  @override
  ProjectState build() => const ProjectState();

  Future<void> fetchProjects({int page = 1, int limit = 20, bool append = false}) async {
    if (page == 1 && !append) {
       state = state.copyWith(isLoading: true, currentPage: 1, hasMore: true);
    } else {
       state = state.copyWith(isLoading: true);
    }
    try {
      final response = await ref.read(apiClientProvider).get('/projects?page=$page&limit=$limit');
      final newProjects = response is List ? response : [];
      state = state.copyWith(
        isLoading: false,
        projects: append ? [...state.projects, ...newProjects] : newProjects,
        currentPage: page,
        hasMore: newProjects.length == limit,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> createProject(
    String name,
    String description,
    String location,
    String projectType,
    String tenderNo,
    String tenderDetails,
    List<Map<String, dynamic>> boqItems,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).post('/projects', {
        'name': name,
        'description': description,
        'location': location,
        'project_type': projectType,
        'tender_no': tenderNo,
        'tender_details': tenderDetails,
        'boq_items': boqItems,
      });
      await fetchProjects();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> fetchProjectStats(int projectId) async {
    try {
      final response = await ref.read(apiClientProvider).get('/projects/$projectId/stats');
      return response as Map<String, dynamic>;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateProject(int id, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).put('/projects/$id', data);
      await fetchProjects();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteProject(int id) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).delete('/projects/$id');
      await fetchProjects();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> importBOQ(int projectId, List<Map<String, dynamic>> items) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).post('/projects/$projectId/boq/import', {
        'items': items,
      });
      await fetchProjects();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<List<dynamic>> fetchDiaries(int projectId) async {
    try {
      final response = await ref.read(apiClientProvider).get('/projects/$projectId/diaries');
      final list = response is List ? response : [];
      state = state.copyWith(diaries: list);
      return list;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> submitDiary(
    int projectId,
    String date,
    String weather,
    int laborStrength,
    String completedWork,
  ) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).post('/projects/$projectId/diaries', {
        'date': date,
        'weather': weather,
        'labor_strength': laborStrength,
        'completed_work': completedWork,
      });
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> updateDiary(int diaryId, Map<String, dynamic> data) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).put('/projects/${data['project_id']}/diaries/$diaryId', data);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteDiary(int projectId, int diaryId) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).delete('/projects/$projectId/diaries/$diaryId');
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> approveDiary(int diaryId) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).post('/diaries/$diaryId/approve', {});
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final projectProvider = NotifierProvider<ProjectNotifier, ProjectState>(() => ProjectNotifier());
