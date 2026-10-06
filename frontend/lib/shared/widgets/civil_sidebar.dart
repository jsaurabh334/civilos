import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_provider.dart';
import 'package:go_router/go_router.dart';

class CivilSidebar extends ConsumerWidget {
  final Function(int)? onNavigate;

  const CivilSidebar({
    super.key,
    this.onNavigate,
  });

  static const List<Map<String, dynamic>> navStructure = [
    {'path': '/', 'title': 'Dashboard', 'group': 'Dashboard', 'icon': Icons.dashboard_outlined},
    {'path': '/projects', 'title': 'Projects', 'group': 'PROJECT MANAGEMENT', 'icon': Icons.business_center_outlined},
    {'path': '/schedule', 'title': 'Schedule', 'group': 'PROJECT MANAGEMENT', 'icon': Icons.schedule_outlined},
    {'path': '/tenders', 'title': 'Tenders', 'group': 'PROJECT MANAGEMENT', 'icon': Icons.gavel_outlined},
    {'path': '/documents', 'title': 'Documents', 'group': 'PROJECT MANAGEMENT', 'icon': Icons.article_outlined},
    {'path': '/drawings', 'title': 'Drawings', 'group': 'PROJECT MANAGEMENT', 'icon': Icons.architecture},
    {'path': '/diary', 'title': 'Site Diary', 'group': 'SITE OPERATIONS', 'icon': Icons.book_outlined},
    {'path': '/labor', 'title': 'Labor & Attendance', 'group': 'SITE OPERATIONS', 'icon': Icons.people_outline},
    {'path': '/machinery', 'title': 'Equipment', 'group': 'SITE OPERATIONS', 'icon': Icons.precision_manufacturing_outlined},
    {'path': '/inspections', 'title': 'Inspections', 'group': 'SITE OPERATIONS', 'icon': Icons.checklist_outlined},
    {'path': '/checklists', 'title': 'Checklists', 'group': 'SITE OPERATIONS', 'icon': Icons.assignment_outlined},
    {'path': '/work_orders', 'title': 'Work Orders', 'group': 'SITE OPERATIONS', 'icon': Icons.construction_outlined},
    {'path': '/vehicles', 'title': 'Vehicles', 'group': 'SITE OPERATIONS', 'icon': Icons.local_shipping_outlined},
    {'path': '/inventory', 'title': 'Material Stock', 'group': 'INVENTORY', 'icon': Icons.inventory_2_outlined},
    {'path': '/purchase_orders', 'title': 'Purchase Orders', 'group': 'INVENTORY', 'icon': Icons.shopping_cart_outlined},
    {'path': '/vendors', 'title': 'Vendors', 'group': 'INVENTORY', 'icon': Icons.store_outlined},
    {'path': '/billing', 'title': 'Billing & Invoices', 'group': 'FINANCE', 'icon': Icons.receipt_long_outlined},
    {'path': '/payments', 'title': 'Payments', 'group': 'FINANCE', 'icon': Icons.payments_outlined},
    {'path': '/expenses', 'title': 'Expenses', 'group': 'FINANCE', 'icon': Icons.account_balance_wallet_outlined},
    {'path': '/reports', 'title': 'Reports', 'group': 'FINANCE', 'icon': Icons.bar_chart_outlined},
    {'path': '/notifications', 'title': 'Notifications', 'group': 'FINANCE', 'icon': Icons.notifications_outlined},
    {'path': '/chat', 'title': 'Chat', 'group': 'FINANCE', 'icon': Icons.chat_outlined},
    {'path': '/map', 'title': 'Map View', 'group': 'FINANCE', 'icon': Icons.map_outlined},
    {'path': '/settings', 'title': 'Settings', 'group': 'SETTINGS', 'icon': Icons.settings_outlined},
    {'path': '/copilot', 'title': 'AI Copilot', 'group': 'DASHBOARD', 'icon': Icons.smart_toy_outlined},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).uri.path;
    final auth = ref.watch(authProvider);
    final authMap = {
      'currentTenant': auth.currentTenant,
      'currentUser': auth.currentUser,
      'tenantName': auth.currentTenant?['name'],
    };

    final groups = <String, List<int>>{};
    for (int i = 0; i < navStructure.length; i++) {
      final group = navStructure[i]['group'] as String;
      groups.putIfAbsent(group, () => []).add(i);
    }

    return Container(
      width: 200,
      color: CivilTheme.surface,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('🏗️', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    const Text('CivilOS',
                        style: TextStyle(color: CivilTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  authMap['currentTenant']?['name'] ?? authMap['tenantName'] ?? 'Acme Constructions Pvt. Ltd.',
                  style: TextStyle(
color: CivilTheme.textSecondary, fontSize: 10),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Divider(color: CivilTheme.border, height: 1),
          const SizedBox(height: 8),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: groups.entries.map((entry) {
                final groupName = entry.key;
                final indices = entry.value;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (groupName != 'Dashboard')
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                        child: Text(
                          groupName,
                          style: TextStyle(
color: CivilTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ...indices.map((index) {
                      final item = navStructure[index];
                      final path = item['path'] as String;
                      final isSelected = currentPath == path || (path != '/' && currentPath.startsWith(path));
                      return InkWell(
                        onTap: () {
                          if (onNavigate != null) onNavigate!(index);
                          context.go(path);
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: isSelected ? CivilTheme.primary.withValues(alpha: 0.15) : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                item['icon'] as IconData,
                                size: 15,
                                color: isSelected ? CivilTheme.primary : CivilTheme.textSecondary,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  item['title'] as String,
                                  style: TextStyle(
                                    color: isSelected ? CivilTheme.primary : CivilTheme.textSecondary,
                                    fontSize: 12.5,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
color: CivilTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
          const Divider(color: Color(0xFF1E2535), height: 1),
          InkWell(
            onTap: () async {
              await ref.read(authProvider.notifier).logout();
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              child: const Row(
                children: [
                  Icon(Icons.logout, size: 15, color: Color(0xFF6B7280)),
                  SizedBox(width: 10),
                  Text('Logout', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
