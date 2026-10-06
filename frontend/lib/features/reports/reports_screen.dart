import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/report_provider.dart';
import '../../core/theme.dart';
import '../../core/download_helper.dart';

class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedYear = DateTime.now().year.toString();
  String? _selectedMonth;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAll();
    });
  }

  void _loadAll() {
    ref.read(reportProvider.notifier).fetchCostReport(year: _selectedYear, month: _selectedMonth);
    ref.read(reportProvider.notifier).fetchLaborReport();
    ref.read(reportProvider.notifier).fetchMachineryReport();
  }

  @override
  Widget build(BuildContext context) {
    final reportState = ref.watch(reportProvider);

    return Scaffold(
      backgroundColor: CivilTheme.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;
          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF222B38), Color(0xFF161F2E)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isMobile ? 600 : 1000),
                  child: Column(
                    children: [
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Reports & Analytics',
                                  style: TextStyle(
                                      color: CivilTheme.textPrimary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                              Row(
                                children: [
                                  _buildDropdown('Year', _selectedYear, ['2024', '2025', '2026', '2027'], (v) {
                                    setState(() => _selectedYear = v!);
                                    _loadAll();
                                  }),
                                  const SizedBox(width: 12),
                                  _buildDropdown('Month', _selectedMonth ?? 'All',
                                      ['All', '01', '02', '03', '04', '05', '06', '07', '08', '09', '10', '11', '12'],
                                      (v) {
                                    setState(() => _selectedMonth = v == 'All' ? null : v);
                                    _loadAll();
                                  }),
                                  IconButton(
                                    icon: const Icon(Icons.download, color: CivilTheme.secondary),
                                    tooltip: 'Export Expenses CSV',
                                    onPressed: () => downloadExport('/export/expenses/csv', 'expenses.csv'),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.download, color: CivilTheme.primary),
                                    tooltip: 'Export Labor CSV',
                                    onPressed: () => downloadExport('/export/labor/csv', 'labor.csv'),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.refresh, color: CivilTheme.primary),
                                    onPressed: _loadAll,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (reportState.isLoading)
                        const Expanded(child: Center(child: CircularProgressIndicator()))
                      else
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildCostReport(reportState.costReport),
                                const SizedBox(height: 20),
                                _buildLaborReport(reportState.laborReport),
                                const SizedBox(height: 20),
                                _buildMachineryReport(reportState.machineryReport),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: CivilTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CivilTheme.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          dropdownColor: CivilTheme.surface,
          style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 12),
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCard(String title, List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CivilTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CivilTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: CivilTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...rows,
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 14)),
          Text(value,
              style: TextStyle(
                  color: valueColor ?? CivilTheme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildCostReport(Map<String, dynamic>? report) {
    if (report == null) return const SizedBox.shrink();
    final total = report['total'] ?? 0;
    final byCategory = report['by_category'] as List? ?? [];
    final byMonth = report['by_month'] as List? ?? [];

    return _buildCard('Cost Analysis', [
      _buildStatRow('Total Expenses', '₹${(total as num).toStringAsFixed(2)}', valueColor: CivilTheme.secondary),
      const Divider(color: CivilTheme.border),
      if (byCategory.isNotEmpty) ...[
        const Text('By Category',
            style: TextStyle(color: CivilTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...byCategory.take(5).map((c) => _buildStatRow(
          c['category']?.toString() ?? 'Other',
          '₹${(c['amount'] as num).toStringAsFixed(2)} (${c['count']})',
        )),
      ],
      if (byMonth.isNotEmpty) ...[
        const Divider(color: CivilTheme.border),
        const Text('Monthly Trend',
            style: TextStyle(color: CivilTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...byMonth.map((m) => _buildStatRow(
          'Month ${m['month']}',
          '₹${(m['amount'] as num).toStringAsFixed(2)}',
        )),
      ],
    ]);
  }

  Widget _buildLaborReport(Map<String, dynamic>? report) {
    if (report == null) return const SizedBox.shrink();
    final totalWorkers = report['total_workers'] ?? 0;
    final bySkill = report['by_skill'] as List? ?? [];
    final monthlyPayroll = report['monthly_payroll'] ?? 0;
    final presentToday = report['present_today'] ?? 0;
    final attendanceRate = report['attendance_rate'] ?? 0;

    return _buildCard('Labor & Attendance', [
      _buildStatRow('Total Workers', totalWorkers.toString(), valueColor: CivilTheme.primary),
      _buildStatRow('Present Today', presentToday.toString()),
      _buildStatRow('Attendance Rate', '${(attendanceRate as num).toStringAsFixed(1)}%'),
      _buildStatRow('Monthly Payroll', '₹${(monthlyPayroll as num).toStringAsFixed(2)}', valueColor: CivilTheme.secondary),
      if (bySkill.isNotEmpty) ...[
        const Divider(color: CivilTheme.border),
        const Text('By Skill',
            style: TextStyle(color: CivilTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...bySkill.map((s) => _buildStatRow(
          s['skill']?.toString() ?? 'Other',
          '${s['count']} (₹${(s['avg_daily_rate'] as num).toStringAsFixed(0)}/day)',
        )),
      ],
    ]);
  }

  Widget _buildMachineryReport(Map<String, dynamic>? report) {
    if (report == null) return const SizedBox.shrink();
    final total = report['total_machinery'] ?? 0;
    final byStatus = report['by_status'] as List? ?? [];
    final totalHours = report['total_hours'] ?? 0;
    final avgRate = report['avg_hourly_rate'] ?? 0;

    return _buildCard('Machinery Utilization', [
      _buildStatRow('Total Machinery', total.toString(), valueColor: CivilTheme.primary),
      _buildStatRow('Total Run Hours', (totalHours as num).toStringAsFixed(1)),
      _buildStatRow('Avg Hourly Rate', '₹${(avgRate as num).toStringAsFixed(2)}'),
      if (byStatus.isNotEmpty) ...[
        const Divider(color: CivilTheme.border),
        const Text('By Status',
            style: TextStyle(color: CivilTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        ...byStatus.map((s) => _buildStatRow(
          s['status']?.toString() ?? 'Unknown',
          s['count'].toString(),
        )),
      ],
    ]);
  }
}
