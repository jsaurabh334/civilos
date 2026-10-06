import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/confirm_dialog.dart';

class IssuesScreen extends ConsumerStatefulWidget {
  const IssuesScreen({super.key});

  @override
  ConsumerState<IssuesScreen> createState() => _IssuesScreenState();
}

class _IssuesScreenState extends ConsumerState<IssuesScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _issues = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await ref.read(apiClientProvider).get('/issues');
      final list = response is List
          ? response.cast<Map<String, dynamic>>()
          : response is Map && response['data'] is List
              ? (response['data'] as List).cast<Map<String, dynamic>>()
              : <Map<String, dynamic>>[];
      setState(() => _issues = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showReportDialog() {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descController = TextEditingController();
    String priority = 'Medium';
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: CivilTheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Report Issue',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: CivilTheme.textPrimary)),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: titleController,
                        style: const TextStyle(color: CivilTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Issue Title',
                          labelStyle:
                              TextStyle(color: CivilTheme.textSecondary),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descController,
                        maxLines: 3,
                        style: const TextStyle(color: CivilTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          labelStyle:
                              TextStyle(color: CivilTheme.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: priority,
                        dropdownColor: CivilTheme.surface,
                        style: const TextStyle(color: CivilTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Priority',
                          labelStyle:
                              TextStyle(color: CivilTheme.textSecondary),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Low', child: Text('Low')),
                          DropdownMenuItem(
                              value: 'Medium', child: Text('Medium')),
                          DropdownMenuItem(
                              value: 'High', child: Text('High')),
                          DropdownMenuItem(
                              value: 'Critical', child: Text('Critical')),
                        ],
                        onChanged: (v) =>
                            setDialogState(() => priority = v!),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel',
                                style: TextStyle(
                                    color: CivilTheme.textSecondary)),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setDialogState(() => isSubmitting = true);
                                    try {
                                      await ref
                                          .read(apiClientProvider)
                                          .post('/issues', {
                                        'title': titleController.text.trim(),
                                        'description':
                                            descController.text.trim(),
                                        'priority': priority,
                                      });
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (mounted) {
                                        showToast(context,
                                            'Issue reported successfully');
                                        _fetchData();
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        showToast(context,
                                            'Failed: $e',
                                            isError: true);
                                      }
                                    } finally {
                                      if (mounted) {
                                        setDialogState(
                                            () => isSubmitting = false);
                                      }
                                    }
                                  },
                            child: const Text('Submit'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.deepOrange;
      case 'Medium':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Site Issues')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error: $_error',
                          style: const TextStyle(color: CivilTheme.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _fetchData,
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : _issues.isEmpty
                  ? const Center(child: Text("No issues reported."))
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _issues.length,
                        itemBuilder: (context, index) {
                          final issue = _issues[index];
                          final status =
                              issue['status']?.toString() ?? 'Open';
                          final priority =
                              issue['priority']?.toString() ?? 'Medium';
                          final Color statusColor =
                              status == 'Closed' ? Colors.green : Colors.orange;
                          final Color priorityColor =
                              _priorityColor(priority);

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                          issue['id']?.toString() ?? 'N/A',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.grey)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border:
                                              Border.all(color: statusColor),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                              color: statusColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                      issue['title']?.toString() ?? 'N/A',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.person,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                          issue['reported_by']?.toString() ??
                                              issue['reportedBy']?.toString() ??
                                              'N/A',
                                          style: const TextStyle(
                                              color: Colors.grey)),
                                      const Spacer(),
                                      const Icon(Icons.calendar_today,
                                          size: 16, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(
                                          issue['date']?.toString() ??
                                              issue['created_at']
                                                  ?.toString() ??
                                              'N/A',
                                          style: const TextStyle(
                                              color: Colors.grey)),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Text("Priority: ",
                                          style: TextStyle(
                                              fontWeight: FontWeight.w600)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color:
                                              priorityColor.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          priority,
                                          style: TextStyle(
                                              color: priorityColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12),
                                        ),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: CivilTheme.primary,
        onPressed: _showReportDialog,
        icon: const Icon(Icons.warning, color: Colors.white),
        label: const Text('Report Issue',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
