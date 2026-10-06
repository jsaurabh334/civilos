import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme.dart';

class WorkforceAttendanceCard extends StatelessWidget {
  const WorkforceAttendanceCard({super.key});

  @override
  Widget build(BuildContext context) {
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
              const Expanded(
                child: Text('Daily Workforce Attendance',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: CivilTheme.textPrimary)),
              ),
              Icon(Icons.more_horiz, color: CivilTheme.textSecondary),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 4,
                          centerSpaceRadius: 50,
                          startDegreeOffset: -90,
                          sections: [
                            PieChartSectionData(
                                color: CivilTheme.primary,
                                value: 92,
                                title: '92%',
                                radius: 24,
                                titleStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: CivilTheme.background)),
                            PieChartSectionData(
                                color: CivilTheme.warning,
                                value: 8,
                                title: '8%',
                                radius: 24,
                                titleStyle: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: CivilTheme.background)),
                          ],
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('310',
                                style: TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: CivilTheme.textPrimary)),
                            Text('Active',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: CivilTheme.textSecondary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLegend('Present', CivilTheme.primary),
                      const SizedBox(height: 16),
                      _buildLegend('On Leave', CivilTheme.warning),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
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
                const TextStyle(fontSize: 13, color: CivilTheme.textPrimary)),
      ],
    );
  }
}
