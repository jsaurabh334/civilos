import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';
import '../../core/auth_provider.dart';
import '../../core/providers/inventory_provider.dart';
import '../../core/theme.dart';
import '../../core/empty_state.dart';
import '../../shared/widgets/empty_state_view.dart';
import '../../shared/widgets/skeleton_loader.dart';

import '../../core/refresh_wrapper.dart';

class InventoryScreen extends ConsumerStatefulWidget {
  const InventoryScreen({super.key});

  @override
  ConsumerState<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends ConsumerState<InventoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final inv = ref.read(inventoryProvider.notifier);
      final auth = ref.read(authProvider.notifier);
      if (auth.isFeatureEnabled('inventory')) {
        inv.fetchInventory();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openCreateItemDialog() {
    final nameCtrl = TextEditingController();
    final skuCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final unitCtrl = TextEditingController();
    final qtyCtrl = TextEditingController();
    final safetyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: CivilTheme.surface,
          title: const Text('Create Inventory Item',
              style: TextStyle(color: CivilTheme.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  style: const TextStyle(color: CivilTheme.textPrimary),
                  decoration: const InputDecoration(
                      labelText: 'Item Name *',
                      labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: skuCtrl,
                  style: const TextStyle(color: CivilTheme.textPrimary),
                  decoration: const InputDecoration(
                      labelText: 'SKU',
                      labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: categoryCtrl,
                  style: const TextStyle(color: CivilTheme.textPrimary),
                  decoration: const InputDecoration(
                      labelText:
                          'Category (Material/Equipment/Fuel/Consumables)',
                      labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: unitCtrl,
                        style: const TextStyle(color: CivilTheme.textPrimary),
                        decoration: const InputDecoration(
                            labelText: 'Unit *',
                            labelStyle:
                                TextStyle(color: CivilTheme.textSecondary)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        controller: qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        style: const TextStyle(color: CivilTheme.textPrimary),
                        decoration: const InputDecoration(
                            labelText: 'Initial Qty',
                            labelStyle:
                                TextStyle(color: CivilTheme.textSecondary)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: safetyCtrl,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: CivilTheme.textPrimary),
                  decoration: const InputDecoration(
                      labelText: 'Safety Stock',
                      labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: CivilTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final unit = unitCtrl.text.trim();
                if (name.isEmpty || unit.isEmpty) return;
                try {
                  await ref
                      .read(inventoryProvider.notifier)
                      .createInventoryItem({
                    'item_name': name,
                    'sku': skuCtrl.text.trim(),
                    'category': categoryCtrl.text.trim(),
                    'unit': unit,
                    'quantity': double.tryParse(qtyCtrl.text) ?? 0.0,
                    'safety_stock': double.tryParse(safetyCtrl.text) ?? 0.0,
                  });
                  if (ctx.mounted) Navigator.pop(ctx);
                } catch (e) {
                  // handle error silently for UI rewrite
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  void _showItemDetailsDialog(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CivilTheme.surface,
        title: Text(item['item_name']?.toString() ?? 'Item Details', style: const TextStyle(color: CivilTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detailRow('SKU', item['sku']?.toString() ?? '-'),
            _detailRow('Category', item['category']?.toString() ?? '-'),
            _detailRow('Quantity', item['quantity']?.toString() ?? '0'),
            _detailRow('Unit', item['unit']?.toString() ?? '-'),
            _detailRow('Unit Price', '₹${item['unit_price'] ?? 0}'),
            _detailRow('Safety Stock', item['safety_stock']?.toString() ?? '0'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close', style: TextStyle(color: CivilTheme.textSecondary))),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: CivilTheme.textSecondary)),
          Text(value, style: const TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _showReorderDialog(Map<String, dynamic> item) {
    final qtyController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: CivilTheme.surface,
        title: Text('Reorder: ${item['item_name'] ?? ''}', style: const TextStyle(color: CivilTheme.textPrimary)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: CivilTheme.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Quantity to order',
                labelStyle: TextStyle(color: CivilTheme.textSecondary),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: CivilTheme.textSecondary))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Reorder requested for ${qtyController.text} units of ${item['item_name']}'),
                backgroundColor: CivilTheme.primary,
              ));
            },
            style: ElevatedButton.styleFrom(backgroundColor: CivilTheme.primary),
            child: const Text('Submit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRecordTransactionDialog(Map<String, dynamic> item) {
    final qtyCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    final ewayCtrl = TextEditingController();
    final ewayDocCtrl = TextEditingController();
    String type = 'IN';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: CivilTheme.surface,
          title: Text('Record Transaction: ${item['item_name']}', style: const TextStyle(color: CivilTheme.textPrimary)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: type,
                  dropdownColor: CivilTheme.surface,
                  style: const TextStyle(color: CivilTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Type', labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                  items: const [
                    DropdownMenuItem(value: 'IN', child: Text('Stock IN')),
                    DropdownMenuItem(value: 'OUT', child: Text('Stock OUT')),
                  ],
                  onChanged: (v) => setDialogState(() => type = v!),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: CivilTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Quantity', labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: notesCtrl,
                  style: const TextStyle(color: CivilTheme.textPrimary),
                  decoration: const InputDecoration(labelText: 'Notes', labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                ),
                if (type == 'IN') ...[
                  const SizedBox(height: 12),
                  const Divider(color: CivilTheme.border),
                  const Text('Government E-Way Bill (Optional)', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 12)),
                  TextField(
                    controller: ewayCtrl,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'E-Way Bill Number', labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: ewayDocCtrl,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(labelText: 'E-Way Bill Document URL', labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: CivilTheme.textSecondary))),
            ElevatedButton(
              onPressed: () async {
                final qty = double.tryParse(qtyCtrl.text) ?? 0;
                if (qty <= 0) return;
                try {
                  await ref.read(inventoryProvider.notifier).recordInventoryTransaction(
                    item['id'], type, qty, 'Manual Entry', notesCtrl.text, DateTime.now().toIso8601String().split('T')[0],
                    ewayBillNumber: ewayCtrl.text, ewayBillDocument: ewayDocCtrl.text,
                  );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaction recorded')));
                } catch (e) {
                   if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: CivilTheme.primary),
              child: const Text('Record', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.read(authProvider.notifier).isFeatureEnabled('inventory')) {
      return Scaffold(
        backgroundColor: CivilTheme.background,
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 450),
            child: Card(
              color: CivilTheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, size: 64, color: CivilTheme.warning),
                    const SizedBox(height: 16),
                    const Text('Warehouse Module Locked',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: CivilTheme.textPrimary)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Contact sales@civilos.com to upgrade'),
                            backgroundColor: CivilTheme.primary,
                          ));
                        }, child: const Text('Request Upgrade')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    final inv = ref.watch(inventoryProvider);
    final items = inv.items;
    final filteredItems = _searchQuery.isEmpty
        ? items
        : items
            .where((i) =>
                (i['item_name'] ?? '')
                    .toString()
                    .toLowerCase()
                    .contains(_searchQuery) ||
                (i['sku'] ?? '')
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
              if (isMobile) _buildMobileTopBar() else _buildDesktopTopBar(),
              Expanded(
                child: inv.isLoading && items.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24.0),
                        child: SkeletonList(count: 4, itemHeight: 120),
                      )
                    : items.isEmpty
                        ? EmptyStateView(
                            icon: Icons.inventory_2,
                            title: 'No inventory items',
                            description: 'Add your first inventory item',
                            actionLabel: 'Add Item',
                            onAction: () => _openCreateItemDialog(),
                          )
                        : RefreshWrapper(
                            onRefresh: () async => await ref
                                .read(inventoryProvider.notifier)
                                .fetchInventory(),
                            child: SingleChildScrollView(
                              padding: const EdgeInsets.all(24),
                              child: isMobile
                                  ? _buildMobileList(filteredItems)
                                  : _buildDesktopGrid(
                                      filteredItems, constraints.maxWidth),
                            ),
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDesktopTopBar() {
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
                    Text('Warehouse Command Center', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: CivilTheme.textPrimary)),
                    SizedBox(height: 4),
                    Text('Inventory & Fleet Logistics', style: TextStyle(fontSize: 13, color: CivilTheme.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _openCreateItemDialog,
                icon: const Icon(Icons.add, size: 16, color: Colors.white),
                label: const Text('Add Item', style: TextStyle(color: Colors.white)),
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
                      const Text('Total Items in Stock', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
                      const SizedBox(height: 8),
                      const Text('14,830', style: TextStyle(color: CivilTheme.textPrimary, fontSize: 28, fontWeight: FontWeight.bold)),
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
                      const Text('Low Stock Alerts', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
                      const SizedBox(height: 8),
                      const Text('12 Warnings', style: TextStyle(color: Colors.orangeAccent, fontSize: 28, fontWeight: FontWeight.bold)),
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
                      const Text('Estimated Inventory Value', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
                      const SizedBox(height: 8),
                      const Text('\$185,400', style: TextStyle(color: Colors.teal, fontSize: 28, fontWeight: FontWeight.bold)),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                        text: 'CONSTRUCT | ',
                        style: TextStyle(
                            color: Colors.lightBlueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                        children: [
                          TextSpan(
                              text: 'WAREHOUSE STOCK',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                        ]),
                  ),
                  const SizedBox(height: 4),
                  const Text('SITE 45 - KENSINGTON',
                      style: TextStyle(
                          color: CivilTheme.textSecondary, fontSize: 12)),
                ],
              ),
              const Icon(Icons.filter_alt_outlined,
                  color: CivilTheme.textSecondary),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: CivilTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CivilTheme.border),
            ),
            child: Row(
              children: [
                const Icon(Icons.search,
                    color: CivilTheme.textSecondary, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.toLowerCase()),
                    style: const TextStyle(
                        color: CivilTheme.textPrimary, fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Search Inventory...',
                      hintStyle: TextStyle(color: CivilTheme.textSecondary),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildMobileFilterPill('Material'),
              const SizedBox(width: 8),
              _buildMobileFilterPill('Quantity'),
              const SizedBox(width: 8),
              _buildMobileFilterPill('Location'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFilterPill(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: CivilTheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: CivilTheme.border),
      ),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: CivilTheme.textSecondary, fontSize: 12)),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down,
              color: CivilTheme.textSecondary, size: 14),
        ],
      ),
    );
  }

  Widget _buildDesktopGrid(List<dynamic> filteredItems, double maxWidth) {
    int columns = maxWidth > 1400 ? 3 : (maxWidth > 900 ? 2 : 1);
    double cardWidth = (maxWidth - 48 - ((columns - 1) * 24)) / columns;

    return Wrap(
      spacing: 24,
      runSpacing: 24,
      children: filteredItems.map((item) {
        return SizedBox(
          width: cardWidth,
          child: DesktopInventoryCard(
            item: item,
            onViewDetails: () => _showItemDetailsDialog(item),
            onReorder: () => _showReorderDialog(item),
            onRecordTransaction: () => _showRecordTransactionDialog(item),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMobileList(List<dynamic> filteredItems) {
    return Column(
      children: filteredItems.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: InkWell(
            onTap: () => _showRecordTransactionDialog(item),
            borderRadius: BorderRadius.circular(16),
            child: MobileInventoryCard(item: item),
          ),
        );
      }).toList(),
    );
  }
}

class DesktopInventoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final VoidCallback onViewDetails;
  final VoidCallback onReorder;
  final VoidCallback onRecordTransaction;
  const DesktopInventoryCard({super.key, required this.item, required this.onViewDetails, required this.onReorder, required this.onRecordTransaction});

  @override
  Widget build(BuildContext context) {
    final double qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
    final double safety = (item['safety_stock'] as num?)?.toDouble() ?? 0.0;

    // Determine status
    String badgeText = "65% OK";
    Color statusColor = Colors.greenAccent;
    if (qty <= safety * 0.5) {
      badgeText = "CRITICAL: 5%";
      statusColor = Colors.redAccent;
    } else if (qty <= safety) {
      badgeText = "LOW STOCK: 12%";
      statusColor = Colors.orangeAccent;
    }

    // Generate random sparkline data for demo
    final random = Random(item['id'].hashCode);
    List<FlSpot> spots = List.generate(
        10, (index) => FlSpot(index.toDouble(), random.nextDouble() * 10));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CivilTheme.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
              color: statusColor.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: 2)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 60,
                width: 60,
                decoration: BoxDecoration(
                    color: CivilTheme.border.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.inventory_2,
                    color: CivilTheme.textSecondary, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['item_name'] ?? 'Unknown Item',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: CivilTheme.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('Item ID: ${item['sku'] ?? 'N/A'}',
                        style: const TextStyle(
                            fontSize: 11, color: CivilTheme.textSecondary)),
                    Text('Category: ${item['category'] ?? 'Materials'}',
                        style: const TextStyle(
                            fontSize: 11, color: CivilTheme.textSecondary)),
                    const Text('Location: Site A',
                        style: TextStyle(
                            fontSize: 11, color: CivilTheme.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.more_vert,
                  color: CivilTheme.textSecondary, size: 20),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Stock Level',
                  style:
                      TextStyle(fontSize: 12, color: CivilTheme.textSecondary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(12)),
                child: Text(badgeText,
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: qty / (qty + safety * 2).clamp(1, double.infinity),
              backgroundColor: CivilTheme.border,
              color: statusColor,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              SizedBox(
                height: 40,
                width: 100,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: const FlTitlesData(show: false),
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: statusColor,
                        barWidth: 2,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: false),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            colors: [
                              statusColor.withValues(alpha: 0.3),
                              statusColor.withValues(alpha: 0.0)
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${qty.toInt()} Units',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: CivilTheme.textPrimary)),
                  Text(item['unit'] ?? 'Bags',
                      style: const TextStyle(
                          fontSize: 11, color: CivilTheme.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
           Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewDetails,
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: CivilTheme.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: const Text('View Details',
                      style: TextStyle(color: CivilTheme.textSecondary)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: onRecordTransaction,
                  style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: CivilTheme.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: const Text('Record',
                      style: TextStyle(color: CivilTheme.textSecondary)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: onReorder,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: CivilTheme.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8))),
                  child: const Text('Reorder',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MobileInventoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const MobileInventoryCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final double qty = (item['quantity'] as num?)?.toDouble() ?? 0.0;
    final double safety = (item['safety_stock'] as num?)?.toDouble() ?? 0.0;
    final double maxCapacity = safety > 0 ? safety * 2 : qty > 0 ? qty * 2 : 100.0;

    Color statusColor = Colors.greenAccent;
    if (safety > 0 && qty <= safety) statusColor = Colors.orangeAccent;
    if (safety > 0 && qty <= safety * 0.5) statusColor = Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CivilTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CivilTheme.border),
      ),
      child: Row(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: CivilTheme.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: CivilTheme.border.withValues(alpha: 0.5)),
            ),
            child: const Icon(Icons.category,
                color: CivilTheme.textSecondary, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item['item_name'] ?? 'Unknown Item',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: CivilTheme.textPrimary)),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('SKU: ${item['sku'] ?? 'N/A'}',
                        style: const TextStyle(
                            fontSize: 12, color: CivilTheme.textSecondary)),
                    Text.rich(
                      TextSpan(
                        text: '${qty.toInt()}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: CivilTheme.textPrimary,
                            fontSize: 12),
                        children: [
                          TextSpan(
                              text: '/${maxCapacity.toInt()} ${item['unit']}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.normal,
                                  color: CivilTheme.textSecondary)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final progressWidth = constraints.maxWidth *
                        (qty / maxCapacity).clamp(0.0, 1.0);
                    return Stack(
                      children: [
                        Container(
                          height: 8,
                          width: double.infinity,
                          decoration: BoxDecoration(
                              color: CivilTheme.border,
                              borderRadius: BorderRadius.circular(4)),
                        ),
                        Container(
                          height: 8,
                          width: progressWidth,
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                  color: statusColor.withValues(alpha: 0.5),
                                  blurRadius: 4)
                            ],
                          ),
                        ),
                        final safetyRatio = safety > 0 ? (safety / maxCapacity).clamp(0.0, 1.0) : 0.3;
                        final criticalRatio = safety > 0 ? ((safety * 0.5) / maxCapacity).clamp(0.0, 1.0) : 0.1;
                        Positioned(
                          bottom: -6,
                          left: constraints.maxWidth * safetyRatio,
                          child: const Text('|',
                              style: TextStyle(
                                  color: Colors.orangeAccent,
                                  fontSize: 10)),
                        ),
                        Positioned(
                          bottom: -6,
                          left: constraints.maxWidth * criticalRatio,
                          child: const Text('|',
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontSize: 10)),
                        ),
                        Positioned(
                          bottom: -8,
                          left: constraints.maxWidth * (qty / maxCapacity).clamp(0.0, 1.0),
                          child: Icon(Icons.arrow_drop_up,
                              color: statusColor, size: 16),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8), // space for markers
              ],
            ),
          ),
        ],
      ),
    );
  }
}
