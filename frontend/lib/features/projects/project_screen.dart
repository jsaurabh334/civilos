import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_provider.dart';
import '../../core/providers/project_provider.dart';
import '../../core/providers/report_provider.dart';
import '../../core/theme.dart';
import '../../core/empty_state.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../core/components/civil_data_table.dart';

import '../../core/refresh_wrapper.dart';

class ProjectScreen extends ConsumerStatefulWidget {
  const ProjectScreen({super.key});

  @override
  ConsumerState<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends ConsumerState<ProjectScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectProvider.notifier).fetchProjects();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddProjectDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddProjectDialog(ref: ref),
    );
  }

  @override
  Widget build(BuildContext context) {
    final proj = ref.watch(projectProvider);
    final projects = proj.projects;
    final isLoading = proj.isLoading;
    final auth = ref.read(authProvider);
    final role = auth.currentUser?['role'] ?? '';
    final canAddProject = role == 'ContractorOwner' || role == 'ProjectManager';

    final filteredProjects = _searchQuery.isEmpty
        ? projects
        : projects
            .where((p) =>
                (p['name'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(_searchQuery) ||
                (p['location'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(_searchQuery))
            .toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;

        return Scaffold(
          backgroundColor: CivilTheme.background,
          body: Column(
            children: [
              if (isMobile)
                _buildMobileTopBar()
              else
                _buildDesktopTopBar(canAddProject, projects.length),
              Expanded(
                child: isLoading && projects.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: SkeletonList(count: 3, itemHeight: 120),
                      )
                    : projects.isEmpty
                        ? EmptyStateView(
                            icon: Icons.apartment,
                            title: 'No projects yet',
                            description:
                                'Create your first project to get started',
                            actionLabel: 'Add Project',
                            onAction: () => _showAddProjectDialog(),
                          )
                        : RefreshWrapper(
                            onRefresh: () async => await ref
                                .read(projectProvider.notifier)
                                .fetchProjects(),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: isMobile
                                  ? _buildMobileList(filteredProjects)
                                  : _buildDesktopGrid(
                                      filteredProjects, constraints.maxWidth),
                            ),
                          ),
              ),
            ],
          ),
          floatingActionButton: isMobile && canAddProject
              ? FloatingActionButton(
                  onPressed: _showAddProjectDialog,
                  backgroundColor: CivilTheme.primary,
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
        );
      },
    );
  }

  Widget _buildDesktopTopBar(bool canAddProject, int count) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: CivilTheme.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Projects Command Center', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: CivilTheme.textPrimary)),
                    SizedBox(height: 4),
                    Text('Portfolio Health & Status Overview', style: TextStyle(fontSize: 13, color: CivilTheme.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              if (canAddProject)
                ElevatedButton.icon(
                  onPressed: _showAddProjectDialog,
                  icon: const Icon(Icons.add, size: 16, color: Colors.white),
                  label: const Text('Add Project', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CivilTheme.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: CivilTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: CivilTheme.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Active Projects', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
                      const SizedBox(height: 8),
                      Text('$count', style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: CivilTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: CivilTheme.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Pipeline Value', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
                      const SizedBox(height: 8),
                      const Text('\$4.2M', style: TextStyle(color: Colors.blueAccent, fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: CivilTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: CivilTheme.border)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Delayed Projects', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
                      const SizedBox(height: 8),
                      const Text('2', style: TextStyle(color: Colors.redAccent, fontSize: 28, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTopBar() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('CONSTRUCTFLOW ERP',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.0)),
              Row(
                children: [
                  const Icon(Icons.search, color: CivilTheme.textSecondary),
                  const SizedBox(width: 12),
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.blueAccent,
                    child: const Text('JD',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () {
                      Scaffold.of(context).openDrawer();
                    },
                    child: const Icon(Icons.menu, color: CivilTheme.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: CivilTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CivilTheme.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search,
                          color: CivilTheme.textSecondary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) =>
                              setState(() => _searchQuery = val.toLowerCase()),
                          style: const TextStyle(
                              color: CivilTheme.textPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Search projects, managers...',
                            hintStyle:
                                TextStyle(color: CivilTheme.textSecondary),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: CivilTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CivilTheme.border),
                ),
                child: const Icon(Icons.tune,
                    color: CivilTheme.textSecondary, size: 18),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildDesktopGrid(List<dynamic> filteredProjects, double maxWidth) {
    return CivilDataTable(
      columns: const ['Project Name', 'Location', 'Budget', 'Status', 'Actions'],
      rows: filteredProjects.map((project) {
        return [
          Text(project['name']?.toString() ?? 'Unnamed', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(project['location']?.toString() ?? 'Unknown'),
          Text('₹${project['budget'] ?? 0}'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: CivilTheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CivilTheme.secondary.withValues(alpha: 0.5)),
            ),
            child: Text(project['status']?.toString() ?? 'Active', style: const TextStyle(color: CivilTheme.secondary, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          OutlinedButton(
            onPressed: () {
              ref.read(currentProjectProvider.notifier).setProject(project);
              context.go('/projects/${project['id']}', extra: project);
            },
            child: const Text('View'),
          ),
        ];
      }).toList(),
    );
  }

  Widget _buildMobileList(List<dynamic> filteredProjects) {
    return Column(
      children: filteredProjects.map((project) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: MobileProjectCard(project: project, ref: ref),
        );
      }).toList(),
    );
  }
}

class DesktopProjectCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> project;
  final WidgetRef ref;

  const DesktopProjectCard(
      {super.key, required this.project, required this.ref});

  @override
  ConsumerState<DesktopProjectCard> createState() => _DesktopProjectCardState();
}

class _DesktopProjectCardState extends ConsumerState<DesktopProjectCard> {
  void _fetchAndShowReport(String title, Future<void> Function() fetchFn) async {
    try {
      await fetchFn();
      if (!mounted) return;
      final reports = ref.read(reportProvider);
      final data = title.contains('Cost') ? reports.costReport
          : title.contains('Labor') ? reports.laborReport
          : reports.machineryReport;

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: CivilTheme.surface,
          title: Text(title, style: const TextStyle(color: CivilTheme.textPrimary)),
          content: data == null
              ? const SizedBox(height: 60, child: Center(child: CircularProgressIndicator()))
              : SizedBox(
                  width: 400,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: data.entries.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(e.key, style: const TextStyle(color: CivilTheme.textSecondary)),
                            Text('${e.value}', style: const TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      )).toList(),
                    ),
                  ),
                ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: CivilTheme.textSecondary))),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load report: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: CivilTheme.error),
        );
      }
    }
  }

  void _showReports() {
    final notifier = ref.read(reportProvider.notifier);
    showModalBottomSheet(
      context: context,
      backgroundColor: CivilTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Project Reports', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: CivilTheme.textPrimary)),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close, color: CivilTheme.textSecondary)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('Select a report type to view', style: TextStyle(color: CivilTheme.textSecondary)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _fetchAndShowReport('Cost Report', () => notifier.fetchCostReport());
                },
                icon: const Icon(Icons.account_balance_wallet, color: Colors.white),
                label: const Text('View Cost Report', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: CivilTheme.primary, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _fetchAndShowReport('Labor Report', () => notifier.fetchLaborReport());
                },
                icon: const Icon(Icons.people, color: Colors.white),
                label: const Text('View Labor Report', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: CivilTheme.secondary, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _fetchAndShowReport('Machinery Report', () => notifier.fetchMachineryReport());
                },
                icon: const Icon(Icons.precision_manufacturing, color: Colors.white),
                label: const Text('View Machinery Report', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, padding: const EdgeInsets.symmetric(vertical: 16)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final boqItems = widget.project['boq_items'] as List<dynamic>? ?? [];
    double totalBudget = 0;
    double totalPlanned = 0;
    double totalActual = 0;
    for (var item in boqItems) {
      final qty = (item['planned_quantity'] as num?)?.toDouble() ?? 0.0;
      final rate = (item['rate'] as num?)?.toDouble() ?? 0.0;
      totalBudget += qty * rate;
      totalPlanned += qty;
      totalActual += (item['actual_quantity'] as num?)?.toDouble() ?? 0.0;
    }
    final progressPercent = totalPlanned > 0 ? (totalActual / totalPlanned) : 0.0;

    final statusStr = (widget.project['status'] as String?) ?? 'Active';
    Color statusColor = CivilTheme.primary;
    if (statusStr.toLowerCase() == 'completed') {
      statusColor = CivilTheme.secondary;
    }
    if (statusStr.toLowerCase() == 'in progress') {
      statusColor = CivilTheme.warning;
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CivilTheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CivilTheme.border),
        boxShadow: [
          BoxShadow(
            color: statusColor.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 2,
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: CivilTheme.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.apartment,
                    color: CivilTheme.textSecondary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Project Name',
                        style: TextStyle(
                            fontSize: 10, color: CivilTheme.textSecondary)),
                    const SizedBox(height: 2),
                    Text(widget.project['name'] ?? 'Unknown Project',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: CivilTheme.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              Icon(Icons.more_vert, color: CivilTheme.textSecondary, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Text('Status: ',
                  style:
                      TextStyle(fontSize: 12, color: CivilTheme.textSecondary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                ),
                child: Text(statusStr,
                    style: TextStyle(
                        fontSize: 10,
                        color: statusColor,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildIconRow(
                        Icons.person_outline, 'Project Manager', 'Alex Rivera'),
                    const SizedBox(height: 12),
                    _buildIconRow(Icons.location_on_outlined, 'Location',
                        widget.project['location'] ?? 'N/A'),
                    const SizedBox(height: 12),
                    _buildIconRow(Icons.calendar_today_outlined, 'Start Date',
                        'Mar 1, 2023'),
                    const SizedBox(height: 12),
                    _buildIconRow(
                        Icons.account_balance_wallet_outlined,
                        'Budget',
                        '\$2.1M / \$${(totalBudget / 1000000).toStringAsFixed(1)}M'),
                  ],
                ),
              ),
              SizedBox(
                height: 80,
                width: 80,
                child: Stack(
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 0,
                        centerSpaceRadius: 32,
                        startDegreeOffset: -90,
                        sections: [
                          PieChartSectionData(
                              color: statusColor,
                              value: progressPercent * 100,
                              title: '',
                              radius: 6),
                          PieChartSectionData(
                              color: CivilTheme.border,
                              value: (1 - progressPercent) * 100,
                              title: '',
                              radius: 6),
                        ],
                      ),
                    ),
                    Center(
                      child: Text('${(progressPercent * 100).toInt()}%',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: CivilTheme.textPrimary)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    ref.read(currentProjectProvider.notifier).setProject(widget.project);
                    context.go('/projects/${widget.project['id']}', extra: widget.project);
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: CivilTheme.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('View Details',
                      style: TextStyle(color: CivilTheme.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _showReports,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: CivilTheme.border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Report',
                      style: TextStyle(color: CivilTheme.textSecondary)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: CivilTheme.textSecondary, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 10, color: CivilTheme.textSecondary)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 12,
                      color: CivilTheme.textPrimary,
                      fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      ],
    );
  }
}

class MobileProjectCard extends ConsumerStatefulWidget {
  final Map<String, dynamic> project;
  final WidgetRef ref;

  const MobileProjectCard(
      {super.key, required this.project, required this.ref});

  @override
  ConsumerState<MobileProjectCard> createState() => _MobileProjectCardState();
}

class _MobileProjectCardState extends ConsumerState<MobileProjectCard> {
  @override
  Widget build(BuildContext context) {
    final boqItems = widget.project['boq_items'] as List<dynamic>? ?? [];
    double totalBudget = 0;
    double totalPlanned = 0;
    double totalActual = 0;
    for (var item in boqItems) {
      final qty = (item['planned_quantity'] as num?)?.toDouble() ?? 0.0;
      final rate = (item['rate'] as num?)?.toDouble() ?? 0.0;
      totalBudget += qty * rate;
      totalPlanned += qty;
      totalActual += (item['actual_quantity'] as num?)?.toDouble() ?? 0.0;
    }
    final mobileProgress = totalPlanned > 0 ? (totalActual / totalPlanned) : 0.0;

    final statusStr = (widget.project['status'] as String?) ?? 'ACTIVE';
    Color statusColor = Colors.blueAccent;
    if (statusStr.toLowerCase() == 'on hold') statusColor = CivilTheme.warning;

    return Container(
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
              Expanded(
                  child: Text(
                      (widget.project['name'] ?? 'Unknown')
                          .toString()
                          .toUpperCase(),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: CivilTheme.textPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(statusStr.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Project ID: CFT-001',
                  style:
                      TextStyle(fontSize: 12, color: CivilTheme.textSecondary)),
              Text('${(mobileProgress * 100).toInt()}%',
                  style:
                      const TextStyle(fontSize: 12, color: CivilTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Client: Skyline Developers',
              style: TextStyle(fontSize: 12, color: CivilTheme.textSecondary)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      size: 14, color: CivilTheme.textSecondary),
                  const SizedBox(width: 4),
                  Text(widget.project['location'] ?? 'New York, NY',
                      style: const TextStyle(
                          fontSize: 12, color: CivilTheme.textSecondary)),
                ],
              ),
              SizedBox(
                width: 100,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: mobileProgress.clamp(0.0, 1.0),
                    backgroundColor: CivilTheme.border,
                    color: statusColor,
                    minHeight: 6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 12, color: CivilTheme.textSecondary),
                        const SizedBox(width: 4),
                        const Text('Status: ',
                            style: TextStyle(
                                fontSize: 11, color: CivilTheme.textSecondary)),
                        Text('In Progress',
                            style: TextStyle(
                                fontSize: 11, color: CivilTheme.textPrimary)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 12, color: CivilTheme.textSecondary),
                        const SizedBox(width: 4),
                        const Text('PM: ',
                            style: TextStyle(
                                fontSize: 11, color: CivilTheme.textSecondary)),
                        Text('Sarah Jenkins',
                            style: TextStyle(
                                fontSize: 11, color: CivilTheme.textPrimary)),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('End Date: Oct 15, 2024',
                        style: const TextStyle(
                            fontSize: 11, color: CivilTheme.textSecondary)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            size: 12, color: CivilTheme.textSecondary),
                        const SizedBox(width: 4),
                        const Text('Budget: ',
                            style: TextStyle(
                                fontSize: 11, color: CivilTheme.textSecondary)),
                        Text('\$${(totalBudget / 1000000).toStringAsFixed(1)}M',
                            style: const TextStyle(
                                fontSize: 11, color: CivilTheme.textPrimary)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// AddProjectDialog remains the same to preserve functionality
class AddProjectDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const AddProjectDialog({super.key, required this.ref});

  @override
  ConsumerState<AddProjectDialog> createState() => _AddProjectDialogState();
}

class _AddProjectDialogState extends ConsumerState<AddProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _locController = TextEditingController();
  final _tenderNoController = TextEditingController();
  final _tenderDetailsController = TextEditingController();

  String _projectType = 'Private';

  final List<Map<String, dynamic>> _boqItems = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _locController.dispose();
    _tenderNoController.dispose();
    _tenderDetailsController.dispose();
    super.dispose();
  }

  void _addBOQRow() {
    setState(() {
      _boqItems.add({
        'description': '',
        'unit': 'Cum',
        'planned_quantity': 0.0,
        'rate': 0.0,
      });
    });
  }

  void _removeBOQRow(int index) {
    setState(() {
      _boqItems.removeAt(index);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    _formKey.currentState!.save();

    try {
      await widget.ref.read(projectProvider.notifier).createProject(
            _nameController.text.trim(),
            _descController.text.trim(),
            _locController.text.trim(),
            _projectType,
            _projectType == 'Government' ? _tenderNoController.text.trim() : '',
            _projectType == 'Government' ? _tenderDetailsController.text.trim() : '',
            _boqItems,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed: $e'), backgroundColor: CivilTheme.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CivilTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Row(
                  children: [
                    Icon(Icons.add_business,
                        color: CivilTheme.primary, size: 28),
                    SizedBox(width: 12),
                    Text('Create New Project',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: CivilTheme.textPrimary)),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          controller: _nameController,
                          style: const TextStyle(color: CivilTheme.textPrimary),
                          decoration: const InputDecoration(
                              labelText: 'Project Name',
                              labelStyle:
                                  TextStyle(color: CivilTheme.textSecondary)),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Project name is required'
                              : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descController,
                          style: const TextStyle(color: CivilTheme.textPrimary),
                          decoration: const InputDecoration(
                              labelText: 'Description',
                              labelStyle:
                                  TextStyle(color: CivilTheme.textSecondary)),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _locController,
                          style: const TextStyle(color: CivilTheme.textPrimary),
                          decoration: const InputDecoration(
                              labelText: 'Location',
                              labelStyle:
                                  TextStyle(color: CivilTheme.textSecondary)),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Location is required'
                              : null,
                        ),
                        const SizedBox(height: 24),
                        const Text('Project Type',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: CivilTheme.textPrimary)),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(value: 'Private', label: Text('Private Project')),
                            ButtonSegment(value: 'Government', label: Text('Government Tender')),
                          ],
                          selected: {_projectType},
                          onSelectionChanged: (Set<String> newSelection) {
                            setState(() {
                              _projectType = newSelection.first;
                            });
                          },
                          style: SegmentedButton.styleFrom(
                            backgroundColor: CivilTheme.background,
                            foregroundColor: CivilTheme.textPrimary,
                            selectedForegroundColor: Colors.white,
                            selectedBackgroundColor: CivilTheme.primary,
                          ),
                        ),
                        if (_projectType == 'Government') ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _tenderNoController,
                            style: const TextStyle(color: CivilTheme.textPrimary),
                            decoration: const InputDecoration(
                                labelText: 'Tender Number',
                                labelStyle:
                                    TextStyle(color: CivilTheme.textSecondary)),
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Tender Number is required'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _tenderDetailsController,
                            style: const TextStyle(color: CivilTheme.textPrimary),
                            decoration: const InputDecoration(
                                labelText: 'Tender Details',
                                labelStyle:
                                    TextStyle(color: CivilTheme.textSecondary)),
                            maxLines: 2,
                          ),
                        ],
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('BOQ Items Estimation',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: CivilTheme.textPrimary)),
                            TextButton.icon(
                              onPressed: _addBOQRow,
                              icon: const Icon(Icons.add,
                                  size: 16, color: CivilTheme.primary),
                              label: const Text('Add Item',
                                  style: TextStyle(color: CivilTheme.primary)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (_boqItems.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: CivilTheme.background,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: CivilTheme.border),
                            ),
                            child: const Text(
                              'Click "Add Item" above to specify material estimation (cement, steel, sand etc.)',
                              style: TextStyle(
                                  color: CivilTheme.textSecondary,
                                  fontStyle: FontStyle.italic),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _boqItems.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: TextFormField(
                                        style: const TextStyle(
                                            color: CivilTheme.textPrimary,
                                            fontSize: 12),
                                        decoration: const InputDecoration(
                                            labelText: 'Description',
                                            labelStyle: TextStyle(
                                                color:
                                                    CivilTheme.textSecondary),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 10)),
                                        onSaved: (v) => _boqItems[index]
                                            ['description'] = v ?? '',
                                        validator: (v) =>
                                            (v == null || v.isEmpty)
                                                ? 'Required'
                                                : null,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 1,
                                      child: TextFormField(
                                        initialValue: 'Cum',
                                        style: const TextStyle(
                                            color: CivilTheme.textPrimary,
                                            fontSize: 12),
                                        decoration: const InputDecoration(
                                            labelText: 'Unit',
                                            labelStyle: TextStyle(
                                                color:
                                                    CivilTheme.textSecondary),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 10)),
                                        onSaved: (v) => _boqItems[index]
                                            ['unit'] = v ?? 'Cum',
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 1,
                                      child: TextFormField(
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d+\.?\d*'))
                                        ],
                                        style: const TextStyle(
                                            color: CivilTheme.textPrimary,
                                            fontSize: 12),
                                        decoration: const InputDecoration(
                                            labelText: 'Qty',
                                            labelStyle: TextStyle(
                                                color:
                                                    CivilTheme.textSecondary),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 10)),
                                        onSaved: (v) => _boqItems[index]
                                                ['planned_quantity'] =
                                            double.tryParse(v ?? '') ?? 0.0,
                                        validator: (v) {
                                          if (v == null || v.isEmpty) {
                                            return 'Req';
                                          }
                                          final val = double.tryParse(v);
                                          if (val == null || val <= 0) {
                                            return '> 0';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      flex: 1,
                                      child: TextFormField(
                                        keyboardType: const TextInputType
                                            .numberWithOptions(decimal: true),
                                        inputFormatters: [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'^\d+\.?\d*'))
                                        ],
                                        style: const TextStyle(
                                            color: CivilTheme.textPrimary,
                                            fontSize: 12),
                                        decoration: const InputDecoration(
                                            labelText: 'Rate',
                                            labelStyle: TextStyle(
                                                color:
                                                    CivilTheme.textSecondary),
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 10)),
                                        onSaved: (v) => _boqItems[index]
                                                ['rate'] =
                                            double.tryParse(v ?? '') ?? 0.0,
                                        validator: (v) {
                                          if (v == null || v.isEmpty) {
                                            return 'Req';
                                          }
                                          final val = double.tryParse(v);
                                          if (val == null || val <= 0) {
                                            return '> 0';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: CivilTheme.error),
                                      onPressed: () => _removeBOQRow(index),
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel',
                          style: TextStyle(color: CivilTheme.textSecondary)),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                          backgroundColor: CivilTheme.primary),
                      child: const Text('Create Project',
                          style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
