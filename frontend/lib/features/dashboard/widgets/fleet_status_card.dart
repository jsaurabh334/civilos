import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme.dart';

class FleetStatusCard extends StatelessWidget {
  const FleetStatusCard({super.key});

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
                child: Text('Equipment Fleet Status',
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
                          value: 68,
                          title: '',
                          radius: 20),
                      PieChartSectionData(
                          color: CivilTheme.warning,
                          value: 14,
                          title: '',
                          radius: 20),
                      PieChartSectionData(
                          color: CivilTheme.secondary,
                          value: 18,
                          title: '',
                          radius: 20),
                    ],
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('124',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: CivilTheme.textPrimary)),
                      Text('units',
                          style: TextStyle(
                              fontSize: 14, color: CivilTheme.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildLegend('Operating', '68%', CivilTheme.primary),
              _buildLegend('Maintenance', '18%', CivilTheme.secondary),
              _buildLegend('Idle', '14%', CivilTheme.warning),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegend(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
                width: 8,
                height: 8,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(label,
                style:
                    TextStyle(fontSize: 11, color: CivilTheme.textSecondary)),
          ],
        ),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: CivilTheme.textPrimary)),
      ],
    );
  }
}
