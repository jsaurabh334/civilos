import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/auth_provider.dart';
import '../../core/api_client.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/theme.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final int receiverId;
  const ChatScreen({super.key, required this.receiverId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;
  String _receiverName = 'User';
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _fetchReceiverName();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).connectWS();
      ref.read(chatProvider.notifier).fetchMessages(widget.receiverId);
    });
  }

  Future<void> _fetchReceiverName() async {
    try {
      final response = await ref.read(apiClientProvider).get('/users/${widget.receiverId}');
      if (response is Map) {
        final name = response['name'] ?? response['display_name'] ?? response['email'];
        if (name != null) {
          setState(() => _receiverName = name.toString());
        }
      }
    } catch (_) {}
    setState(() => _isLoadingUser = false);
  }

  String _resolveReceiverName(List<dynamic> messages) {
    if (_receiverName.isNotEmpty) return _receiverName;
    final currentUserId = ref.read(authProvider).currentUser?['id'];
    for (final msg in messages) {
      if (msg['sender_id'] != currentUserId && msg['sender_name'] != null) {
        _receiverName = msg['sender_name'];
        return _receiverName;
      }
    }
    return 'Chat';
  }

  @override
  void dispose() {
    ref.read(chatProvider.notifier).disconnectWS();
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _pickAndSendFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result == null || result.files.isEmpty) return;
    final file = result.files.first;
    final bytes = file.bytes ?? (file.path != null ? await File(file.path!).readAsBytes() : null);
    if (bytes == null) return;

    try {
      final response = await ref.read(apiClientProvider).uploadFile('/upload', 'file', bytes, file.name);
      final fileUrl = response['url'] ?? '';
      await ref.read(chatProvider.notifier).sendMessage(widget.receiverId, '📎 ${file.name}', attachment: fileUrl);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Future<void> _captureAndSendPhoto() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;
    final bytes = await photo.readAsBytes();

    try {
      final response = await ref.read(apiClientProvider).uploadFile('/upload', 'file', bytes, photo.name);
      final fileUrl = response['url'] ?? '';
      await ref.read(chatProvider.notifier).sendMessage(widget.receiverId, '📷 Photo', attachment: fileUrl);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _msgController.clear();

    try {
      await ref.read(chatProvider.notifier).sendMessage(widget.receiverId, text);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send: $e')),
        );
      }
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final rawMessages = chatState.messages;

    final List<dynamic> displayMessages = rawMessages;
    final headerName = _resolveReceiverName(displayMessages);

    return Scaffold(
      backgroundColor: CivilTheme.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;
          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF222B38), Color(0xFF161F2E)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isMobile ? 600 : 800),
                  child: Column(
                    children: [
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: CivilTheme.surface.withValues(alpha: 0.4),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1)),
                              boxShadow: [
                                BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10)
                              ],
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(headerName,
                                          style: const TextStyle(
                                              color: CivilTheme.textPrimary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                    icon: const Icon(Icons.phone_outlined,
                                        color: CivilTheme.textSecondary),
                                    onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use your device dialer to call the site supervisor'), backgroundColor: CivilTheme.primary)); }),
                                IconButton(
                                    icon: const Icon(Icons.search,
                                        color: CivilTheme.textSecondary),
                                    onPressed: () { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Search messages'), backgroundColor: CivilTheme.primary)); }),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: displayMessages.length,
                          itemBuilder: (context, index) {
                            final msg = displayMessages[index];
                            final currentUserId = ref.watch(authProvider).currentUser?['id'];
                            final isMe = msg['sender_id'] == currentUserId;
                            return _buildMessageBubble(msg, isMe);
                          },
                        ),
                      ),
                      SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: CivilTheme.surface.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _msgController,
                                    style: const TextStyle(
                                        color: CivilTheme.textPrimary),
                                    decoration: const InputDecoration(
                                      hintText: 'Type message...',
                                      hintStyle: TextStyle(
                                          color: CivilTheme.textSecondary),
                                      border: InputBorder.none,
                                    ),
                                  ),
                                ),
                                IconButton(
                                    icon: const Icon(Icons.attach_file,
                                        color: CivilTheme.textSecondary),
                                    onPressed: _pickAndSendFile),
                                IconButton(
                                    icon: const Icon(Icons.camera_alt_outlined,
                                        color: CivilTheme.textSecondary),
                                    onPressed: _captureAndSendPhoto),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: _sendMessage,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: const BoxDecoration(
                                        color: Colors.blueAccent,
                                        shape: BoxShape.circle),
                                    child: const Icon(Icons.arrow_forward,
                                        color: Colors.white, size: 20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isMe) {
    String timeText = '';
    if (msg['created_at'] != null) {
      try {
        timeText = msg['created_at'].split('T')[1].substring(0, 5);
      } catch (_) {}
    }

    final hasAttachment = msg['attachment'] != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMe) ...[
            CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey.shade800,
                child: Text(msg['avatar'] ?? 'U',
                    style: const TextStyle(color: Colors.white, fontSize: 12))),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color(0xFF1B3252).withValues(alpha: 0.8)
                    : CivilTheme.surface.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isMe
                        ? Colors.blueAccent.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isMe || msg['sender_name'] != null) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(msg['sender_name'] ?? 'User',
                            style: const TextStyle(
                                color: CivilTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        if (msg['role'] != null)
                          Text(' (${msg['role']})',
                              style: const TextStyle(
                                  color: CivilTheme.textSecondary,
                                  fontSize: 12)),
                        const Text(':',
                            style: TextStyle(color: CivilTheme.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                  ],
                  if (hasAttachment) ...[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4)),
                          child: const Text('PDF',
                              style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10)),
                        ),
                        const SizedBox(width: 8),
                        Text(msg['attachment'],
                            style:
                                const TextStyle(color: CivilTheme.textPrimary)),
                      ],
                    ),
                  ] else ...[
                    _buildHighlightedText(
                        msg['content'] ?? '', msg['mentions']),
                  ],
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(timeText,
                        style: const TextStyle(
                            color: CivilTheme.textSecondary, fontSize: 10)),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 12),
            CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFF1B3252),
                child: Text(msg['avatar'] ?? 'U',
                    style: const TextStyle(
                        color: Colors.blueAccent, fontSize: 12))),
          ],
        ],
      ),
    );
  }

  Widget _buildHighlightedText(String text, List<dynamic>? mentions) {
    if (mentions == null || mentions.isEmpty) {
      return Text(text,
          style: const TextStyle(
              color: CivilTheme.textPrimary, fontSize: 14, height: 1.4));
    }

    // Simple mock highlighting
    List<TextSpan> spans = [];
    String currentText = text;
    for (String mention in mentions) {
      if (currentText.contains(mention)) {
        final parts = currentText.split(mention);
        spans.add(TextSpan(text: parts[0]));
        spans.add(TextSpan(
            text: mention, style: const TextStyle(color: Colors.blueAccent)));
        currentText = parts.length > 1 ? parts[1] : '';
      }
    }
    spans.add(TextSpan(text: currentText));

    return RichText(
      text: TextSpan(
        style: const TextStyle(
            color: CivilTheme.textPrimary, fontSize: 14, height: 1.4),
        children: spans,
      ),
    );
  }
}
