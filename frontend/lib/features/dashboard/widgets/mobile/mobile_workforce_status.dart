import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers/dashboard_provider.dart';

class MobileWorkforceStatus extends ConsumerWidget {
  const MobileWorkforceStatus({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final stats = dashboardState.stats ?? {};

    final present = (stats['workers_present_today'] ?? 168) as num;
    final total = (stats['total_workers'] ?? 245) as num;
    final onLeave = (stats['workers_on_leave'] ?? (total * 0.08).round()) as num;
    final unassigned = (stats['workers_unassigned'] ?? (total * 0.06).round()) as num;
    final absent = total - present - onLeave - unassigned;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: CivilTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: CivilTheme.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Workforce Status',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: CivilTheme.textPrimary)),
                Icon(Icons.more_horiz,
                    color: CivilTheme.textSecondary, size: 20),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 120,
                    child: Stack(
                      children: [
                        PieChart(
                          PieChartData(
                            sectionsSpace: 4,
                            centerSpaceRadius: 40,
                            startDegreeOffset: -90,
                            sections: [
                              PieChartSectionData(
                                  color: CivilTheme.primary,
                                  value: present.toDouble(),
                                  title: '',
                                  radius: 12),
                              PieChartSectionData(
                                  color: CivilTheme.warning,
                                  value: onLeave.toDouble(),
                                  title: '',
                                  radius: 12),
                              PieChartSectionData(
                                  color: Colors.blueAccent,
                                  value: unassigned.toDouble(),
                                  title: '',
                                  radius: 12),
                            ],
                          ),
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('$total',
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: CivilTheme.textPrimary)),
                              Text('workers',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: CivilTheme.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegend('Active: ${total > 0 ? ((present / total) * 100).round() : 0}%', CivilTheme.primary),
                      const SizedBox(height: 12),
                      _buildLegend('On Leave: ${total > 0 ? ((onLeave / total) * 100).round() : 0}%', CivilTheme.warning),
                      const SizedBox(height: 12),
                      _buildLegend('Unassigned: ${total > 0 ? ((unassigned / total) * 100).round() : 0}%', Colors.blueAccent),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: CivilTheme.textPrimary)),
      ],
    );
  }
}
