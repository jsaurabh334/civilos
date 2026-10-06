import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';

class AnnouncementState {
  final bool isLoading;
  final List<dynamic> announcements;

  const AnnouncementState({
    this.isLoading = false,
    this.announcements = const [],
  });

  AnnouncementState copyWith({bool? isLoading, List<dynamic>? announcements}) {
    return AnnouncementState(
      isLoading: isLoading ?? this.isLoading,
      announcements: announcements ?? this.announcements,
    );
  }
}

class AnnouncementNotifier extends Notifier<AnnouncementState> {
  @override
  AnnouncementState build() {
    fetchAnnouncements();
    return const AnnouncementState();
  }

  Future<void> fetchAnnouncements() async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ref.read(apiClientProvider).get('/announcements');
      state = state.copyWith(
        isLoading: false,
        announcements: response is List ? response : [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> createAnnouncement(String title, String message, String type) async {
    state = state.copyWith(isLoading: true);
    try {
      await ref.read(apiClientProvider).post('/admin/announcements', {
        'title': title,
        'message': message,
        'type': type,
      });
      await fetchAnnouncements();
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final announcementProvider = NotifierProvider<AnnouncementNotifier, AnnouncementState>(() => AnnouncementNotifier());
