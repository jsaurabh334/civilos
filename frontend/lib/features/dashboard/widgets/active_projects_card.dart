import 'package:flutter/material.dart';
import '../../../core/theme.dart';

class ActiveProjectsCard extends StatelessWidget {
  final List<Map<String, dynamic>> projects;
  const ActiveProjectsCard({super.key, this.projects = const []});

  @override
  Widget build(BuildContext context) {
    final displayProjects = projects.isEmpty
        ? [
            {'site': 'Oakwood Tower', 'status': 0.65, 'pm': 'A'},
            {'site': 'Bridge Renovation', 'status': 0.82, 'pm': 'B'},
            {'site': 'Parkside Tower', 'status': 0.65, 'pm': 'C'},
            {'site': 'Parkside', 'status': 0.75, 'pm': 'D'},
          ]
        : projects;

    return Container(
      padding: const EdgeInsets.all(24),
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
              const Text('Active Projects',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: CivilTheme.textPrimary)),
              Icon(Icons.more_horiz, color: CivilTheme.textSecondary),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                  flex: 3,
                  child: Text('Site',
                      style: TextStyle(
                          fontSize: 12, color: CivilTheme.textSecondary))),
              Expanded(
                  flex: 2,
                  child: Text('Status',
                      style: TextStyle(
                          fontSize: 12, color: CivilTheme.textSecondary))),
              Expanded(
                  flex: 1,
                  child: Text('PM',
                      style: TextStyle(
                          fontSize: 12, color: CivilTheme.textSecondary),
                      textAlign: TextAlign.right)),
            ],
          ),
          const SizedBox(height: 16),
            Expanded(
              child: ListView(
              children: displayProjects
                  .asMap()
                  .entries
                  .map((entry) {
                    final p = entry.value as Map<String, dynamic>;
                    final name = p['name']?.toString() ?? p['site']?.toString() ?? 'Project ${entry.key + 1}';
                    final progress = (p['progress'] ?? p['status'] ?? entry.key * 0.15 + 0.4) as num;
                    final pm = p['pm'] ?? (p['project_manager']?.toString() ?? 'NA');
                    return Padding(
                        padding: const EdgeInsets.only(bottom: 16.0),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: CivilTheme.textPrimary)),
                                  Text('${projects.length} projects',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: CivilTheme.textSecondary)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: progress.toDouble().clamp(0, 1),
                                        backgroundColor: CivilTheme.border,
                                        color: CivilTheme.primary,
                                        minHeight: 6,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                      '${(progress.toDouble() * 100).toInt()}%',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: CivilTheme.textPrimary)),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: CircleAvatar(
                                  radius: 12,
                                  backgroundColor: CivilTheme.border,
                                  child: Text(pm.isNotEmpty ? pm[0].toUpperCase() : '?',
                                      style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 11)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                  })
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
