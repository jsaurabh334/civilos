import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/labor_provider.dart';
import '../../core/theme.dart';
import '../../core/download_helper.dart';
import '../../core/components/civil_data_table.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/skeleton_loader.dart';

class LaborScreen extends ConsumerStatefulWidget {
  const LaborScreen({super.key});

  @override
  ConsumerState<LaborScreen> createState() => _LaborScreenState();
}

class _LaborScreenState extends ConsumerState<LaborScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final labor = ref.read(laborProvider.notifier);
      labor.fetchWorkers();
      labor.fetchPayroll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddWorkerDialog() {
    final nameController = TextEditingController();
    String skill = 'Mason';
    final rateController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: CivilTheme.surface,
          title: const Text('Add Worker', style: TextStyle(color: CivilTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: CivilTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Name', labelStyle: TextStyle(color: CivilTheme.textSecondary)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: skill,
                dropdownColor: CivilTheme.surface,
                style: const TextStyle(color: CivilTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Skill', labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                items: ['Mason', 'Helper', 'Operator', 'Carpenter', 'Electrician', 'Plumber', 'Welder']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) { if (val != null) setDialogState(() => skill = val); },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: rateController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: CivilTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Daily Rate (₹)', labelStyle: TextStyle(color: CivilTheme.textSecondary)),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: CivilTheme.textSecondary))),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty || rateController.text.isEmpty) return;
                try {
                  await ref.read(laborProvider.notifier).createWorker(nameController.text.trim(), skill, double.tryParse(rateController.text) ?? 0);
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: CivilTheme.primary),
              child: const Text('Add', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final laborState = ref.watch(laborProvider);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    return Scaffold(
      backgroundColor: CivilTheme.background,
      body: Stack(
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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Top Header
                  Row(
                    children: [
                      if (!isDesktop)
                        IconButton(
                          icon: const Icon(Icons.menu, color: CivilTheme.textSecondary),
                          onPressed: () => Scaffold.of(context).openDrawer(),
                        ),
                      const Text('Labor Command Center', style: TextStyle(color: CivilTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.download, color: CivilTheme.secondary),
                        tooltip: 'Export CSV',
                        onPressed: () => downloadExport('/export/labor/csv', 'labor.csv'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showAddWorkerDialog(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Worker'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CivilTheme.primary,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // KPI Row
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: CivilTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CivilTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Active Workers Today', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
                              const SizedBox(height: 8),
                              Text('${laborState.workers.length}', style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: CivilTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CivilTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Total Weekly Payroll', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
                              const SizedBox(height: 8),
                              const Text('\$12,450.00', style: TextStyle(color: Colors.orange, fontSize: 28, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: CivilTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CivilTheme.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Overtime Hours', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
                              const SizedBox(height: 8),
                              const Text('48 hrs', style: TextStyle(color: Colors.redAccent, fontSize: 28, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Tab Bar
                  TabBar(
                    controller: _tabController,
                    indicatorColor: CivilTheme.primary,
                    labelColor: CivilTheme.primary,
                    unselectedLabelColor: CivilTheme.textSecondary,
                    dividerColor: CivilTheme.border,
                    tabs: const [
                      Tab(text: 'Worker Roster'),
                      Tab(text: 'Payroll Ledger'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Roster Tab
                        laborState.isLoading
                            ? const SkeletonList(count: 3, itemHeight: 80)
                            : laborState.workers.isEmpty
                                ? const EmptyStateView(
                                    icon: Icons.people,
                                    title: 'No workers',
                                    description: 'No workers are currently assigned to this tenant',
                                  )
                                : CivilDataTable(
                                    columns: const ['Name', 'Trade', 'Daily Wage', 'Status'],
                                    rows: laborState.workers.map((w) {
                                      return <Widget>[
                                        Text(w['name'] ?? 'Unknown', style: const TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.blueAccent.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(w['skill_category'] ?? 'Worker', style: const TextStyle(color: Colors.blueAccent, fontSize: 11)),
                                        ),
                                        Text('₹${w['daily_rate'] ?? 0}', style: const TextStyle(color: CivilTheme.textPrimary)),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.teal.withValues(alpha: 0.15),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: const Text('Active', style: TextStyle(color: Colors.teal, fontSize: 11)),
                                        ),
                                      ];
                                    }).toList(),
                                  ),
                        
                        // Payroll Tab
                        laborState.isLoading
                            ? const SkeletonList(count: 3, itemHeight: 80)
                            : laborState.payroll.isEmpty
                                ? const EmptyStateView(
                                    icon: Icons.payments,
                                    title: 'No payroll records',
                                    description: 'Payroll processing will appear here',
                                  )
                                : CivilDataTable(
                                    columns: const ['Worker', 'Week/Month', 'Total Wage', 'Advances', 'Net Payable'],
                                    rows: laborState.payroll.map((p) {
                                      final net = (p['net_payable'] as num?)?.toDouble() ?? 0.0;
                                      return <Widget>[
                                        Text(p['worker_name'] ?? 'Unknown', style: const TextStyle(color: CivilTheme.textPrimary)),
                                        Text(p['period'] ?? 'This Week', style: const TextStyle(color: CivilTheme.textSecondary)),
                                        Text('\$${p['gross_pay'] ?? '0.00'}', style: const TextStyle(color: CivilTheme.textPrimary)),
                                        Text('\$${p['deductions'] ?? '0.00'}', style: const TextStyle(color: Colors.redAccent)),
                                        Text('\$${net.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                      ];
                                    }).toList(),
                                  ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
