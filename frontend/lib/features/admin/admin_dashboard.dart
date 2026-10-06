import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:ui';
import 'admin_shell.dart';
import '../../core/theme.dart';
import '../../core/providers/admin_provider.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).fetchTenants();
    });
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);
    if (adminState.isLoading) {
      return const AdminShell(child: Center(child: CircularProgressIndicator()));
    }
    return AdminShell(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Super Admin Command Center', style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: CivilTheme.textPrimary)),
            const SizedBox(height: 8),
            Text('Manage the CivilOS platform ecosystem', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 16)),
            const SizedBox(height: 32),
            
            // Analytics Row
            _buildAnalyticsRow(context, adminState),
            const SizedBox(height: 32),

            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Contractor Oversight Board
                Expanded(
                  flex: 2,
                  child: _buildContractorBoard(context, adminState),
                ),
                const SizedBox(width: 24),
                // System Logs Feed
                Expanded(
                  flex: 1,
                  child: _buildSystemLogs(context, adminState),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsRow(BuildContext context, AdminState state) {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = constraints.maxWidth > 1200 ? 4 : (constraints.maxWidth > 800 ? 2 : 1);
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 24,
          mainAxisSpacing: 24,
          childAspectRatio: 2.5,
          children: [
            _buildGlassStatCard('Active Tenants', state.analytics['active_users'].toString(), Icons.domain, CivilTheme.primary),
            _buildGlassStatCard('Verified Vendors', 'N/A', Icons.verified_user, CivilTheme.secondary),
            _buildGlassStatCard('Monthly MRR', '\$${state.analytics['total_mrr']}', Icons.monetization_on, CivilTheme.primary),
            _buildGlassStatCard('System Health', state.systemHealth.isNotEmpty ? state.systemHealth[0]['status'] : 'Optimal', Icons.monitor_heart, CivilTheme.secondary),
          ],
        );
      }
    );
  }

  Widget _buildGlassStatCard(String title, String value, IconData icon, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withValues(alpha: 0.2)),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withValues(alpha: 0.1), CivilTheme.background.withValues(alpha: 0.01)],
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(title, style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(value, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContractorBoard(BuildContext context, AdminState state) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ]
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Contractor Oversight', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add Tenant'),
              )
            ],
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
              columns: const [
                DataColumn(label: Text('Business Name')),
                DataColumn(label: Text('Plan')),
                DataColumn(label: Text('Projects')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Actions')),
              ],
              rows: state.tenants.map((c) {
                final isActive = c['is_active'] == true;
                final name = c['name'] ?? 'Unknown';
                final plan = (c['active_subscription'] != null && c['active_subscription']['plan'] != null) ? c['active_subscription']['plan']['name'] : 'Basic';
                final statusStr = isActive ? 'Active' : 'Suspended';
                return DataRow(
                  cells: [
                    DataCell(Row(
                      children: [
                        CircleAvatar(backgroundColor: CivilTheme.primary.withValues(alpha: 0.1), child: Text(name[0], style: const TextStyle(color: CivilTheme.primary))),
                        const SizedBox(width: 12),
                        Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      ],
                    )),
                    DataCell(Chip(label: Text(plan), backgroundColor: Colors.purple.withValues(alpha: 0.1), labelStyle: const TextStyle(color: Colors.purple))),
                    DataCell(Text('0')),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isActive ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(statusStr, style: TextStyle(color: isActive ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 12)),
                      )
                    ),
                    DataCell(
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert),
                        onSelected: (val) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$val clicked for ${c['name']}')));
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(value: 'view', child: Text('View Details')),
                          const PopupMenuItem(value: 'impersonate', child: Text('Impersonate')),
                          if (isActive)
                            const PopupMenuItem(value: 'suspend', child: Text('Suspend Tenant', style: TextStyle(color: Colors.red)))
                          else
                            const PopupMenuItem(value: 'activate', child: Text('Activate Tenant', style: TextStyle(color: Colors.green))),
                        ],
                      )
                    ),
                  ],
                );
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSystemLogs(BuildContext context, AdminState state) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('System Audit Logs', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.auditLogs.length > 5 ? 5 : state.auditLogs.length,
            separatorBuilder: (context, index) => const Divider(height: 32),
            itemBuilder: (context, index) {
              final log = state.auditLogs[index];
              final action = log['action'] ?? 'Unknown Action';
              final time = log['timestamp'] != null ? log['timestamp'].toString() : 'Now';
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.info, color: Colors.blue),
                title: Text(action, style: const TextStyle(fontSize: 14)),
                subtitle: Text(time, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              );
            },
          )
        ],
      ),
    );
  }
}
