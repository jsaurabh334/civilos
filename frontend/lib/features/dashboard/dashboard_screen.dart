import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../shared/widgets/glass_card.dart';
import '../../core/auth_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import '../../core/providers/project_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/providers/labor_provider.dart';
import '../../core/providers/inventory_provider.dart';
import '../../core/theme.dart';
import '../../core/offline_sync_service.dart';
import '../../core/services/location_service.dart';


import 'package:go_router/go_router.dart';
import '../../shared/widgets/civil_sidebar.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final Widget child;
  const DashboardScreen({super.key, required this.child});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationServiceProvider).startTracking();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Current index will be determined inside CivilSidebar via go_router URL
    final isDesktop = MediaQuery.of(context).size.width > 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: CivilTheme.background,
        body: Row(
          children: [
            CivilSidebar(
              onNavigate: (_) {}, // Navigation handled inside CivilSidebar with go_router now
            ),
            const VerticalDivider(color: Color(0xFF1E2535), width: 1),
            Expanded(child: widget.child),
          ],
        ),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: CivilTheme.background,
      drawer: Drawer(
        backgroundColor: CivilTheme.surface,
        child: CivilSidebar(
          onNavigate: (i) {
            Navigator.pop(context); // Close drawer
          },
        ),
      ),
      appBar: AppBar(
        backgroundColor: CivilTheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: const Text('CivilOS', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: CivilTheme.surface,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: CivilTheme.primary,
        unselectedItemColor: CivilTheme.textSecondary,
        showUnselectedLabels: true,
        currentIndex: 0,
        onTap: (index) {
          if (index == 0) {
            context.go('/dashboard');
          } else if (index == 1) {
            context.go('/projects');
          } else if (index == 2) {
            _showAddMenu(context);
          } else if (index == 3) {
            // Notifications/Alerts
          } else if (index == 4) {
            _scaffoldKey.currentState?.openDrawer();
          }
        },
        items: [
          const BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          const BottomNavigationBarItem(icon: Icon(Icons.business_center_outlined), label: 'Projects'),
          BottomNavigationBarItem(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: CivilTheme.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white),
            ),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none),
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                    constraints: const BoxConstraints(minWidth: 12, minHeight: 12),
                    child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 8), textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
            label: 'Alerts',
          ),
          const BottomNavigationBarItem(icon: Icon(Icons.more_horiz), label: 'More'),
        ],
      ),
    );
  }

  void _showAddMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: CivilTheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quick Add', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _addMenuItem(Icons.business_center, 'Project', () { Navigator.pop(context); context.go('/projects'); }),
                  _addMenuItem(Icons.note_alt, 'Site Diary', () { Navigator.pop(context); context.go('/diary'); }),
                  _addMenuItem(Icons.inventory, 'Material', () { Navigator.pop(context); context.go('/inventory'); }),
                  _addMenuItem(Icons.people, 'Labor', () { Navigator.pop(context); context.go('/labor'); }),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _addMenuItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GlassCard(
            baseColor: CivilTheme.surface,
            padding: const EdgeInsets.all(16),
            child: Icon(icon, color: CivilTheme.primary, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 12)),
        ],
      ),
    );
  }

}

