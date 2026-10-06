import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/admin_provider.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/components/civil_data_table.dart';
import 'tenant_details_screen.dart';
import '../auth/login_screen.dart';
import '../chat/b2b_chat_screen.dart';

class AdminScreen extends ConsumerStatefulWidget {
  const AdminScreen({super.key});

  @override
  ConsumerState<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends ConsumerState<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminProvider.notifier).fetchTenants();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _updateFeature(Map<String, dynamic> tenant, String key, bool value) async {
    final adminProv = ref.read(adminProvider.notifier);
    Map<String, dynamic> flags = {};
    final flagsStr = tenant['feature_flags'];
    if (flagsStr != null) {
      try {
        if (flagsStr is String) {
          flags = jsonDecode(flagsStr) as Map<String, dynamic>;
        } else {
          flags = Map<String, dynamic>.from(flagsStr);
        }
      } catch (_) {}
    }

    flags[key] = value;
    final newFlagsJson = jsonEncode(flags);

    try {
      final tId = int.tryParse(tenant['id'].toString()) ?? 0;
      await adminProv.toggleFeatureFlag(tId, newFlagsJson);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Config updated'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    }
  }

  Map<String, dynamic> _getFlags(dynamic flagsStr) {
    if (flagsStr == null) return {};
    try {
      if (flagsStr is String) return jsonDecode(flagsStr) as Map<String, dynamic>;
      return Map<String, dynamic>.from(flagsStr);
    } catch (_) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    final adminProv = ref.watch(adminProvider);
    final tenants = adminProv.tenants;
    final analytics = adminProv.analytics;
    final systemHealth = adminProv.systemHealth;
    final auditLogs = adminProv.auditLogs;
    final isDesktop = MediaQuery.of(context).size.width > 900;
    
    final activeTenants = analytics['active_users'] ?? 0;
    final mrr = analytics['total_mrr'] ?? 0;

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
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: CivilTheme.surface.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.admin_panel_settings, color: Colors.purpleAccent, size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Text('Super Admin Console', style: TextStyle(color: CivilTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.forum_rounded, color: Colors.lightBlueAccent),
                        tooltip: 'B2B Network Chat',
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const B2BChatScreen()));
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: Colors.redAccent),
                        tooltip: 'Sign Out',
                        onPressed: () async {
                          await ref.read(authProvider.notifier).logout();
                          if (context.mounted) {
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(builder: (_) => const LoginScreen()),
                              (route) => false,
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // MRR Command Center
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: CivilTheme.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: CivilTheme.border)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Monthly Recurring Revenue (MRR)', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
                              const SizedBox(height: 8),
                              Text('\$$mrr', style: const TextStyle(color: Colors.greenAccent, fontSize: 28, fontWeight: FontWeight.bold)),
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
                              const Text('Active Users', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
                              const SizedBox(height: 8),
                              Text('$activeTenants', style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
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
                              const Text('System Health & Uptime', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
                              const SizedBox(height: 8),
                              const Text('99.98%', style: TextStyle(color: Colors.blueAccent, fontSize: 28, fontWeight: FontWeight.bold)),
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
                    indicatorColor: Colors.purpleAccent,
                    labelColor: Colors.purpleAccent,
                    unselectedLabelColor: CivilTheme.textSecondary,
                    dividerColor: CivilTheme.border,
                    tabs: const [
                      Tab(text: 'Tenants & Billing'),
                      Tab(text: 'Feature Flags (Tiers)'),
                      Tab(text: 'System Health'),
                      Tab(text: 'Global Audit Logs'),
                      Tab(text: 'Global Users'),
                      Tab(text: 'Support Desk'),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // 1. Tenants
                        adminProv.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : CivilDataTable(
                                columns: const ['Workspace Name', 'Domain', 'Subscription', 'Status', 'Actions'],
                                rows: tenants.map((t) {
                                  return <Widget>[
                                    Text(t['name'] ?? 'Unknown', style: const TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold)),
                                    Text(t['domain'] ?? '', style: const TextStyle(color: CivilTheme.textSecondary)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.purpleAccent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                                      child: const Text('PRO', style: TextStyle(color: Colors.purpleAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.teal.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                                      child: const Text('ACTIVE', style: TextStyle(color: Colors.teal, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.visibility, size: 16, color: CivilTheme.primary), 
                                          tooltip: 'View Details', 
                                          onPressed: () {
                                            Navigator.push(context, MaterialPageRoute(builder: (_) => TenantDetailsScreen(tenant: t)));
                                          }
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.login, size: 16, color: CivilTheme.primary), 
                                          tooltip: 'Impersonate', 
                                          onPressed: () async {
                                            try {
                                              await ref.read(adminProvider.notifier).impersonateTenant(t['id'], ref);
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impersonating ${t['name']}')));
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Impersonation blocked or failed.')));
                                            }
                                          }
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.block, size: 16, color: CivilTheme.error), 
                                          tooltip: 'Suspend', 
                                          onPressed: () {
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Tenant ${t['name']} suspended.')));
                                          }
                                        ),
                                      ],
                                    ),
                                  ];
                                }).toList(),
                              ),
                        
                        // 2. Feature Flags
                        adminProv.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : CivilDataTable(
                                columns: const ['Tenant', 'Inventory Module', 'Advanced AI', 'Custom Roles'],
                                rows: tenants.map((t) {
                                  final flags = _getFlags(t['feature_flags']);
                                  final hasInv = flags['inventory'] == true;
                                  final hasAI = flags['advanced_ai'] == true;
                                  final hasRoles = flags['custom_roles'] == true;
                                  return <Widget>[
                                    Text(t['name'] ?? '', style: const TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold)),
                                    Switch(value: hasInv, activeThumbColor: Colors.purpleAccent, onChanged: (v) => _updateFeature(t, 'inventory', v)),
                                    Switch(value: hasAI, activeThumbColor: Colors.purpleAccent, onChanged: (v) => _updateFeature(t, 'advanced_ai', v)),
                                    Switch(value: hasRoles, activeThumbColor: Colors.purpleAccent, onChanged: (v) => _updateFeature(t, 'custom_roles', v)),
                                  ];
                                }).toList(),
                              ),

                        // 3. System Health
                        adminProv.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : CivilDataTable(
                                columns: const ['Service', 'Status', 'Latency', 'Storage Usage'],
                                rows: systemHealth.map((h) {
                                  final isHealthy = h['status'] == 'Healthy';
                                  return <Widget>[
                                    Text(h['service'] ?? '', style: const TextStyle(color: CivilTheme.textPrimary)),
                                    Text(h['status'] ?? '', style: TextStyle(color: isHealthy ? Colors.green : Colors.red)),
                                    Text(h['latency'] ?? '', style: const TextStyle(color: CivilTheme.textSecondary)),
                                    Text(h['storage_usage'] ?? '', style: const TextStyle(color: CivilTheme.textSecondary)),
                                  ];
                                }).toList(),
                              ),

                        // 4. Global Audit Logs
                        adminProv.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : CivilDataTable(
                                columns: const ['Timestamp', 'Actor', 'Tenant', 'Action', 'IP Address'],
                                rows: auditLogs.map((log) {
                                  return <Widget>[
                                    Text(log['timestamp']?.toString().split('T').first ?? '', style: const TextStyle(color: CivilTheme.textSecondary)),
                                    Text(log['actor'] ?? 'System', style: const TextStyle(color: Colors.purpleAccent)),
                                    Text(log['tenant'] ?? 'Global', style: const TextStyle(color: CivilTheme.textSecondary)),
                                    Text(log['action'] ?? '', style: const TextStyle(color: CivilTheme.textPrimary)),
                                    Text(log['ip_address'] ?? 'Unknown', style: const TextStyle(color: CivilTheme.textSecondary)),
                                  ];
                                }).toList(),
                              ),
                        // 5. Global Users
                        adminProv.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : CivilDataTable(
                                columns: const ['Name', 'Email', 'Role', 'Tenant ID', '2FA Enabled', 'Actions'],
                                rows: adminProv.globalUsers.map((u) {
                                  return <Widget>[
                                    Text(u['name'] ?? '', style: const TextStyle(color: CivilTheme.textPrimary)),
                                    Text(u['email'] ?? '', style: const TextStyle(color: CivilTheme.textSecondary)),
                                    Text(u['role'] ?? '', style: const TextStyle(color: CivilTheme.textPrimary)),
                                    Text(u['tenant_id']?.toString() ?? 'N/A', style: const TextStyle(color: CivilTheme.textSecondary)),
                                    Text(u['two_factor_enabled'] == true ? 'Yes' : 'No', style: TextStyle(color: u['two_factor_enabled'] == true ? Colors.green : Colors.red)),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.block, size: 16, color: CivilTheme.error),
                                          tooltip: 'Force Logout / Suspend',
                                          onPressed: () {
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('User ${u['name']} suspended.')));
                                          }
                                        ),
                                      ],
                                    ),
                                  ];
                                }).toList(),
                              ),

                        // 6. Support Desk
                        adminProv.isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : CivilDataTable(
                                columns: const ['Subject', 'Priority', 'Status', 'Tenant ID', 'Actions'],
                                rows: adminProv.supportTickets.map((t) {
                                  return <Widget>[
                                    Text(t['subject'] ?? '', style: const TextStyle(color: CivilTheme.textPrimary)),
                                    Text(t['priority'] ?? '', style: TextStyle(color: t['priority'] == 'Critical' ? Colors.red : CivilTheme.textSecondary)),
                                    Text(t['status'] ?? '', style: TextStyle(color: t['status'] == 'Open' ? Colors.green : CivilTheme.textSecondary)),
                                    Text(t['tenant_id']?.toString() ?? 'N/A', style: const TextStyle(color: CivilTheme.textSecondary)),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.reply, size: 16, color: CivilTheme.primary),
                                          tooltip: 'Reply / Resolve',
                                          onPressed: () {
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Replying to: ${t['subject']}')));
                                          }
                                        ),
                                      ],
                                    ),
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
