import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/theme.dart';
import '../../../core/providers/dashboard_provider.dart';

class BudgetChartCard extends ConsumerWidget {
  const BudgetChartCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final stats = dashboardState.stats ?? {};

    final budgeted = (stats['monthly_budgeted'] as List<dynamic>?) ?? [];
    final actual = (stats['monthly_actual'] as List<dynamic>?) ?? [];
    final projectCount = stats['active_projects'] ?? stats['total_projects'] ?? 4;

    final hasChartData = budgeted.length >= 4 && actual.length >= 4;

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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Current Budget vs Actual',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CivilTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text('$projectCount Projects',
                        style: TextStyle(
                            fontSize: 12, color: CivilTheme.textSecondary)),
                  ],
                ),
              ),
              Icon(Icons.more_horiz, color: CivilTheme.textSecondary),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: hasChartData
                    ? (budgeted.cast<num>().reduce((a, b) => a > b ? a : b).toDouble() * 1.3)
                    : 1.2,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        const style = TextStyle(
                            color: CivilTheme.textSecondary, fontSize: 11);
                        String text;
                        switch (value.toInt()) {
                          case 0:
                            text = '01';
                            break;
                          case 1:
                            text = '22';
                            break;
                          case 2:
                            text = '33';
                            break;
                          case 3:
                            text = '44';
                            break;
                          default:
                            text = '';
                            break;
                        }
                        return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(text, style: style));
                      },
                      reservedSize: 28,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (double value, TitleMeta meta) {
                        if (value == 0) {
                          return const Text('0',
                              style: TextStyle(
                                  color: CivilTheme.textSecondary,
                                  fontSize: 11));
                        }
                        return Text('\$${value.toInt()}K',
                            style: const TextStyle(
                                color: CivilTheme.textSecondary, fontSize: 11));
                      },
                      reservedSize: 32,
                    ),
                  ),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) =>
                      const FlLine(color: CivilTheme.border, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: hasChartData
                    ? List.generate(budgeted.length, (i) => _buildBarGroup(
                        i,
                        (budgeted[i] as num).toDouble(),
                        i < actual.length ? (actual[i] as num).toDouble() : 0,
                      ))
                    : [
                        _buildBarGroup(0, 0.5, 0.3),
                        _buildBarGroup(1, 0.7, 0.5),
                        _buildBarGroup(2, 0.9, 0.6),
                        _buildBarGroup(3, 1.0, 0.8),
                      ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend('Budgeted', CivilTheme.primary),
              const SizedBox(width: 24),
              _buildLegend('Actual Spend (\$K)', CivilTheme.secondary),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label,
            style:
                const TextStyle(fontSize: 12, color: CivilTheme.textPrimary)),
      ],
    );
  }

  BarChartGroupData _buildBarGroup(int x, double val1, double val2) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
            toY: val1,
            color: CivilTheme.primary,
            width: 14,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2), topRight: Radius.circular(2))),
        BarChartRodData(
            toY: val2,
            color: CivilTheme.secondary,
            width: 14,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2), topRight: Radius.circular(2))),
      ],
    );
  }
}