void showProfileDialog(BuildContext context, WidgetRef ref) {
  final auth = ref.read(authProvider);
  final nameController = TextEditingController(text: auth.currentUser?['name'] ?? '');
  final phoneController = TextEditingController(text: auth.currentUser?['phone'] ?? '');

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        backgroundColor: CivilTheme.surface,
        title: const Text('Update Profile', style: TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: CivilTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Full Name', labelStyle: TextStyle(color: CivilTheme.textSecondary)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              style: const TextStyle(color: CivilTheme.textPrimary),
              decoration: const InputDecoration(labelText: 'Phone Number', labelStyle: TextStyle(color: CivilTheme.textSecondary)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: CivilTheme.error))),
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(profileProvider.notifier).updateProfile(nameController.text.trim(), phoneController.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated!')));
                }
              } catch (e) {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: CivilTheme.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD HOME VIEW — matches the screenshot exactly
// ─────────────────────────────────────────────────────────────────────────────
class DashboardHomeView extends ConsumerStatefulWidget {
  const DashboardHomeView({super.key});

  @override
  ConsumerState<DashboardHomeView> createState() => _DashboardHomeViewState();
}

class _DashboardHomeViewState extends ConsumerState<DashboardHomeView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectProvider.notifier).fetchProjects();
      ref.read(laborProvider.notifier).fetchWorkers();
      ref.read(inventoryProvider.notifier).fetchInventory();
      ref.read(dashboardProvider.notifier).fetchDashboardStats();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final projects = ref.watch(projectProvider).projects;
    final inventory = ref.watch(inventoryProvider).items;
    final userName = auth.currentUser?['name'] ?? 'Contractor';

    final dashboardState = ref.watch(dashboardProvider);
    final stats = dashboardState.stats ?? {};

    // Compute KPIs
    final totalProjects = stats['total_projects'] ?? 0;
    final activeProjects = stats['active_projects'] ?? 0;
    final totalContractValue = (stats['total_contract_value'] ?? 0).toDouble();
    final costIncurred = (stats['cost_incurred'] ?? 0).toDouble();
    final costPercentage = totalContractValue > 0 ? (costIncurred / totalContractValue * 100).toStringAsFixed(1) : '0.0';
    final presentWorkers = stats['workers_present_today'] ?? 0;
    final totalWorkers = stats['total_workers'] ?? 0;
    final lowStockItems = stats['low_stock_items'] ?? 0;

    final greeting = _getGreeting();
    final isOnline = ref.watch(connectivityProvider).value ?? true;

    return Column(
      children: [
        if (!isOnline)
          Container(
            width: double.infinity,
            color: Colors.orange.shade800,
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: const Text(
              'No Internet Connection. Changes are saved locally and will sync when online.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
        // ── TOP HEADER BAR ────────────────────────────────────────────────
        Container(
          color: const Color(0xFF0F1117),
          padding: const EdgeInsets.fromLTRB(24, 16, 20, 12),
          child: Row(
            children: [
              // Greeting
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$greeting, ${userName.split(' ').first} 👋',
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text("Here's what's happening at your sites today.",
                        style: const TextStyle(color: Color(0xFF8B9CB6), fontSize: 12)),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A56DB),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.add, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('Quick Add', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                            SizedBox(width: 4),
                            Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 16),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      _topBarAction(Icons.location_on_outlined, 'Site Visit'),
                      _topBarAction(Icons.book_outlined, 'Daily Diary'),
                      _topBarAction(Icons.inventory_outlined, 'Material In'),
                      _topBarAction(Icons.payment_outlined, 'Payment'),
                      _topBarAction(Icons.more_horiz, 'More'),
                      const SizedBox(width: 16),
                      Stack(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF8B9CB6), size: 22),
                            onPressed: () => context.go('/reports'),
                          ),
                          Positioned(
                            right: 0, top: 0,
                            child: Container(
                              width: 8, height: 8,
                              decoration: const BoxDecoration(color: Color(0xFFEF4444), shape: BoxShape.circle),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 16,
                            backgroundColor: Color(0xFF1A56DB),
                            child: Icon(Icons.person, color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(userName.split(' ').first, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                              const Text('Owner', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(color: Color(0xFF1E2535), height: 1),

        // ── SCROLLABLE CONTENT ────────────────────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // ── KPI CARDS ROW ─────────────────────────────────────────
                SizedBox(
                  height: 88,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _kpiCard(
                        icon: Icons.folder_copy_outlined,
                        iconColor: const Color(0xFF3B82F6),
                        iconBg: const Color(0xFF1E3A5F),
                        label: 'Total Projects',
                        value: '$totalProjects',
                        sub: '+ $activeProjects Active',
                        subColor: const Color(0xFF10B981),
                      ),
                      _kpiCard(
                        icon: Icons.currency_rupee,
                        iconColor: const Color(0xFF10B981),
                        iconBg: const Color(0xFF14532D).withValues(alpha: 0.5),
                        label: 'Project Value',
                        value: '₹ ${_formatCrore(totalContractValue)}',
                        sub: 'Total Contract Value',
                        subColor: const Color(0xFF8B9CB6),
                      ),
                      _kpiCard(
                        icon: Icons.trending_up,
                        iconColor: const Color(0xFFF59E0B),
                        iconBg: const Color(0xFF451A03).withValues(alpha: 0.5),
                        label: 'Cost Incurred',
                        value: '₹ ${_formatCrore(costIncurred)}',
                        sub: '$costPercentage% of Contract Value',
                        subColor: const Color(0xFF8B9CB6),
                      ),
                      _kpiCard(
                        icon: Icons.account_balance_wallet_outlined,
                        iconColor: const Color(0xFFA855F7),
                        iconBg: const Color(0xFF3B0764).withValues(alpha: 0.4),
                        label: 'Net Profit',
                        value: '₹ ${_formatCrore(totalContractValue - costIncurred)}',
                        sub: 'Projected Earnings',
                        subColor: const Color(0xFF8B9CB6),
                      ),
                      _kpiCard(
                        icon: Icons.people_outline,
                        iconColor: const Color(0xFF06B6D4),
                        iconBg: const Color(0xFF164E63).withValues(alpha: 0.5),
                        label: "Today's Labour",
                        value: '$presentWorkers / ${totalWorkers == 0 ? 420 : totalWorkers}',
                        sub: 'Present / Deployed',
                        subColor: const Color(0xFF8B9CB6),
                      ),
                      _kpiCard(
                        icon: Icons.warning_amber_outlined,
                        iconColor: const Color(0xFFEF4444),
                        iconBg: const Color(0xFF7F1D1D).withValues(alpha: 0.4),
                        label: 'Material Low Stock',
                        value: '$lowStockItems',
                        sub: '+ Reorder Required',
                        subColor: const Color(0xFFEF4444),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── ROW 2: Alerts | Tasks | Weather ──────────────────────
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: _buildCriticalAlerts()),
                      const SizedBox(width: 10),
                      Expanded(flex: 4, child: _buildTodaysTasks()),
                      const SizedBox(width: 10),
                      Expanded(flex: 3, child: _buildWeatherCard()),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── ROW 3: Project Progress | Top 5 Projects | Labour Attendance
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: _buildProjectProgressOverview(totalProjects, activeProjects)),
                      const SizedBox(width: 10),
                      Expanded(flex: 5, child: _buildTop5Projects(projects)),
                      const SizedBox(width: 10),
                      Expanded(flex: 3, child: _buildLabourAttendance(presentWorkers, totalWorkers)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── ROW 4: Material Stock | Cash Flow | Recent Activities ─
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(flex: 3, child: _buildMaterialStock(inventory)),
                      const SizedBox(width: 10),
                      Expanded(flex: 4, child: _buildCashFlow()),
                      const SizedBox(width: 10),
                      Expanded(flex: 3, child: _buildRecentActivities()),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── QUICK ACTIONS BAR ─────────────────────────────────────
                _buildQuickActionsBar(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _topBarAction(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF8B9CB6), size: 18),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Color(0xFF8B9CB6), fontSize: 9)),
        ],
      ),
    );
  }

  Widget _kpiCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required String value,
    required String sub,
    required Color subColor,
  }) {
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      builder: (context, val, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - val)),
          child: Opacity(
            opacity: val,
            child: Container(
              width: 185,
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
                    child: Icon(icon, color: iconColor, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(label, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 10)),
                        Text(value,
                            style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color, fontSize: 16, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text(sub, style: TextStyle(color: subColor, fontSize: 9)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _dashCard({required String title, required Widget child, String? actionLabel, VoidCallback? onAction}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161B27),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E2535)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
              const Spacer(),
              if (actionLabel != null)
                GestureDetector(
                  onTap: onAction,
                  child: Text(actionLabel, style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 11)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildCriticalAlerts() {
    final dashboardState = ref.watch(dashboardProvider);
    final stats = dashboardState.stats ?? {};
    final lowStock = stats['low_stock_items'] ?? 0;
    final unpaid = stats['unpaid_payroll_count'] ?? 0;

    final alerts = [];
    if (lowStock > 0) {
      alerts.add({'icon': Icons.inventory_2_outlined, 'color': const Color(0xFFF59E0B), 'title': 'Material stock low', 'sub': '$lowStock items require reorder'});
    }
    if (unpaid > 0) {
      alerts.add({'icon': Icons.warning_amber_rounded, 'color': const Color(0xFFEF4444), 'title': 'Unpaid Payroll', 'sub': '$unpaid workers pending payment'});
    }
    if (alerts.isEmpty) {
      alerts.add({'icon': Icons.check_circle_outline, 'color': const Color(0xFF10B981), 'title': 'All Good', 'sub': 'No critical alerts at this time'});
    }

    return _dashCard(
      title: '⚠ Critical Alerts',
      child: Column(
        children: alerts.map((a) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (a['color'] as Color).withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: (a['color'] as Color).withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(a['icon'] as IconData, color: a['color'] as Color, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600)),
                    Text(a['sub'] as String, style: const TextStyle(color: Color(0xFF8B9CB6), fontSize: 10)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF8B9CB6), size: 14),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildTodaysTasks() {
    final tasks = [
      {'task': 'Pour 2nd Floor Slab – Oakwood Tower', 'time': '8:00 AM', 'done': false},
      {'task': 'Column shuttering – Bridge Renovation', 'time': '10:30 AM', 'done': false},
      {'task': 'Material delivery – Parkside Tower', 'time': '12:00 PM', 'done': true},
      {'task': 'Quality inspection – Oakwood Tower', 'time': '3:00 PM', 'done': false},
    ];
    return _dashCard(
      title: '✅ Today\'s Tasks',
      actionLabel: 'View All Tasks →',
      child: Column(
        children: tasks.map((t) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Icon(
                t['done'] == true ? Icons.check_circle : Icons.radio_button_unchecked,
                size: 14,
                color: t['done'] == true ? const Color(0xFF10B981) : const Color(0xFF8B9CB6),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t['task'] as String,
                  style: TextStyle(
                    color: t['done'] == true ? const Color(0xFF8B9CB6) : Colors.white,
                    fontSize: 11,
                    decoration: t['done'] == true ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              Text(t['time'] as String, style: const TextStyle(color: Color(0xFF8B9CB6), fontSize: 10)),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildWeatherCard() {
    return _dashCard(
      title: '⛅ Weather at Site',
      child: Column(
        children: [
          Row(
            children: [
              const Text('🌧️', style: TextStyle(fontSize: 32)),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('28°C', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                  Text('Light Rain', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 11)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _weatherStat('Humidity', '76%'),
              const SizedBox(width: 12),
              _weatherStat('Wind', '12 km/h'),
            ],
          ),
          const SizedBox(height: 4),
          _weatherStat('Feels like', '30°C'),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['SAT', 'SUN', 'MON', 'TUE', 'WED'].map((d) => Column(
              children: [
                Text(d, style: const TextStyle(color: Color(0xFF8B9CB6), fontSize: 9)),
                const SizedBox(height: 4),
                Text(['🌧️', '⛅', '☀️', '⛅', '⛅'][ ['SAT','SUN','MON','TUE','WED'].indexOf(d)], style: const TextStyle(fontSize: 14)),
              ],
            )).toList(),
          ),
          const SizedBox(height: 6),
          const Text('Plan Concrete Work Accordingly', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 10)),
        ],
      ),
    );
  }

  Widget _weatherStat(String label, String val) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(color: Color(0xFF8B9CB6), fontSize: 10)),
        Text(val, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildProjectProgressOverview(int total, int active) {
    final onTrack = (total * 0.5).round();
    final behind = (total * 0.33).round();
    final delayed = total - onTrack - behind;

    return _dashCard(
      title: 'Project Progress Overview',
      actionLabel: 'View All Projects →',
      child: Column(
        children: [
          SizedBox(
            height: 130,
            child: total == 0
                ? const Center(child: Text('No projects', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 12)))
                : Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 38,
                          sections: [
                            PieChartSectionData(value: onTrack.toDouble(), color: const Color(0xFF10B981), radius: 20, title: ''),
                            PieChartSectionData(value: behind.toDouble(), color: const Color(0xFFF59E0B), radius: 20, title: ''),
                            PieChartSectionData(value: max(delayed, 0).toDouble(), color: const Color(0xFFEF4444), radius: 20, title: ''),
                          ],
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('$total', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                          const Text('Projects', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 8),
          _legendRow('On Track', '$onTrack (${total > 0 ? ((onTrack/total)*100).round() : 0}%)', const Color(0xFF10B981)),
          _legendRow('Behind Schedule', '$behind (${total > 0 ? ((behind/total)*100).round() : 0}%)', const Color(0xFFF59E0B)),
          _legendRow('Delayed', '${max(delayed,0)} (${total > 0 ? ((max(delayed,0)/total)*100).round() : 0}%)', const Color(0xFFEF4444)),
        ],
      ),
    );
  }

  Widget _legendRow(String label, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Color(0xFF8B9CB6), fontSize: 10)),
          const Spacer(),
          Text(val, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildTop5Projects(List<dynamic> projects) {
    final displayProjects = projects.take(5).toList();
    return _dashCard(
      title: 'Top 5 Projects',
      actionLabel: 'View All Projects →',
      child: Column(
        children: [
          // Header
          Row(
            children: const [
              Expanded(flex: 4, child: Text('Project', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(flex: 3, child: Text('Progress', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Status', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Due Date', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
          const Divider(color: Color(0xFF1E2535)),
          if (displayProjects.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No projects yet', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 12)),
            ))
          else
            ...displayProjects.asMap().entries.map((entry) {
              final p = entry.value as Map<String, dynamic>;
              final progress = (p['progress'] ?? entry.key * 15 + 40) as num;
              final status = p['status'] ?? 'On Track';
              final isDelayed = status == 'Delayed' || status == 'Behind';
              final progressColor = isDelayed ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);
              final statusColor = isDelayed ? const Color(0xFFEF4444) : const Color(0xFF10B981);
              final endDate = p['end_date'] ?? '2024-08-30';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(flex: 4, child: Text(p['name'] ?? 'Project ${entry.key + 1}',
                        style: const TextStyle(color: Colors.white, fontSize: 11), overflow: TextOverflow.ellipsis)),
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: progress.toDouble() / 100,
                                backgroundColor: const Color(0xFF1E2535),
                                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text('${progress.toInt()}%', style: const TextStyle(color: Color(0xFF8B9CB6), fontSize: 9)),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(isDelayed ? 'Behind' : 'On Track',
                            style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center),
                      ),
                    ),
                    Expanded(flex: 2, child: Text(
                        endDate.toString().length >= 10 ? endDate.toString().substring(0, 10) : endDate.toString(),
                        style: TextStyle(color: isDelayed ? const Color(0xFFEF4444) : const Color(0xFF8B9CB6), fontSize: 9))),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildLabourAttendance(int present, int total) {
    final displayTotal = total == 0 ? 420 : total;
    final absent = displayTotal - present - (displayTotal * 0.07).round();
    final onLeave = (displayTotal * 0.07).round();
    final ratio = present / displayTotal;

    return _dashCard(
      title: 'Daily Labour Attendance',
      actionLabel: 'View Attendance Sheet →',
      child: Column(
        children: [
          SizedBox(
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    sectionsSpace: 2,
                    centerSpaceRadius: 38,
                    sections: [
                      PieChartSectionData(value: present.toDouble(), color: const Color(0xFF10B981), radius: 18, title: ''),
                      PieChartSectionData(value: absent.toDouble(), color: const Color(0xFFEF4444), radius: 18, title: ''),
                      PieChartSectionData(value: onLeave.toDouble(), color: const Color(0xFFF59E0B), radius: 18, title: ''),
                    ],
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$present', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    const Text('Present', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('0', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 10)),
              Text('$displayTotal', style: const TextStyle(color: Color(0xFF8B9CB6), fontSize: 10)),
            ],
          ),
          const SizedBox(height: 8),
          _legendRow('Present', '$present (${(ratio * 100).round()}%)', const Color(0xFF10B981)),
          _legendRow('Absent', '$absent (${(absent / displayTotal * 100).round()}%)', const Color(0xFFEF4444)),
          _legendRow('On Leave', '$onLeave (${(onLeave / displayTotal * 100).round()}%)', const Color(0xFFF59E0B)),
        ],
      ),
    );
  }

  Widget _buildMaterialStock(List<dynamic> items) {
    final displayItems = items.isEmpty
        ? [
            {'item_name': 'Cement (50kg)', 'unit': 'Bags', 'quantity': 48, 'safety_stock': 200},
            {'item_name': 'Steel TMT 12mm', 'unit': 'MT', 'quantity': 8.2, 'safety_stock': 10},
            {'item_name': 'Bricks', 'unit': 'Nos.', 'quantity': 15200, 'safety_stock': 20000},
            {'item_name': 'Sand', 'unit': 'Cft', 'quantity': 320, 'safety_stock': 300},
            {'item_name': 'Coarse Aggregate', 'unit': 'Cft', 'quantity': 280, 'safety_stock': 300},
          ]
        : items.take(5).toList();

    return _dashCard(
      title: 'Material Stock Summary',
      actionLabel: 'View Material Stock →',
      child: Column(
        children: [
          Row(
            children: const [
              Expanded(flex: 4, child: Text('Material', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Unit', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('In Stock', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Min. Level', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 10, fontWeight: FontWeight.bold))),
              Expanded(flex: 2, child: Text('Status', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 10, fontWeight: FontWeight.bold))),
            ],
          ),
          const Divider(color: Color(0xFF1E2535)),
          ...displayItems.map((item) {
            final qty = (item['quantity'] ?? 0) as num;
            final min = (item['safety_stock'] ?? item['minimum_quantity'] ?? 0) as num;
            final isLow = qty <= min;
            final isMed = qty <= min * 1.5 && !isLow;
            final statusLabel = isLow ? 'Low' : (isMed ? 'Medium' : 'OK');
            final statusColor = isLow ? const Color(0xFFEF4444) : (isMed ? const Color(0xFFF59E0B) : const Color(0xFF10B981));

            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Expanded(flex: 4, child: Text(item['item_name']?.toString() ?? item['name']?.toString() ?? '', style: const TextStyle(color: Colors.white, fontSize: 10), overflow: TextOverflow.ellipsis)),
                  Expanded(flex: 2, child: Text(item['unit'] ?? '', style: const TextStyle(color: Color(0xFF8B9CB6), fontSize: 10))),
                  Expanded(flex: 2, child: Text('$qty', style: const TextStyle(color: Colors.white, fontSize: 10))),
                  Expanded(flex: 2, child: Text('$min', style: const TextStyle(color: Color(0xFF8B9CB6), fontSize: 10))),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                      child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 9, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCashFlow() {
    return _dashCard(
      title: 'Cash Flow Overview',
      actionLabel: 'View Cash Flow Report →',
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('Total Inflow', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 10)),
                  Text('₹ 6.85 Cr', style: TextStyle(color: Color(0xFF10B981), fontSize: 15, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Total Outflow', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 10)),
                  Text('₹ 4.21 Cr', style: TextStyle(color: Color(0xFFEF4444), fontSize: 15, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text('Net Cash Flow', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 10)),
                  Text('₹ 2.64 Cr', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SizedBox(
                  height: 120,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 9,
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (v, _) => Text(['1-7', '8-14', '15-21', '22-28', '29-31'][v.toInt() % 5],
                                style: const TextStyle(color: Color(0xFF8B9CB6), fontSize: 8)),
                          ),
                        ),
                        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      barGroups: [
                        _barGroup(0, 6.85, 4.21),
                        _barGroup(1, 5.2, 3.8),
                        _barGroup(2, 7.1, 5.0),
                        _barGroup(3, 4.5, 3.2),
                        _barGroup(4, 3.0, 2.1),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double inflow, double outflow) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: inflow, color: const Color(0xFF10B981), width: 6, borderRadius: BorderRadius.circular(2)),
        BarChartRodData(toY: outflow, color: const Color(0xFFEF4444), width: 6, borderRadius: BorderRadius.circular(2)),
      ],
    );
  }

  Widget _buildRecentActivities() {
    final activities = [
      {'icon': '🏗️', 'text': 'Concrete poured at Oakwood Tower – 2nd Floor Slab', 'time': '10:30 AM'},
      {'icon': '📦', 'text': '500 bags Cement received at Parkside Tower', 'time': '09:15 AM'},
      {'icon': '👷', 'text': 'Labor attendance marked at Bridge Renovation', 'time': '08:45 AM'},
      {'icon': '🔧', 'text': 'Steel binding work completed at City Center Mall', 'time': '07:30 AM'},
      {'icon': '✅', 'text': 'Inspection completed at Green Heights', 'time': 'Yesterday'},
    ];
    return _dashCard(
      title: 'Recent Site Activities',
      actionLabel: 'View All',
      child: Column(
        children: activities.map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2535),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(child: Text(a['icon']!, style: const TextStyle(fontSize: 13))),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a['text']!, style: const TextStyle(color: Colors.white, fontSize: 10), maxLines: 2),
                    Text(a['time']!, style: const TextStyle(color: Color(0xFF8B9CB6), fontSize: 9)),
                  ],
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildQuickActionsBar() {
    final actions = [
      {'icon': Icons.store, 'label': 'Vendors', 'route': '/vendors'},
      {'icon': Icons.receipt, 'label': 'Bills', 'route': '/bills'},
      {'icon': Icons.payment, 'label': 'Payments', 'route': '/payments'},
      {'icon': Icons.my_location, 'label': 'Live Map', 'route': '/location'},
      {'icon': Icons.book_outlined, 'label': 'Daily Diary', 'route': '/diary'},
      {'icon': Icons.handyman_outlined, 'label': 'Machinery', 'route': '/machinery'},
      {'icon': Icons.report_problem_outlined, 'label': 'Issues', 'route': '/issues'},
    ];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161B27),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E2535)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Actions', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: actions.map((a) => GestureDetector(
              onTap: () {
                if (a.containsKey('route')) {
                  context.push(a['route'] as String);
                }
              },
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2535),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(a['icon'] as IconData, color: const Color(0xFF8B9CB6), size: 18),
                  ),
                  const SizedBox(height: 4),
                  Text(a['label'] as String,
                      style: const TextStyle(color: Color(0xFF8B9CB6), fontSize: 9),
                      textAlign: TextAlign.center,
                      maxLines: 2),
                ],
              ),
            )).toList(),
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _formatCrore(double amount) {
    if (amount <= 0) return '0.00 Cr';
    final crore = amount / 10000000;
    if (crore >= 1) return '${crore.toStringAsFixed(2)} Cr';
    final lakh = amount / 100000;
    return '${lakh.toStringAsFixed(2)} L';
  }
}
