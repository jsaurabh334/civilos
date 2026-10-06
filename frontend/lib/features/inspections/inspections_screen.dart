import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/project_provider.dart';
import '../../core/theme.dart';
import '../../core/providers/inspection_provider.dart';
import '../../core/empty_state.dart';
import '../../core/refresh_wrapper.dart';

class InspectionsScreen extends ConsumerStatefulWidget {
  final bool isEmbedded;
  const InspectionsScreen({super.key, this.isEmbedded = false});

  @override
  ConsumerState<InspectionsScreen> createState() => _InspectionsScreenState();
}

class _InspectionsScreenState extends ConsumerState<InspectionsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(inspectionProvider.notifier).fetchInspections();
      ref.read(projectProvider.notifier).fetchProjects();
    });
  }

  void _showAddInspectionDialog() {
    final titleController = TextEditingController();
    final descController = TextEditingController();
    int? selectedProjectId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: CivilTheme.surface,
          title: const Text('Schedule Inspection',
            style: TextStyle(color: CivilTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                style: const TextStyle(color: CivilTheme.textPrimary),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                style: const TextStyle(color: CivilTheme.textPrimary),
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
                  await ref.read(inspectionProvider.notifier).createInspection(
                    titleController.text,
                    descController.text,
                    selectedProjectId ?? 0,
                    DateTime.now().toIso8601String(),
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
              child: const Text('Schedule'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(inspectionProvider);
    final inspections = state.inspections;
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
                      const Text('Inspections',
                        style: TextStyle(color: CivilTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _showAddInspectionDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('New Inspection'),
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
                  child: state.isLoading && inspections.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : state.error != null && inspections.isEmpty
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
                                    onPressed: () => ref.read(inspectionProvider.notifier).fetchInspections(),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : inspections.isEmpty
                              ? const EmptyState(
                                  icon: Icons.checklist,
                                  title: 'No Inspections',
                                  subtitle: 'Schedule your first inspection',
                                )
                              : RefreshWrapper(
                                  onRefresh: () => ref.read(inspectionProvider.notifier).fetchInspections(),
                                  child: ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                                    itemCount: inspections.length,
                                    itemBuilder: (context, index) {
                                      final item = inspections[index];
                                      final status = item['status']?.toString() ?? 'Pending';
                                      final statusColor = status == 'Passed'
                                          ? CivilTheme.secondary
                                          : status == 'Failed'
                                              ? CivilTheme.error
                                              : CivilTheme.warning;
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 12),
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: CivilTheme.surface,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: CivilTheme.border),
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  Text(item['title']?.toString() ?? '',
                                                    style: const TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
                                                  if (item['description']?.toString().isNotEmpty == true) ...[
                                                    const SizedBox(height: 4),
                                                    Text(item['description'].toString(),
                                                      style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 12)),
                                                  ],
                                                ],
                                              ),
                                            ),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: statusColor.withValues(alpha: 0.15),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(status.toUpperCase(),
                                                style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
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
