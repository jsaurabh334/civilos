import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/providers/project_provider.dart';

class CopilotScreen extends ConsumerStatefulWidget {
  const CopilotScreen({super.key});

  @override
  ConsumerState<CopilotScreen> createState() => _CopilotScreenState();
}

class _CopilotScreenState extends ConsumerState<CopilotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'ai',
      'text': 'Hello! I am your AI Copilot. How can I assist you with your projects today?',
    });
  }

  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;

    final prompt = _controller.text.trim();
    setState(() {
      _messages.add({'role': 'user', 'text': prompt});
      _isLoading = true;
    });
    _controller.clear();

    final project = ref.read(currentProjectProvider);
    final projectId = project?['id'] ?? 0;

    try {
      final response = await ApiClient().post('/ai/chat', {
        'prompt': prompt,
        'project_id': projectId,
      });

      setState(() {
        _messages.add({
          'role': 'ai',
          'text': response['reply']['text'] ?? 'Sorry, I couldn\'t process that.',
        });
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'error',
          'text': 'Error: ${e.toString()}',
        });
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('AI Copilot'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                final isError = msg['role'] == 'error';

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? Theme.of(context).primaryColor
                          : (isError ? Theme.of(context).colorScheme.error.withValues(alpha: 0.1) : Theme.of(context).cardColor),
                      borderRadius: BorderRadius.circular(12),
                      border: isUser || isError ? null : Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Text(
                      msg['text'] ?? '',
                      style: TextStyle(
                        color: isUser ? Colors.white : (isError ? Theme.of(context).colorScheme.error : Theme.of(context).textTheme.bodyLarge?.color),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
