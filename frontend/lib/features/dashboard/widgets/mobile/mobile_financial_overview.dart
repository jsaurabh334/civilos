import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers/dashboard_provider.dart';

class MobileFinancialOverview extends ConsumerWidget {
  const MobileFinancialOverview({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final stats = dashboardState.stats ?? {};

    final monthlyBudgeted = (stats['monthly_budgeted'] as List<dynamic>?) ?? [];
    final monthlyActual = (stats['monthly_actual'] as List<dynamic>?) ?? [];
    final hasData = monthlyBudgeted.length >= 6 && monthlyActual.length >= 6;

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
                const Text('Financial Overview',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: CivilTheme.textPrimary)),
                Icon(Icons.more_horiz,
                    color: CivilTheme.textSecondary, size: 20),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend('Estimated', CivilTheme.primary),
                const SizedBox(width: 16),
                _buildLegend('Actual Spending', CivilTheme.warning),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: hasData
                      ? (monthlyBudgeted.cast<num>().reduce((a, b) => a > b ? a : b).toDouble() * 1.3)
                      : 4.0,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          const style = TextStyle(
                              color: CivilTheme.textSecondary, fontSize: 9);
                          List<String> months = [
                            'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                            'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                          ];
                          if (value.toInt() >= 0 && value.toInt() < 12) {
                            if (value.toInt() % 2 == 0) {
                              return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(months[value.toInt()],
                                      style: style));
                            }
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 22,
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
                                    fontSize: 9));
                          }
                          return Text('\$${value.toStringAsFixed(1)}M',
                              style: const TextStyle(
                                  color: CivilTheme.textSecondary,
                                  fontSize: 9));
                        },
                        reservedSize: 32,
                        interval: 1,
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
                    horizontalInterval: 1,
                    getDrawingHorizontalLine: (value) =>
                        const FlLine(color: CivilTheme.border, strokeWidth: 1),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: hasData
                      ? List.generate(monthlyBudgeted.length, (i) {
                          final x = i % 2 == 0 ? i * 2 + 0 : i * 2;
                          return _buildBarGroup(
                            i % 2 == 0 ? i * 2 : i * 2,
                            (monthlyBudgeted[i] as num).toDouble(),
                            i < monthlyActual.length
                                ? (monthlyActual[i] as num).toDouble()
                                : 0,
                          );
                        })
                      : [
                          _buildBarGroup(0, 2.8, 2.5),
                          _buildBarGroup(2, 3.2, 3.1),
                          _buildBarGroup(4, 2.5, 2.9),
                          _buildBarGroup(6, 3.5, 3.2),
                          _buildBarGroup(8, 3.1, 2.8),
                          _buildBarGroup(10, 3.2, 3.4),
                        ],
                ),
              ),
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
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 6),
        Text(label,
            style:
                const TextStyle(fontSize: 10, color: CivilTheme.textPrimary)),
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
            width: 8,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2), topRight: Radius.circular(2))),
        BarChartRodData(
            toY: val2,
            color: CivilTheme.warning,
            width: 8,
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(2), topRight: Radius.circular(2))),
      ],
    );
  }
}
