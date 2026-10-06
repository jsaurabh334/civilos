import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/project_provider.dart';
import '../../core/theme.dart';
import '../../core/providers/checklist_provider.dart';
import '../../core/empty_state.dart';
import '../../core/refresh_wrapper.dart';

class ChecklistsScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const ChecklistsScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<ChecklistsScreen> createState() => _ChecklistsScreenState();
}

class _ChecklistsScreenState extends ConsumerState<ChecklistsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(checklistProvider.notifier).fetchChecklists();
      ref.read(projectProvider.notifier).fetchProjects();
    });
  }

  void _showAddChecklistDialog() {
    final titleController = TextEditingController();
    String category = 'Safety';
    int? selectedProjectId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: CivilTheme.surface,
          title: const Text('Add Checklist Item',
            style: TextStyle(color: CivilTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Task',
                  labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                style: const TextStyle(color: CivilTheme.textPrimary),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                dropdownColor: CivilTheme.surface,
                style: const TextStyle(color: CivilTheme.textPrimary),
                items: ['Safety', 'Quality', 'Environment', 'Other']
                    .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => category = val);
                },
              ),
              const SizedBox(height: 16),
              Consumer(builder: (context, ref, child) {
                final projects = ref.watch(projectProvider).projects;
                return DropdownButtonFormField<int>(
                  initialValue: selectedProjectId,
                  dropdownColor: CivilTheme.surface,
                  style: const TextStyle(color: CivilTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Project',
                    labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                  items: projects.map((p) => DropdownMenuItem(
                    value: p['id'] as int,
                    child: Text(p['name']?.toString() ?? 'Unnamed'),
                  )).toList(),
                  onChanged: (val) {
                    setDialogState(() => selectedProjectId = val);
                  },
                );
              }),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                style: TextStyle(color: CivilTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty) return;
                try {
                  await ref.read(checklistProvider.notifier).createChecklist(
                    titleController.text,
                    category,
                    selectedProjectId ?? 0,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: CivilTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(checklistProvider);
    final checklists = state.checklists;

    final Map<String, List<dynamic>> grouped = {};
    for (var c in checklists) {
      final cat = c['category']?.toString() ?? 'Other';
      if (!grouped.containsKey(cat)) grouped[cat] = [];
      grouped[cat]!.add(c);
    }

    final isDesktop = MediaQuery.of(context).size.width > 900;

    final content = Stack(
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
        SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  children: [
                    if (!isDesktop && !widget.isEmbedded)
                      IconButton(
                        icon: const Icon(Icons.menu, color: CivilTheme.textSecondary),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                      const Text('QA & Safety Checklists',
                        style: TextStyle(color: CivilTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _showAddChecklistDialog,
                        icon: const Icon(Icons.add_task, size: 18),
                        label: const Text('Add Item'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CivilTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: state.isLoading && checklists.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : state.error != null && checklists.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline, size: 48, color: CivilTheme.error),
                                  const SizedBox(height: 16),
                                  Text(state.error!,
                                    style: const TextStyle(color: CivilTheme.error)),
                                  const SizedBox(height: 16),
                                  ElevatedButton(
                                    onPressed: () => ref.read(checklistProvider.notifier).fetchChecklists(),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : checklists.isEmpty
                              ? const EmptyState(
                                  icon: Icons.assignment,
                                  title: 'No Checklists',
                                  subtitle: 'Add your first checklist item',
                                )
                              : RefreshWrapper(
                                  onRefresh: () => ref.read(checklistProvider.notifier).fetchChecklists(),
                                  child: ListView(
                                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                    children: grouped.entries.map((entry) {
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            child: Text(entry.key,
                                              style: const TextStyle(color: CivilTheme.primary, fontSize: 14, fontWeight: FontWeight.bold)),
                                          ),
                                          ...entry.value.map((item) {
                                            final isDone = item['completed'] == true;
                                            return Container(
                                              margin: const EdgeInsets.only(bottom: 8),
                                              decoration: BoxDecoration(
                                                color: CivilTheme.surface,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: isDone ? CivilTheme.secondary.withValues(alpha: 0.3) : CivilTheme.border,
                                                ),
                                              ),
                                              child: ListTile(
                                                leading: Icon(
                                                  isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                                                  color: isDone ? CivilTheme.secondary : CivilTheme.textSecondary,
                                                ),
                                                title: Text(item['title']?.toString() ?? '',
                                                  style: TextStyle(
                                                    color: CivilTheme.textPrimary,
                                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                                  )),
                                                subtitle: item['project_id'] != null && item['project_id'] != 0
                                                    ? Text('Project #${item['project_id']}',
                                                        style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 11))
                                                    : null,
                                                onTap: () {
                                                  ref.read(checklistProvider.notifier).toggleChecklist(item['id'] as int);
                                                },
                                              ),
                                            );
                                          }),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                ),
              ],
            ),
          ),
        ],
      );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: CivilTheme.background,
      body: content,
    );
  }
}
