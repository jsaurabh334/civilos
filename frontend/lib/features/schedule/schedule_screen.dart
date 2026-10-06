import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/task_provider.dart';
import '../../core/providers/project_provider.dart';
import '../../core/theme.dart';
import '../../shared/widgets/gantt_chart.dart';

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  int? _selectedProjectId;
  bool _showGantt = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectProvider.notifier).fetchProjects();
    });
  }

  void _loadTasks(int projectId) {
    setState(() => _selectedProjectId = projectId);
    ref.read(taskProvider.notifier).fetchTasks(projectId);
  }

  void _showCreateDialog() {
    if (_selectedProjectId == null) return;

    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final assigneeCtrl = TextEditingController();
    String startDate = DateTime.now().toIso8601String().substring(0, 10);
    String endDate = DateTime.now().add(const Duration(days: 7)).toIso8601String().substring(0, 10);
    String priority = 'Medium';
    double progress = 0;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDState) => AlertDialog(
          backgroundColor: CivilTheme.surface,
          title: const Text('Create Task', style: TextStyle(color: CivilTheme.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: CivilTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Title',
                      labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  style: const TextStyle(color: CivilTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Description',
                      labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: assigneeCtrl,
                  style: const TextStyle(color: CivilTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Assignee',
                      labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Start',
                            labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                        style: const TextStyle(color: CivilTheme.textPrimary),
                        controller: TextEditingController(text: startDate),
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.parse(startDate),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setDState(() => startDate = picked.toIso8601String().substring(0, 10));
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'End',
                            labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                        style: const TextStyle(color: CivilTheme.textPrimary),
                        controller: TextEditingController(text: endDate),
                        readOnly: true,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.parse(endDate),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2030),
                          );
                          if (picked != null) setDState(() => endDate = picked.toIso8601String().substring(0, 10));
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  dropdownColor: CivilTheme.surface,
                  style: const TextStyle(color: CivilTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Priority',
                      labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                  items: ['Low', 'Medium', 'High', 'Critical']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setDState(() => priority = v!),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Progress: ', style: TextStyle(color: CivilTheme.textSecondary)),
                    Expanded(
                      child: Slider(
                        value: progress,
                        min: 0, max: 100,
                        divisions: 20,
                        activeColor: CivilTheme.primary,
                        onChanged: (v) => setDState(() => progress = v),
                      ),
                    ),
                    Text('${progress.toInt()}%',
                        style: const TextStyle(color: CivilTheme.textPrimary)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.redAccent)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                final scaffold = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(ctx);
                final success = await ref.read(taskProvider.notifier).createTask({
                  'project_id': _selectedProjectId,
                  'title': titleCtrl.text.trim(),
                  'description': descCtrl.text.trim(),
                  'assignee': assigneeCtrl.text.trim(),
                  'start_date': startDate,
                  'end_date': endDate,
                  'priority': priority,
                  'progress': progress,
                });
                if (navigator.mounted) navigator.pop();
                if (success && scaffold.mounted) {
                  scaffold.showSnackBar(
                      const SnackBar(content: Text('Task created')));
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final projectState = ref.watch(projectProvider);
    final taskState = ref.watch(taskProvider);
    final projects = projectState.projects;
    final tasks = taskState.tasks;

    return Scaffold(
      backgroundColor: CivilTheme.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
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
              SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        children: [
                          const Text('Project Schedule',
                              style: TextStyle(color: CivilTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                          const Spacer(),
                          // Project selector
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: CivilTheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: CivilTheme.border),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int?>(
                                value: _selectedProjectId,
                                hint: const Text('Select Project',
                                    style: TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
                                dropdownColor: CivilTheme.surface,
                                style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 13),
                                items: [
                                  ...projects.map((p) => DropdownMenuItem(
                                    value: p['id'] as int,
                                    child: Text(p['name']?.toString() ?? ''),
                                  )),
                                ],
                                onChanged: (v) {
                                  if (v != null) _loadTasks(v);
                                },
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_selectedProjectId != null) ...[
                            IconButton(
                              icon: Icon(_showGantt ? Icons.list : Icons.bar_chart,
                                  color: CivilTheme.primary),
                              onPressed: () => setState(() => _showGantt = !_showGantt),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: CivilTheme.primary),
                              onPressed: _showCreateDialog,
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (taskState.error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text('Error: ${taskState.error}',
                            style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
                      ),
                    if (_selectedProjectId == null)
                      const Expanded(
                        child: Center(
                          child: Text('Select a project to view its schedule',
                              style: TextStyle(color: CivilTheme.textSecondary, fontSize: 16)),
                        ),
                      )
                    else if (taskState.isLoading)
                      const Expanded(child: Center(child: CircularProgressIndicator()))
                    else if (tasks.isEmpty)
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule, size: 48, color: CivilTheme.textSecondary),
                              const SizedBox(height: 12),
                              const Text('No tasks for this project',
                                  style: TextStyle(color: CivilTheme.textSecondary)),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _showCreateDialog,
                                icon: const Icon(Icons.add, size: 18),
                                label: const Text('Add First Task'),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_showGantt)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: GanttChart(
                            tasks: tasks.map((t) => GanttTask.fromMap(Map<String, dynamic>.from(t as Map))).toList(),
                            projectStart: DateTime.now().subtract(const Duration(days: 7)),
                            projectEnd: DateTime.now().add(const Duration(days: 60)),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final t = tasks[index] as Map<String, dynamic>;
                            final ganttTask = GanttTask.fromMap(t);
                            return Card(
                              color: CivilTheme.surface.withValues(alpha: 0.6),
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: _statusIcon(ganttTask.status),
                                title: Text(ganttTask.title,
                                    style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 14)),
                                subtitle: Text(
                                  '${ganttTask.startDate} → ${ganttTask.endDate}  ·  ${ganttTask.progress.toInt()}%',
                                  style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 11),
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 18),
                                  onPressed: () {
                                    ref.read(taskProvider.notifier)
                                        .deleteTask(ganttTask.id, _selectedProjectId!);
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _statusIcon(String status) {
    IconData icon;
    Color color;
    switch (status) {
      case 'Completed':
        icon = Icons.check_circle;
        color = CivilTheme.secondary;
        break;
      case 'In Progress':
        icon = Icons.play_circle;
        color = CivilTheme.primary;
        break;
      case 'On Hold':
        icon = Icons.pause_circle;
        color = Colors.orange;
        break;
      default:
        icon = Icons.radio_button_unchecked;
        color = CivilTheme.textSecondary;
    }
    return Icon(icon, color: color, size: 22);
  }
}
