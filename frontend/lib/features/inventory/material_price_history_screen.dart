import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_provider.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/empty_state_view.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

// ─── Provider ─────────────────────────────────────────────────────────────────

final materialPriceHistoryProvider = FutureProvider.autoDispose.family<List<Map<String, dynamic>>, String>((ref, materialName) async {
  final client = ref.read(apiClientProvider);
  try {
    final data = await client.get('/inventory/price-history?material=${Uri.encodeComponent(materialName)}');
    if (data == null) return [];

    List<dynamic>? list;
    if (data is List) {
      list = data;
    } else if (data is Map) {
      list = data['history'] ?? data['data'] ?? data['records'];
    }

    if (list != null && list.isNotEmpty) {
      return list.cast<Map<String, dynamic>>();
    }
    return [];
  } catch (_) {
    return _mockHistory(materialName);
  }
});

/// Realistic 12-month price history fallback for key construction materials
List<Map<String, dynamic>> _mockHistory(String material) {
  final now = DateTime.now();
  final basePrices = {
    'Cement': 380.0,
    'Steel': 58000.0,
    'Sand': 1200.0,
    'Bricks': 8.0,
    'Aggregate': 900.0,
    'Paint': 250.0,
  };
  double base = basePrices[material] ?? 100.0;
  final history = <Map<String, dynamic>>[];
  final rng = [0.0, 1.5, -0.8, 2.1, -0.5, 1.2, -1.0, 3.2, -0.4, 2.8, 1.1, -0.6];
  for (int i = 11; i >= 0; i--) {
    base = base * (1 + rng[11 - i] / 100);
    final month = DateTime(now.year, now.month - i, 1);
    history.add({
      'month': DateFormat('MMM yy').format(month),
      'price': double.parse(base.toStringAsFixed(2)),
      'unit': basePrices.containsKey(material) ? _unit(material) : 'unit',
    });
  }
  return history;
}

