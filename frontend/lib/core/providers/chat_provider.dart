import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth_provider.dart';
import '../ws_service.dart';

class ChatState {
  final bool isLoading;
  final List<dynamic> messages;

  const ChatState({this.isLoading = false, this.messages = const []});

  ChatState copyWith({bool? isLoading, List<dynamic>? messages}) {
    return ChatState(
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
    );
  }
}

class ChatNotifier extends Notifier<ChatState> {
  WsService? _ws;

  @override
  ChatState build() {
    ref.onDispose(() {
      _ws?.disconnect();
    });
    return const ChatState();
  }

  void _onWSMessage(Map<String, dynamic> msg) {
    final updated = [...state.messages, msg];
    state = state.copyWith(messages: updated);
  }

  void connectWS() {
    final auth = ref.read(authProvider);
    final token = auth.token;
    if (token == null || _ws != null) return;

    _ws = WsService();
    _ws!.connect(
      token: token,
      onMessage: _onWSMessage,
      tenantId: auth.currentTenant?['id'] ?? 0,
    );
  }

  void disconnectWS() {
    _ws?.disconnect();
    _ws = null;
  }

  Future<void> fetchMessages(int receiverId) async {
    state = state.copyWith(isLoading: true);
    try {
      final response = await ref.read(apiClientProvider).get('/chat/$receiverId');
      state = state.copyWith(
        isLoading: false,
        messages: response is List ? response : [],
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> sendMessage(int receiverId, String content, {String? attachment}) async {
    state = state.copyWith(isLoading: true);
    try {
      final body = <String, dynamic>{
        'receiver_id': receiverId,
        'content': content,
      };
      if (attachment != null) {
        body['attachment'] = attachment;
      }
      await ref.read(apiClientProvider).post('/chat', body);
      await fetchMessages(receiverId);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(() => ChatNotifier());
