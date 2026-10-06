import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/machinery_provider.dart';
import '../../core/theme.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/skeleton_loader.dart';

class MachineryScreen extends ConsumerStatefulWidget {
  const MachineryScreen({super.key});

  @override
  ConsumerState<MachineryScreen> createState() => _MachineryScreenState();
}

class _MachineryScreenState extends ConsumerState<MachineryScreen> {
  final _searchController = TextEditingController();
  String _filterCategory = 'All';
  String _filterStatus = 'All';
  bool _showFilters = false;

  static const _categories = ['All', 'Excavator', 'Crane', 'Mixer', 'Bulldozer', 'Loader', 'Dump Truck'];
  static const _statuses = ['All', 'Active', 'Under Maintenance', 'Idle'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(machineryProvider.notifier).fetchMachinery();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    ref.read(machineryProvider.notifier).fetchMachinery(
      category: _filterCategory,
      status: _filterStatus,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mac = ref.watch(machineryProvider);
    final machineryList = mac.machinery;

    final List<dynamic> displayMachinery = machineryList;

    return Scaffold(
      backgroundColor: CivilTheme.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;
          return Stack(
            children: [
              // Mock background image effect (gradient for now)
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
                  constraints: BoxConstraints(maxWidth: isMobile ? 600 : 1200),
                  child: Column(
                    children: [
                      SafeArea(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color:
                                            CivilTheme.surface.withValues(alpha: 0.5),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: GestureDetector(
                                      onTap: () {
                                        Scaffold.of(context).openDrawer();
                                      },
                                      child: const Icon(Icons.menu,
                                          color: CivilTheme.textSecondary,
                                          size: 20),
                                    ),
                                  ),
                                  const Spacer(),
                                  const Text('Fleet Machinery',
                                      style: TextStyle(
                                          color: CivilTheme.textPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  const CircleAvatar(
                                      radius: 14,
                                      backgroundImage: NetworkImage(
                                          'https://ui-avatars.com/api/?name=User+11')),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color:
                                            CivilTheme.surface.withValues(alpha: 0.5),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: const Icon(Icons.notifications_none,
                                        color: CivilTheme.textSecondary,
                                        size: 20),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 48,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16),
                                      decoration: BoxDecoration(
                                        color:
                                            CivilTheme.surface.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: CivilTheme.border),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.search,
                                              color: CivilTheme.textSecondary,
                                              size: 20),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: TextField(
                                              controller: _searchController,
                                              style: const TextStyle(
                                                  color: CivilTheme.textPrimary,
                                                  fontSize: 14),
                                              decoration: const InputDecoration(
                                                hintText:
                                                    'Search fleet, status, ID...',
                                                hintStyle: TextStyle(
                                                    color: CivilTheme
                                                        .textSecondary),
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
                                    height: 48,
                                    width: 48,
                                    decoration: BoxDecoration(
                                        color:
                                            CivilTheme.surface.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: CivilTheme.border)),
                                    child: GestureDetector(
                                        onTap: () => setState(() => _showFilters = !_showFilters),
                                        child: Icon(Icons.filter_list,
                                            color: _showFilters ? CivilTheme.primary : CivilTheme.textSecondary),),
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    height: 48,
                                    width: 48,
                                    decoration: BoxDecoration(
                                        color:
                                            CivilTheme.surface.withValues(alpha: 0.6),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                            color: CivilTheme.border)),
                                    child: const Icon(Icons.grid_view,
                                        color: CivilTheme.textSecondary),
                                  ),
                                ],
                              ),
                              if (_showFilters) ...[
                                const SizedBox(height: 12),
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      ..._categories.map((c) => Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: FilterChip(
                                          label: Text(c, style: const TextStyle(fontSize: 12, color: Colors.white)),
                                          selected: _filterCategory == c,
                                          onSelected: (_) {
                                            setState(() => _filterCategory = c);
                                            _applyFilters();
                                          },
                                          selectedColor: CivilTheme.primary,
                                          backgroundColor: CivilTheme.surface.withValues(alpha: 0.4),
                                          checkmarkColor: Colors.white,
                                          side: BorderSide.none,
                                        ),
                                      )),
                                      const SizedBox(width: 8),
                                      ..._statuses.map((s) => Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: FilterChip(
                                          label: Text(s, style: const TextStyle(fontSize: 12, color: Colors.white)),
                                          selected: _filterStatus == s,
                                          onSelected: (_) {
                                            setState(() => _filterStatus = s);
                                            _applyFilters();
                                          },
                                          selectedColor: CivilTheme.secondary,
                                          backgroundColor: CivilTheme.surface.withValues(alpha: 0.4),
                                          checkmarkColor: Colors.white,
                                          side: BorderSide.none,
                                        ),
                                      )),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: mac.isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(20),
                                child: SkeletonList(count: 3, itemHeight: 150),
                              )
                            : displayMachinery.isEmpty
                                ? const EmptyStateView(
                                    icon: Icons.precision_manufacturing,
                                    title: 'No Machinery',
                                    description: 'No machinery found in the fleet.',
                                  )
                                : isMobile
                                    ? ListView.separated(
                                        padding: const EdgeInsets.all(20),
                                        itemCount: displayMachinery.length,
                                        separatorBuilder: (context, index) =>
                                            const SizedBox(height: 20),
                                        itemBuilder: (context, index) =>
                                            _buildMachineryCard(displayMachinery[index],
                                                showChart: index == 0),
                                      )
                                    : GridView.builder(
                                        padding: const EdgeInsets.all(20),
                                        gridDelegate:
                                            const SliverGridDelegateWithMaxCrossAxisExtent(
                                          maxCrossAxisExtent: 450,
                                          mainAxisSpacing: 20,
                                          crossAxisSpacing: 20,
                                          childAspectRatio: 1.3,
                                        ),
                                        itemCount: displayMachinery.length,
                                        itemBuilder: (context, index) =>
                                            _buildMachineryCard(displayMachinery[index],
                                                showChart: index == 0),
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

  Widget _buildMachineryCard(Map<String, dynamic> mac,
      {bool showChart = false}) {
    final status = mac['status']?.toString().toUpperCase() ?? 'ACTIVE';
    final isActive = status == 'ACTIVE';
    final glowColor = isActive ? Colors.greenAccent : Colors.amber;

    return Container(
      decoration: BoxDecoration(
        color: CivilTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: glowColor.withValues(alpha: 0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: glowColor.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 5)
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  color: CivilTheme.background,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: CivilTheme.border),
                ),
                child: Icon(_iconForMachinery(mac),
                    color: Colors.amber, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${mac['name']} | ${mac['model_number']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: CivilTheme.textPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text('ID: ${mac['id'] ?? 'Unknown'}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: CivilTheme.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive
                      ? glowColor.withValues(alpha: 0.1)
                      : Colors.transparent,
                  border: Border.all(color: glowColor),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                      color: glowColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (showChart) ...[
            const SizedBox(height: 20),
            SizedBox(
              height: 40,
              child: Stack(
                children: [
                  LineChart(
                    LineChartData(
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: 10,
                      lineBarsData: [
                        LineChartBarData(
                          spots: const [
                            FlSpot(0, 3),
                            FlSpot(1, 4),
                            FlSpot(2, 3),
                            FlSpot(3, 7),
                            FlSpot(4, 4),
                            FlSpot(5, 8),
                            FlSpot(6, 5),
                          ],
                          isCurved: true,
                          color: Colors.greenAccent,
                          barWidth: 2,
                          isStrokeCapRound: true,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Colors.greenAccent.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        Text('Usage',
                            style: TextStyle(
                                color: CivilTheme.textSecondary, fontSize: 10)),
                        Text('48hr',
                            style: TextStyle(
                                color: CivilTheme.textPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ],
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildDataCol('Hours:', '${mac['total_hours_run'] ?? 0} hr'),
              _buildDataCol('Rate:', '₹${mac['hourly_rate'] ?? 0}/hr'),
              _buildDataCol('Location:', mac['location']?.toString() ?? 'Site'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      color: isActive ? Colors.green : Colors.grey,
                      shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                      color: isActive ? Colors.grey : Colors.amber,
                      shape: BoxShape.circle)),
              const SizedBox(width: 4),
              Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                      color: Colors.grey, shape: BoxShape.circle)),
              const Spacer(),
              _buildActionButton('Details'),
              const SizedBox(width: 8),
              _buildActionButton('Maintain'),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconForMachinery(Map<String, dynamic> mac) {
    final name = (mac['name'] ?? '').toString().toLowerCase();
    final cat = (mac['category'] ?? '').toString().toLowerCase();
    if (name.contains('excavator') || cat.contains('excavator')) return Icons.construction;
    if (name.contains('crane') || cat.contains('crane')) return Icons.precision_manufacturing;
    if (name.contains('mixer') || cat.contains('mixer')) return Icons.recycling;
    if (name.contains('truck') || name.contains('dump') || cat.contains('truck')) return Icons.local_shipping;
    if (name.contains('loader') || cat.contains('loader')) return Icons.agriculture;
    if (name.contains('generator') || cat.contains('generator')) return Icons.electrical_services;
    if (name.contains('drill') || cat.contains('drill')) return Icons.handyman;
    if (name.contains('welder') || cat.contains('welder')) return Icons.bolt;
    if (name.contains('compactor') || name.contains('roller') || cat.contains('compactor')) return Icons.science;
    return Icons.precision_manufacturing;
  }

  Widget _buildDataCol(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(color: CivilTheme.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                color: CivilTheme.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildActionButton(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CivilTheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CivilTheme.border),
      ),
      child: Text(label,
          style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 12)),
    );
  }
}