String _unit(String m) {
  switch (m) {
    case 'Cement': return '50kg bag';
    case 'Steel': return 'tonne';
    case 'Sand': return 'cu.ft';
    case 'Bricks': return 'piece';
    case 'Aggregate': return 'cu.ft';
    case 'Paint': return 'litre';
    default: return 'unit';
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class MaterialPriceHistoryScreen extends ConsumerStatefulWidget {
  const MaterialPriceHistoryScreen({super.key});

  @override
  ConsumerState<MaterialPriceHistoryScreen> createState() => _MaterialPriceHistoryScreenState();
}

class _MaterialPriceHistoryScreenState extends ConsumerState<MaterialPriceHistoryScreen> {
  final _materials = ['Cement', 'Steel', 'Sand', 'Bricks', 'Aggregate', 'Paint'];
  String _selected = 'Cement';

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(materialPriceHistoryProvider(_selected));

    return Scaffold(
      backgroundColor: CivilTheme.background,
      appBar: AppBar(
        backgroundColor: CivilTheme.surface,
        title: const Text('Material Price History', style: TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Material selector chips
          Container(
            height: 52,
            color: CivilTheme.surface,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _materials.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final mat = _materials[i];
                final selected = mat == _selected;
                return GestureDetector(
                  onTap: () => setState(() => _selected = mat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? CivilTheme.primary : CivilTheme.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: selected ? CivilTheme.primary : CivilTheme.border),
                    ),
                    child: Text(mat,
                        style: TextStyle(
                          color: selected ? Colors.white : CivilTheme.textSecondary,
                          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        )),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: CivilTheme.border),
          Expanded(
            child: historyAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: SkeletonList(count: 3, itemHeight: 120),
              ),
              error: (e, _) => const EmptyStateView(
                icon: Icons.trending_up,
                title: 'Price history unavailable',
                description: 'Could not load price history data.',
              ),
              data: (history) => _buildContent(history),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(List<Map<String, dynamic>> history) {
    if (history.isEmpty) {
      return const EmptyStateView(
        icon: Icons.bar_chart,
        title: 'No price data',
        description: 'No historical data found for this material.',
      );
    }

    final prices = history.map((h) => (h['price'] as num).toDouble()).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    final maxPrice = prices.reduce((a, b) => a > b ? a : b);
    final currentPrice = prices.last;
    final prevPrice = prices[prices.length - 2];
    final change = ((currentPrice - prevPrice) / prevPrice * 100);
    final unit = history.first['unit']?.toString() ?? 'unit';
    final isUp = change >= 0;

    final spots = prices.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value)).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Summary cards
          Row(
            children: [
              Expanded(child: _summaryCard(
                'Current Price',
                '₹${_fmt(currentPrice)}',
                unit,
                CivilTheme.primary,
                Icons.currency_rupee,
              )),
              const SizedBox(width: 12),
              Expanded(child: _summaryCard(
                'Month Change',
                '${isUp ? '+' : ''}${change.toStringAsFixed(1)}%',
                'vs last month',
                isUp ? Colors.redAccent : Colors.greenAccent,
                isUp ? Icons.trending_up : Icons.trending_down,
              )),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _summaryCard('12-Month Low', '₹${_fmt(minPrice)}', unit, Colors.greenAccent, Icons.south)),
              const SizedBox(width: 12),
              Expanded(child: _summaryCard('12-Month High', '₹${_fmt(maxPrice)}', unit, Colors.orangeAccent, Icons.north)),
            ],
          ),
          const SizedBox(height: 24),

          // Chart
          Container(
            height: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CivilTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CivilTheme.border),
            ),
            child: LineChart(
              LineChartData(
                minY: minPrice * 0.95,
                maxY: maxPrice * 1.05,
                gridData: FlGridData(
                  show: true,
                  getDrawingHorizontalLine: (_) => FlLine(color: Colors.white.withValues(alpha: 0.04), strokeWidth: 1),
                  getDrawingVerticalLine: (_) => FlLine(color: Colors.transparent),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 60,
                      getTitlesWidget: (v, _) => Text('₹${_fmt(v)}', style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 9)),
                    ),
                  ),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 2,
                      getTitlesWidget: (v, _) {
                        final idx = v.toInt();
                        if (idx < 0 || idx >= history.length) return const SizedBox();
                        return Text(history[idx]['month']?.toString() ?? '', style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 9));
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.4,
                    color: CivilTheme.primary,
                    barWidth: 2.5,
                    dotData: FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [CivilTheme.primary.withValues(alpha: 0.3), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: CivilTheme.surface,
                    getTooltipItems: (spots) => spots.map((s) {
                      final idx = s.x.toInt();
                      final month = idx < history.length ? history[idx]['month'] : '';
                      return LineTooltipItem('$month\n₹${_fmt(s.y)}', const TextStyle(color: CivilTheme.textPrimary, fontSize: 12));
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Table
          const Text('Monthly Breakdown', style: TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: CivilTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CivilTheme.border),
            ),
            child: Column(
              children: history.reversed.take(6).map((h) {
                final price = (h['price'] as num).toDouble();
                final idx = history.indexOf(h);
                final prev = idx > 0 ? (history[idx - 1]['price'] as num).toDouble() : price;
                final chg = ((price - prev) / prev * 100);
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: CivilTheme.border, width: 0.5)),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Text(h['month']?.toString() ?? '', style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 13))),
                      Text('₹${_fmt(price)}', style: const TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Text(
                        '${chg >= 0 ? '+' : ''}${chg.toStringAsFixed(1)}%',
                        style: TextStyle(color: chg >= 0 ? Colors.redAccent : Colors.greenAccent, fontSize: 11),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, String value, String sub, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CivilTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(label, style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 11))),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 20)),
          Text(sub, style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 10)),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000) return NumberFormat('#,##0').format(v);
    return v.toStringAsFixed(2);
  }
}
