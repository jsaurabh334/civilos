import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';
import '../site_diary/diary_screen.dart';
import '../work_orders/work_orders_screen.dart';
import '../inspections/inspections_screen.dart';
import '../checklists/checklists_screen.dart';
import '../photos/photos_screen.dart';
import 'live_tracking_tab.dart';
import 'package:go_router/go_router.dart';

class ProjectDetailScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> project;
  const ProjectDetailScreen({super.key, required this.project});

  @override
  ConsumerState<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<dynamic> _boqItems = [];
  List<dynamic> _expenses = [];
  List<dynamic> _laborWorkers = [];
  List<dynamic> _inventory = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 12, vsync: this);
    _fetchTabData();
  }

  Future<void> _fetchTabData() async {
    setState(() => _isLoading = true);
    try {
      final client = ref.read(apiClientProvider);
      final projId = widget.project['id'];
      final results = await Future.wait([
        client.get('/projects/$projId/boq/items', forceRefresh: true).catchError((_) => []),
        client.get('/expenses?project_id=$projId', forceRefresh: true).catchError((_) => []),
        client.get('/labor?project_id=$projId', forceRefresh: true).catchError((_) => []),
        client.get('/inventory?project_id=$projId', forceRefresh: true).catchError((_) => []),
      ]);
      if (mounted) {
        setState(() {
          _boqItems = (results[0] is List) ? results[0] : [];
          _expenses = (results[1] is List) ? results[1] : (results[1] is Map ? (results[1]['data'] ?? []) : []);
          _laborWorkers = (results[2] is List) ? results[2] : (results[2] is Map ? (results[2]['data'] ?? []) : []);
          _inventory = (results[3] is List) ? results[3] : (results[3] is Map ? (results[3]['data'] ?? []) : []);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildBoqTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_boqItems.isEmpty) {
      return const Center(child: Text('No BOQ items yet.', style: TextStyle(color: CivilTheme.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _boqItems.length,
      itemBuilder: (context, index) {
        final item = _boqItems[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(item['description'] ?? '', style: const TextStyle(color: CivilTheme.textPrimary)),
            subtitle: Text('${item['planned_quantity']} ${item['unit']} @ \$${item['rate']}'),
            trailing: Text('\$${(item['planned_quantity'] ?? 0) * (item['rate'] ?? 0)}', style: const TextStyle(color: CivilTheme.secondary)),
          ),
        );
      },
    );
  }

  Widget _buildExpensesTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_expenses.isEmpty) {
      return const Center(child: Text('No expenses recorded.', style: TextStyle(color: CivilTheme.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _expenses.length,
      itemBuilder: (context, index) {
        final exp = _expenses[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.receipt, color: CivilTheme.warning),
            title: Text(exp['description'] ?? '', style: const TextStyle(color: CivilTheme.textPrimary)),
            subtitle: Text('${exp['category']} - ${exp['expense_date']}'),
            trailing: Text('\$${exp['amount']}', style: const TextStyle(color: CivilTheme.error, fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Widget _buildLaborTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_laborWorkers.isEmpty) {
      return const Center(child: Text('No workers assigned.', style: TextStyle(color: CivilTheme.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _laborWorkers.length,
      itemBuilder: (context, index) {
        final worker = _laborWorkers[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(child: Text((worker['name'] ?? '?')[0], style: const TextStyle(color: Colors.white))),
            title: Text(worker['name'] ?? '', style: const TextStyle(color: CivilTheme.textPrimary)),
            subtitle: Text('${worker['skill_category']} - \$${worker['daily_rate']}/day'),
          ),
        );
      },
    );
  }

  Widget _buildInventoryTab() {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_inventory.isEmpty) {
      return const Center(child: Text('No inventory items.', style: TextStyle(color: CivilTheme.textSecondary)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _inventory.length,
      itemBuilder: (context, index) {
        final item = _inventory[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.inventory_2, color: CivilTheme.primary),
            title: Text(item['item_name'] ?? '', style: const TextStyle(color: CivilTheme.textPrimary)),
            subtitle: Text('Qty: ${item['quantity']} ${item['unit']}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (item['quantity'] ?? 0) > 0 ? CivilTheme.secondary.withValues(alpha: 0.2) : CivilTheme.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text((item['quantity'] ?? 0) > 0 ? 'In Stock' : 'Out of Stock', style: TextStyle(fontSize: 11, color: (item['quantity'] ?? 0) > 0 ? CivilTheme.secondary : CivilTheme.error)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOverviewTab() {
    final proj = widget.project;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(proj['name']?.toString() ?? '', style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  _infoRow('Status', proj['status']?.toString() ?? 'N/A'),
                  _infoRow('Location', proj['location']?.toString() ?? 'N/A'),
                  _infoRow('Budget', '\$${proj['budget'] ?? 0}'),
                  _infoRow('Type', proj['project_type']?.toString() ?? 'N/A'),
                  _infoRow('Created', proj['created_at']?.toString() ?? 'N/A'),
                ],
              ),
            ),
          ),
          if (proj['description'] != null && (proj['description'] as String).isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Description', style: TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(proj['description'], style: const TextStyle(color: CivilTheme.textSecondary)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: CivilTheme.textSecondary)),
          Text(value, style: const TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final proj = widget.project;
    return Scaffold(
      backgroundColor: CivilTheme.background,
      appBar: AppBar(
        backgroundColor: CivilTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/projects'),
        ),
        title: Text(proj['name']?.toString() ?? 'Project Details', style: const TextStyle(color: CivilTheme.textPrimary)),
        iconTheme: const IconThemeData(color: CivilTheme.textPrimary),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: CivilTheme.primary,
          labelColor: CivilTheme.primary,
          unselectedLabelColor: CivilTheme.textSecondary,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'BOQ'),
            Tab(text: 'Expenses'),
            Tab(text: 'Labor'),
            Tab(text: 'Inventory'),
            Tab(text: 'Daily Progress'),
            Tab(text: 'Work Orders'),
            Tab(text: 'Inspections'),
            Tab(text: 'Checklists'),
            Tab(text: 'Photos'),
            Tab(text: 'Tracking'),
            Tab(text: 'Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOverviewTab(),
          _buildBoqTab(),
          _buildExpensesTab(),
          _buildLaborTab(),
          _buildInventoryTab(),
          const DiaryScreen(isEmbedded: true),
          const WorkOrdersScreen(isEmbedded: true),
          const InspectionsScreen(isEmbedded: true),
          const ChecklistsScreen(isEmbedded: true),
          const PhotosScreen(isEmbedded: true),
          LiveTrackingTab(project: proj),
          _buildReportsTab(),
        ],
      ),
    );
  }

  Widget _buildReportsTab() {
    final projId = widget.project['id'];
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _reportCard('Cost Report', '/reports/cost?project_id=$projId', Icons.account_balance_wallet, CivilTheme.error),
        const SizedBox(height: 12),
        _reportCard('Labor Report', '/reports/labor?project_id=$projId', Icons.people, CivilTheme.primary),
        const SizedBox(height: 12),
        _reportCard('Machinery Report', '/reports/machinery?project_id=$projId', Icons.precision_manufacturing, CivilTheme.warning),
      ],
    );
  }

  Widget _reportCard(String title, String endpoint, IconData icon, Color color) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(backgroundColor: color.withValues(alpha: 0.2), child: Icon(icon, color: color)),
        title: Text(title, style: const TextStyle(color: CivilTheme.textPrimary)),
        subtitle: Text(endpoint, style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 12)),
        trailing: const Icon(Icons.open_in_new, color: CivilTheme.primary),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fetching $title...')));
          // In a real app, navigate to a report viewer with the endpoint
        },
      ),
    );
  }
}
