import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_provider.dart';
import '../../core/providers/dashboard_provider.dart';
import 'package:intl/intl.dart';

class DashboardMobileView extends ConsumerStatefulWidget {
  final VoidCallback onOpenDrawer;
  const DashboardMobileView({super.key, required this.onOpenDrawer});

  @override
  ConsumerState<DashboardMobileView> createState() => _DashboardMobileViewState();
}

class _DashboardMobileViewState extends ConsumerState<DashboardMobileView> {
  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final userName = auth.currentUser?['name'] ?? 'Acme';
    final initial = userName.isNotEmpty ? userName[0].toUpperCase() : 'A';
    
    // Formatting today's date
    final today = DateFormat('dd MMM yyyy').format(DateTime.now());

    final dashboardState = ref.watch(dashboardProvider);
    final stats = dashboardState.stats ?? {};

    return Scaffold(
      backgroundColor: const Color(0xFF0F111A), // Deep dark background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: widget.onOpenDrawer,
        ),
        title: Row(
          children: const [
            Text('Civil', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text('OS', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 20, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none, color: Colors.white),
                onPressed: () {},
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: const Text('3', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16.0, left: 8.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFF3B82F6),
                  child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white54, size: 16),
              ],
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting
            Text('Good Evening, $userName 👋', style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("Here's what's happening at your sites today.", style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 14)),
            const SizedBox(height: 24),

            // Today's Summary
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161B26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E2535)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.calendar_today, color: Color(0xFF8B9CB6), size: 14),
                          SizedBox(width: 6),
                          Text("Today's Summary", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                      Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Color(0xFF8B9CB6), size: 14),
                          const SizedBox(width: 6),
                          Text(today, style: const TextStyle(color: Color(0xFF8B9CB6), fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSummaryItem(Icons.folder_copy, const Color(0xFF3B82F6), '${stats['active_projects'] ?? 0}', 'Active Projects'),
                      _buildDivider(),
                      _buildSummaryItem(Icons.currency_rupee, const Color(0xFF10B981), '₹ ${( (stats['total_contract_value'] ?? 0) / 100000).toStringAsFixed(1)}L', 'Project Value'),
                      _buildDivider(),
                      _buildSummaryItem(Icons.trending_up, const Color(0xFFA855F7), '₹ ${( (stats['cost_incurred'] ?? 0) / 100000).toStringAsFixed(1)}L', 'Cost Incurred'),
                      _buildDivider(),
                      _buildSummaryItem(Icons.trending_up, const Color(0xFFF59E0B), '₹ ${( ((stats['total_contract_value'] ?? 0) - (stats['cost_incurred'] ?? 0)) / 100000).toStringAsFixed(1)}L', 'Net Profit'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // My Active Project
            _buildSectionHeader('My Active Project', 'View All'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF161B26),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E2535)),
              ),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey.shade800,
                          // Replace with NetworkImage if available
                          child: const Icon(Icons.location_city, color: Colors.white54, size: 40),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Metro Line Extension', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(4)),
                                  child: const Text('On Track', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: const [
                                Icon(Icons.location_on_outlined, color: Color(0xFF8B9CB6), size: 14),
                                SizedBox(width: 4),
                                Text('Sector 62, Noida', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 12)),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: const [
                                Text('Progress', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 10)),
                                Text('Due Date', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 10)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Text('40%', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 14, fontWeight: FontWeight.bold)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: const LinearProgressIndicator(value: 0.4, backgroundColor: Color(0xFF1E2535), valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)), minHeight: 6),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Row(
                                  children: const [
                                    Icon(Icons.calendar_today, color: Color(0xFF8B9CB6), size: 12),
                                    SizedBox(width: 4),
                                    Text('30 Aug 2024', style: TextStyle(color: Colors.white, fontSize: 12)),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.more_horiz, color: Color(0xFF8B9CB6)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0xFF1E2535)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildProjectStat('Tender Value', '₹ 4.20 Cr', Colors.white),
                      _buildProjectStat('Cost Incurred', '₹ 2.10 Cr', Colors.white),
                      _buildProjectStat('Net Profit', '₹ 2.10 Cr', const Color(0xFF10B981)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Manpower', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 10)),
                          SizedBox(height: 4),
                          Text('0 / 3', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // What Needs Your Attention
            _buildSectionHeader('What Needs Your Attention', 'View All'),
            const SizedBox(height: 12),
            _buildAlertCard(Icons.warning_amber_rounded, const Color(0xFFEF4444), '2 Slabs delayed', 'Oakwood Tower, Bridge Renovation'),
            const SizedBox(height: 8),
            _buildAlertCard(Icons.inventory_2_outlined, const Color(0xFFF59E0B), 'Cement stock low', 'Only 48 bags left at Parkside Tower'),
            const SizedBox(height: 8),
            _buildAlertCard(Icons.construction, const Color(0xFFF59E0B), '3 Equipment maintenance due', 'JCB 3DX, Mixer, Vibrator'),
            const SizedBox(height: 24),

            // Quick Actions
            const Text('Quick Actions', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickAction(Icons.note_alt_outlined, const Color(0xFF3B82F6), 'Site Diary'),
                  _buildQuickAction(Icons.architecture, const Color(0xFF10B981), 'Daily Progress'),
                  _buildQuickAction(Icons.camera_alt_outlined, const Color(0xFFA855F7), 'Add Photo'),
                  _buildQuickAction(Icons.inventory_outlined, const Color(0xFFF59E0B), 'Material In'),
                  _buildQuickAction(Icons.local_shipping_outlined, const Color(0xFF06B6D4), 'Work Order'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent Site Activity
            _buildSectionHeader('Recent Site Activity', 'View All'),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.fire_truck, color: Color(0xFF3B82F6), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text('Concrete poured at Oakwood Tower', style: TextStyle(color: Colors.white, fontSize: 14)),
                      SizedBox(height: 4),
                      Text('2nd Floor Slab', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 12)),
                    ],
                  ),
                ),
                const Text('10:30 AM', style: TextStyle(color: Color(0xFF8B9CB6), fontSize: 12)),
              ],
            ),
            const SizedBox(height: 80), // Padding for bottom nav bar
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, Color iconColor, String value, String label) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 16),
        ),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Color(0xFF8B9CB6), fontSize: 10), textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 40, color: const Color(0xFF1E2535));
  }

  Widget _buildSectionHeader(String title, String action) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
        Text(action, style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildProjectStat(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF8B9CB6), fontSize: 10)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: valueColor, fontSize: 14, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildAlertCard(IconData icon, Color color, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(color: Color(0xFF8B9CB6), fontSize: 11)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFF8B9CB6), size: 16),
        ],
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, Color color, String label) {
    return Container(
      width: 72,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF161B26),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF1E2535)),
            ),
            child: Center(
              child: Icon(icon, color: color, size: 28),
            ),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Color(0xFF8B9CB6), fontSize: 10), textAlign: TextAlign.center, maxLines: 2),
        ],
      ),
    );
  }
}
