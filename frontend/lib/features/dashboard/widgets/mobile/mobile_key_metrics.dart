import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers/dashboard_provider.dart';

class MobileKeyMetrics extends ConsumerWidget {
  const MobileKeyMetrics({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final stats = dashboardState.stats ?? {};

    final activeProjects = stats['active_projects'] ?? stats['total_projects'] ?? 0;
    final totalWorkers = stats['total_workers'] ?? 0;
    final totalBudget = (stats['total_contract_value'] ?? 0).toDouble();
    final spentBudget = (stats['cost_incurred'] ?? 0).toDouble();
    final budgetPercent = totalBudget > 0 ? ((spentBudget / totalBudget) * 100).toStringAsFixed(0) : '0';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Key Metrics',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: CivilTheme.textPrimary)),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            children: [
              _buildCard('Active Projects', '$activeProjects', '+$activeProjects', 'Total Running',
                  CivilTheme.primary),
              const SizedBox(width: 12),
              _buildCard('Current Workforce', '$totalWorkers', '', 'Total Deployed',
                  CivilTheme.warning),
              const SizedBox(width: 12),
              _buildCard('Total Budget', '\$${_fmtBudget(totalBudget)}', '', '$budgetPercent% Spent',
                  Colors.blueAccent),
            ],
          ),
        ),
      ],
    );
  }

  String _fmtBudget(double amount) {
    if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
    if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(1)}K';
    return amount.toStringAsFixed(0);
  }

  Widget _buildCard(
      String title, String value, String change, String subtitle, Color color) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CivilTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 11, color: CivilTheme.textSecondary)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: CivilTheme.textPrimary)),
              if (change.isNotEmpty) ...[
                const SizedBox(width: 4),
                Text(change,
                    style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.bold)),
              ]
            ],
          ),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 10, color: CivilTheme.textSecondary)),
        ],
      ),
    );
  }
}
