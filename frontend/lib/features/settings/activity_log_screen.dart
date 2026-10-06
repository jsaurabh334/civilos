import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/auth_provider.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/empty_state_view.dart';

final activityLogProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get('/audit-logs/me');
  if (data == null) return [];
  final list = data['logs'] ?? data['data'] ?? data;
  if (list is List) return list.cast<Map<String, dynamic>>();
  return [];
});

class ActivityLogScreen extends ConsumerWidget {
  const ActivityLogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsAsync = ref.watch(activityLogProvider);

    return Scaffold(
      backgroundColor: CivilTheme.background,
      appBar: AppBar(
        backgroundColor: CivilTheme.surface,
        title: const Text('Activity Log', style: TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: CivilTheme.textSecondary),
            onPressed: () => ref.invalidate(activityLogProvider),
          ),
        ],
      ),
      body: logsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: SkeletonList(count: 6, itemHeight: 70),
        ),
        error: (e, _) => EmptyStateView(
          icon: Icons.error_outline,
          title: 'Failed to load activity',
          description: e.toString().replaceAll('Exception: ', ''),
        ),
        data: (logs) {
          if (logs.isEmpty) {
            return const EmptyStateView(
              icon: Icons.history,
              title: 'No Activity Yet',
              description: 'Your actions on the platform will appear here.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(activityLogProvider),
            color: CivilTheme.primary,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _buildLogItem(logs[i]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLogItem(Map<String, dynamic> log) {
    final action = log['action']?.toString() ?? 'Action';
    final resource = log['resource_type']?.toString() ?? '';
    final metadata = log['metadata']?.toString() ?? '';
    final ts = log['created_at']?.toString() ?? log['timestamp']?.toString();
    String timeLabel = '';
    if (ts != null) {
      try {
        final dt = DateTime.parse(ts).toLocal();
        timeLabel = DateFormat('dd MMM yyyy, HH:mm').format(dt);
      } catch (_) {
        timeLabel = ts;
      }
    }

    final (icon, color) = _getActionStyle(action);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: CivilTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        action,
                        style: const TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                    ),
                    if (resource.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(resource, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                  ],
                ),
                if (metadata.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(metadata, style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                if (timeLabel.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: CivilTheme.textSecondary, size: 11),
                      const SizedBox(width: 4),
                      Text(timeLabel, style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 11)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  (IconData, Color) _getActionStyle(String action) {
    final lower = action.toLowerCase();
    if (lower.contains('create') || lower.contains('add')) return (Icons.add_circle_outline, Colors.greenAccent);
    if (lower.contains('delete') || lower.contains('remove')) return (Icons.delete_outline, Colors.redAccent);
    if (lower.contains('update') || lower.contains('edit') || lower.contains('change')) return (Icons.edit_outlined, Colors.blueAccent);
    if (lower.contains('login') || lower.contains('sign')) return (Icons.login, Colors.tealAccent);
    if (lower.contains('upload')) return (Icons.upload_outlined, Colors.purpleAccent);
    if (lower.contains('download') || lower.contains('export')) return (Icons.download_outlined, Colors.orangeAccent);
    return (Icons.info_outline, CivilTheme.primary);
  }
}
