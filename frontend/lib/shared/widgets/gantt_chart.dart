import 'package:flutter/material.dart';
import '../../core/theme.dart';

class GanttTask {
  final int id;
  final String title;
  final String startDate;
  final String endDate;
  final double progress;
  final String status;
  final String priority;
  final String assignee;
  final List<int> dependencyIds;

  GanttTask({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    this.progress = 0,
    this.status = 'Not Started',
    this.priority = 'Medium',
    this.assignee = '',
    this.dependencyIds = const [],
  });

  factory GanttTask.fromMap(Map<String, dynamic> map) => GanttTask(
    id: map['id'] as int,
    title: map['title']?.toString() ?? '',
    startDate: map['start_date']?.toString() ?? '',
    endDate: map['end_date']?.toString() ?? '',
    progress: (map['progress'] as num?)?.toDouble() ?? 0,
    status: map['status']?.toString() ?? 'Not Started',
    priority: map['priority']?.toString() ?? 'Medium',
    assignee: map['assignee']?.toString() ?? '',
    dependencyIds: (map['dependency_ids'] is List)
        ? List<int>.from(map['dependency_ids'] as List)
        : [],
  );
}

class GanttChart extends StatelessWidget {
  final List<GanttTask> tasks;
  final DateTime projectStart;
  final DateTime projectEnd;
  final void Function(int taskId, DateTime newStart, DateTime newEnd)? onTaskReschedule;

  const GanttChart({
    super.key,
    required this.tasks,
    required this.projectStart,
    required this.projectEnd,
    this.onTaskReschedule,
  });

  static const _rowHeight = 44.0;
  static const _dayWidth = 28.0;
  static const _sidebarWidth = 200.0;
  static const _headerHeight = 56.0;

  int get _totalDays => projectEnd.difference(projectStart).inDays + 1;

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const Center(child: Text('No tasks scheduled', style: TextStyle(color: CivilTheme.textSecondary)));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth - _sidebarWidth;
        final dayWidth = _dayWidth;
        final totalWidth = _totalDays * dayWidth;
        final scrollWidth = totalWidth > availableWidth ? totalWidth : availableWidth;

        return Column(
          children: [
            // Header row
            SizedBox(
              height: _headerHeight,
              child: Row(
                children: [
                  Container(
                    width: _sidebarWidth,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: CivilTheme.surface,
                      border: Border.all(color: CivilTheme.border),
                    ),
                    child: const Text('Task',
                        style: TextStyle(
                            color: CivilTheme.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: scrollWidth,
                        child: Row(
                          children: List.generate(_totalDays, (i) {
                            final date = projectStart.add(Duration(days: i));
                            final isWeekend = date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
                            return Container(
                              width: dayWidth,
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: isWeekend ? Colors.grey.withValues(alpha: 0.1) : CivilTheme.surface,
                                border: Border.all(color: CivilTheme.border, width: 0.5),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('${date.day}',
                                      style: TextStyle(
                                          color: isWeekend ? CivilTheme.textSecondary.withValues(alpha: 0.5) : CivilTheme.textPrimary,
                                          fontSize: 9)),
                                  Text(_monthAbbr(date),
                                      style: TextStyle(
                                          color: CivilTheme.textSecondary,
                                          fontSize: 7)),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Task rows
            Expanded(
              child: SingleChildScrollView(
                  child: Column(
                    children: tasks.map((task) => _buildTaskRow(context, task, dayWidth, scrollWidth)).toList(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  String _monthAbbr(DateTime d) {
    const months = ['J','F','M','A','M','J','J','A','S','O','N','D'];
    return months[d.month - 1];
  }

  Widget _buildTaskRow(BuildContext ctx, GanttTask task, double dayWidth, double scrollWidth) {
    final taskStart = DateTime.tryParse(task.startDate) ?? projectStart;
    final taskEnd = DateTime.tryParse(task.endDate) ?? projectStart;
    final startOffset = taskStart.difference(projectStart).inDays;
    final duration = taskEnd.difference(taskStart).inDays + 1;

    final left = startOffset * dayWidth;
    final width = duration * dayWidth;

    Color barColor;
    switch (task.status) {
      case 'Completed':
        barColor = CivilTheme.secondary;
        break;
      case 'In Progress':
        barColor = CivilTheme.primary;
        break;
      case 'On Hold':
        barColor = Colors.orange;
        break;
      default:
        barColor = CivilTheme.textSecondary;
    }

    return Container(
      height: _rowHeight,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: CivilTheme.border.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          // Sidebar
          Container(
            width: _sidebarWidth,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(task.title,
                      style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 11),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ),
                if (task.assignee.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: CivilTheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(task.assignee,
                        style: const TextStyle(color: CivilTheme.primary, fontSize: 8)),
                  ),
              ],
            ),
          ),
          // Timeline
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: scrollWidth,
                height: _rowHeight,
                child: Stack(
                  children: [
                    // Today line
                    Positioned(
                      left: DateTime.now().difference(projectStart).inDays * dayWidth,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 2,
                        color: Colors.redAccent.withValues(alpha: 0.6),
                      ),
                    ),
                    // Task bar
                    Positioned(
                      left: left,
                      top: 8,
                      width: width,
                      child: GestureDetector(
                        onTap: () => _showTaskDetails(ctx, task),
                        child: Container(
                          height: 28,
                          decoration: BoxDecoration(
                            color: barColor.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: barColor, width: 1.5),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: Stack(
                              children: [
                                FractionallySizedBox(
                                  widthFactor: task.progress / 100,
                                  child: Container(color: barColor.withValues(alpha: 0.5)),
                                ),
                                if (width > 40)
                                  Center(
                                    child: Text(task.title,
                                        style: const TextStyle(color: Colors.white, fontSize: 9),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskDetails(BuildContext context, GanttTask task) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CivilTheme.surface,
        title: Text(task.title, style: const TextStyle(color: CivilTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('Status', task.status),
            _detailRow('Priority', task.priority),
            _detailRow('Dates', '${task.startDate} → ${task.endDate}'),
            _detailRow('Progress', '${task.progress.toStringAsFixed(0)}%'),
            if (task.assignee.isNotEmpty) _detailRow('Assignee', task.assignee),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: TextStyle(color: CivilTheme.primary)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
          Text(value, style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 13)),
        ],
      ),
    );
  }
}
