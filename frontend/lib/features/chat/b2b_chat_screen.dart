import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/ws_service.dart';

class B2BChatScreen extends ConsumerStatefulWidget {
  const B2BChatScreen({super.key});

  @override
  ConsumerState<B2BChatScreen> createState() => _B2BChatScreenState();
}

class _B2BChatScreenState extends ConsumerState<B2BChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  WsService? _ws;

  @override
  void initState() {
    super.initState();
    _fetchMessages();
    _connectWS();
  }

  @override
  void dispose() {
    _ws?.disconnect();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _connectWS() {
    final auth = ref.read(authProvider);
    final token = auth.token;
    if (token == null) return;
    _ws = WsService();
    _ws!.connect(
      token: token,
      onMessage: (msg) {
        if (mounted) {
          setState(() {
            _messages = [..._messages, msg];
          });
          _scrollToBottom();
        }
      },
      tenantId: auth.currentTenant?['id'] ?? 0,
    );
  }

  Future<void> _fetchMessages({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      final client = ref.read(apiClientProvider);
      final response = await client.get('/group-chat/');
      if (response is List) {
        setState(() {
          _messages = response;
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _msgController.clear();

    try {
      final client = ref.read(apiClientProvider);
      final response = await client.post('/group-chat/', {'content': text});
      if (response != null) {
        await _fetchMessages(silent: true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final myId = auth.currentUser?['id'];
    final isSuperAdmin = auth.isSuperAdmin;

    return Scaffold(
      backgroundColor: CivilTheme.background,
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
            decoration: BoxDecoration(
              color: CivilTheme.surface,
              border: Border(bottom: BorderSide(color: CivilTheme.border)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3F51B5)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.groups_rounded, color: Colors.white, size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('B2B Network Chat', style: TextStyle(color: CivilTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        const Text('All Contractors + CivilOS Admin', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: CivilTheme.textSecondary),
                  onPressed: () => _fetchMessages(),
                ),
              ],
            ),
          ),

          // Messages
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _messages.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final sender = msg['sender'] as Map<String, dynamic>? ?? {};
                          final senderId = sender['id'];
                          final isMe = senderId == myId;
                          final senderName = sender['name'] ?? 'Unknown';
                          final senderRole = sender['role'] ?? '';
                          final tenantName = (sender['tenant'] as Map<String, dynamic>?)?['name'] ?? 'CivilOS';
                          final isAdmin = senderRole == 'SuperAdmin';

                          return _buildMessageBubble(
                            content: msg['content'] ?? '',
                            senderName: senderName,
                            tenantName: tenantName,
                            isMe: isMe,
                            isAdmin: isAdmin,
                            createdAt: msg['created_at'] ?? '',
                          );
                        },
                      ),
          ),

          // Input Box
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            decoration: BoxDecoration(
              color: CivilTheme.surface,
              border: Border(top: BorderSide(color: CivilTheme.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: InputDecoration(
                      hintText: isSuperAdmin ? 'Broadcast a message to all contractors...' : 'Message the B2B network...',
                      hintStyle: const TextStyle(color: CivilTheme.textSecondary),
                      filled: true,
                      fillColor: CivilTheme.background,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF3F51B5)]),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: _isSending
                        ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)))
                        : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble({
    required String content,
    required String senderName,
    required String tenantName,
    required bool isMe,
    required bool isAdmin,
    required String createdAt,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
              radius: 18,
              backgroundColor: isAdmin ? Colors.purpleAccent : CivilTheme.primary,
              child: Text(senderName.isNotEmpty ? senderName[0].toUpperCase() : '?',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(senderName, style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 6),
                        if (isAdmin)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.purpleAccent.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                            child: const Text('ADMIN', style: TextStyle(color: Colors.purpleAccent, fontSize: 9, fontWeight: FontWeight.bold)),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: CivilTheme.primary.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                            child: Text(tenantName, style: TextStyle(color: CivilTheme.primary, fontSize: 9, fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? (isAdmin ? Colors.purpleAccent.withValues(alpha: 0.8) : CivilTheme.primary.withValues(alpha: 0.85))
                        : CivilTheme.surface,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    border: isMe ? null : Border.all(color: CivilTheme.border),
                  ),
                  child: Text(content, style: TextStyle(color: isMe ? Colors.white : CivilTheme.textPrimary, fontSize: 14)),
                ),
              ],
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: CivilTheme.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.forum_outlined, color: CivilTheme.textSecondary, size: 48),
          ),
          const SizedBox(height: 16),
          const Text('No messages yet', style: TextStyle(color: CivilTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('Be the first to say hello to the B2B network!', style: TextStyle(color: CivilTheme.textSecondary)),
        ],
      ),
    );
  }
}
