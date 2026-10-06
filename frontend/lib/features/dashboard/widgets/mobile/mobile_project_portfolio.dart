import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers/project_provider.dart';

class MobileProjectPortfolio extends ConsumerWidget {
  const MobileProjectPortfolio({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projects = ref.watch(projectProvider).projects;
    final displayProjects = projects.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Project Portfolio',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: CivilTheme.textPrimary)),
        ),
        const SizedBox(height: 12),
        if (displayProjects.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text('No projects yet',
                style: TextStyle(fontSize: 13, color: CivilTheme.textSecondary)),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: displayProjects.asMap().entries.map((entry) {
                final p = entry.value as Map<String, dynamic>;
                final name = p['name']?.toString() ?? 'Project ${entry.key + 1}';
                final location = p['location']?.toString() ?? '';
                final progress = (p['progress'] ?? 0).toDouble() / 100;
                final status = p['status']?.toString() ?? 'On Track';
                final statusColor = status == 'Delayed' || status == 'Behind'
                    ? CivilTheme.error
                    : CivilTheme.primary;
                final budget = p['budget'] ?? p['contract_value'] ?? 0;
                final spent = p['cost_incurred'] ?? 0;
                final issues = p['open_issues'] ?? 0;
                final critical = p['critical_issues'] ?? 0;

                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _buildProjectCard(
                    name,
                    location,
                    Icons.apartment,
                    CivilTheme.primary,
                    status,
                    statusColor,
                    progress,
                    '\$${_fmtNum(budget)}',
                    '\$${_fmtNum(spent)}',
                    issues is int ? issues : 0,
                    critical is int ? critical : 0,
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  String _fmtNum(dynamic val) {
    final num v = (val ?? 0) as num;
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  Widget _buildProjectCard(
      String title,
      String location,
      IconData icon,
      Color iconColor,
      String status,
      Color statusColor,
      double progress,
      String budget,
      String spent,
      int issues,
      int critical) {
    return Container(
      width: 280,
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
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: CivilTheme.textPrimary),
                        overflow: TextOverflow.ellipsis),
                    if (location.isNotEmpty)
                      Text(location,
                          style: const TextStyle(
                              fontSize: 11, color: CivilTheme.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text.rich(TextSpan(children: [
                const TextSpan(
                    text: 'Status: ',
                    style: TextStyle(
                        fontSize: 11, color: CivilTheme.textSecondary)),
                TextSpan(
                    text: status,
                    style: TextStyle(
                        fontSize: 11,
                        color: statusColor,
                        fontWeight: FontWeight.bold)),
              ])),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Progress:',
                  style:
                      TextStyle(fontSize: 11, color: CivilTheme.textSecondary)),
              Text('${(progress * 100).toInt()}%',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: CivilTheme.textPrimary)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress.clamp(0, 1),
              backgroundColor: CivilTheme.border,
              color: statusColor,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          Text.rich(TextSpan(children: [
            const TextSpan(
                text: 'Budget: ',
                style:
                    TextStyle(fontSize: 11, color: CivilTheme.textSecondary)),
            TextSpan(
                text: budget,
                style: const TextStyle(
                    fontSize: 11,
                    color: CivilTheme.textPrimary,
                    fontWeight: FontWeight.bold)),
            TextSpan(
                text: ' (Spent $spent)',
                style: const TextStyle(
                    fontSize: 11, color: CivilTheme.textSecondary)),
          ])),
          const SizedBox(height: 4),
          Text.rich(TextSpan(children: [
            const TextSpan(
                text: 'Issues: ',
                style:
                    TextStyle(fontSize: 11, color: CivilTheme.textSecondary)),
            TextSpan(
                text: '$issues ',
                style: const TextStyle(
                    fontSize: 11,
                    color: CivilTheme.textPrimary,
                    fontWeight: FontWeight.bold)),
            if (critical > 0)
              TextSpan(
                  text: '($critical Critical)',
                  style: const TextStyle(fontSize: 11, color: CivilTheme.error)),
          ])),
        ],
      ),
    );
  }
}
