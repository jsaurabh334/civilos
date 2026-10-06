import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/purchase_order_provider.dart';
import '../../core/theme.dart';
import '../../core/confirm_dialog.dart';
import '../../core/components/civil_data_table.dart';


class PurchaseOrdersScreen extends ConsumerStatefulWidget {
  const PurchaseOrdersScreen({super.key});

  @override
  ConsumerState<PurchaseOrdersScreen> createState() =>
      _PurchaseOrdersScreenState();
}

class _PurchaseOrdersScreenState extends ConsumerState<PurchaseOrdersScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(purchaseOrderProvider.notifier).fetchPurchaseOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filteredOrders(List<dynamic> orders) {
    if (_searchQuery.isEmpty) return orders.cast<Map<String, dynamic>>();
    return orders
        .where((o) {
          final po = o as Map<String, dynamic>;
          final query = _searchQuery.toLowerCase();
          return (po['vendor_name']?.toString().toLowerCase().contains(query) ??
                  false) ||
              (po['item_name']?.toString().toLowerCase().contains(query) ??
                  false);
        })
        .cast<Map<String, dynamic>>()
        .toList();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber;
      case 'approved':
        return Colors.blueAccent;
      case 'received':
        return Colors.greenAccent;
      case 'cancelled':
        return Colors.redAccent;
      default:
        return CivilTheme.textSecondary;
    }
  }

  void _showCreateDialog() {
    showDialog(
        context: context,
        builder: (context) => _CreatePurchaseOrderDialog(ref: ref));
  }

  Future<void> _updateStatus(Map<String, dynamic> po) async {
    final currentStatus = (po['status'] as String?)?.toLowerCase() ?? 'pending';
    final statusFlow = ['pending', 'approved', 'received', 'cancelled'];
    final currentIndex = statusFlow.indexOf(currentStatus);
    if (currentIndex < 0) return;

    if (currentStatus == 'received' || currentStatus == 'cancelled') {
      if (mounted) {
        showToast(context, 'Purchase order cannot be updated further.');
      }
      return;
    }

    final nextStatus = statusFlow[currentIndex + 1];

    final confirm = await showConfirmDialog(
      context,
      title: 'Update Status',
      message: 'Change status from $currentStatus to $nextStatus?',
    );
    if (!confirm) return;

    try {
      await ref
          .read(purchaseOrderProvider.notifier)
          .updatePurchaseOrderStatus(po['id'] as int, nextStatus);
      if (mounted) showToast(context, 'Status updated successfully');
    } catch (e) {
      if (mounted) {
        showToast(context, 'Failed to update status: $e', isError: true);
      }
    }
  }

  Future<void> _deletePurchaseOrder(Map<String, dynamic> po) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Delete Purchase Order',
      message: 'Are you sure you want to delete this purchase order?',
    );
    if (!confirm) return;

    try {
      await ref
          .read(purchaseOrderProvider.notifier)
          .deletePurchaseOrder(po['id'] as int);
      if (mounted) showToast(context, 'Purchase order deleted successfully');
    } catch (e) {
      if (mounted) {
        showToast(context, 'Failed to delete purchase order: $e',
            isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final po = ref.watch(purchaseOrderProvider);
    final orders = _filteredOrders(po.purchaseOrders);
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
                      const Text('Procurement Command Center', style: TextStyle(color: CivilTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _showCreateDialog,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Create PO'),
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
                              const Text('Pending Approvals', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
                              const SizedBox(height: 8),
                              const Text('8', style: TextStyle(color: Colors.orangeAccent, fontSize: 28, fontWeight: FontWeight.bold)),
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
                              const Text('Total PO Value', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
                              const SizedBox(height: 8),
                              const Text('\$124,500', style: TextStyle(color: Colors.teal, fontSize: 28, fontWeight: FontWeight.bold)),
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
                              const Text('Delivered Orders', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
                              const SizedBox(height: 8),
                              const Text('42', style: TextStyle(color: Colors.blueAccent, fontSize: 28, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Search
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
                        const Icon(Icons.search, color: CivilTheme.textSecondary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 14),
                            decoration: const InputDecoration(
                              hintText: 'Search purchase orders...',
                              hintStyle: TextStyle(color: CivilTheme.textSecondary),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onChanged: (v) => setState(() => _searchQuery = v),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Table
                  Expanded(
                    child: po.isLoading && orders.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : orders.isEmpty
                            ? const Center(child: Text('No purchase orders.', style: TextStyle(color: CivilTheme.textSecondary)))
                            : CivilDataTable(
                                columns: const ['Vendor', 'Item', 'Qty', 'Amount', 'Status', 'Actions'],
                                rows: orders.map((o) {
                                  final status = (o['status'] as String?) ?? 'pending';
                                  final color = _statusColor(status);
                                  return <Widget>[
                                    Text(o['vendor_name'] ?? 'Unknown', style: const TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold)),
                                    Text(o['item_name'] ?? '', style: const TextStyle(color: CivilTheme.textSecondary)),
                                    Text('${o['quantity'] ?? ''} ${o['unit'] ?? ''}', style: const TextStyle(color: CivilTheme.textPrimary)),
                                    Text('\$${(o['total_cost'] as num?)?.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold)),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
                                      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
                                    ),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(icon: Icon(Icons.check_circle_outline, color: color, size: 16), onPressed: () => _updateStatus(o)),
                                        IconButton(icon: const Icon(Icons.delete, size: 16, color: CivilTheme.error), onPressed: () => _deletePurchaseOrder(o)),
                                      ],
                                    ),
                                  ];
                                }).toList(),
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

class _CreatePurchaseOrderDialog extends ConsumerStatefulWidget {
  final WidgetRef ref;
  const _CreatePurchaseOrderDialog({required this.ref});
  @override
  ConsumerState<_CreatePurchaseOrderDialog> createState() =>
      _CreatePurchaseOrderDialogState();
}

class _CreatePurchaseOrderDialogState
    extends ConsumerState<_CreatePurchaseOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _vendorController = TextEditingController();
  final _itemController = TextEditingController();
  final _qtyController = TextEditingController();
  final _unitController = TextEditingController();
  final _unitPriceController = TextEditingController();
  final _orderDateController = TextEditingController();
  final _expectedByController = TextEditingController();
  int? _selectedProjectId;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await widget.ref
          .read(purchaseOrderProvider.notifier)
          .createPurchaseOrder({
        'vendor_name': _vendorController.text.trim(),
        'item_name': _itemController.text.trim(),
        'quantity': double.tryParse(_qtyController.text) ?? 0,
        'unit': _unitController.text.trim(),
        'unit_price': double.tryParse(_unitPriceController.text) ?? 0,
        'order_date': _orderDateController.text.trim(),
        'expected_by': _expectedByController.text.trim(),
        'project_id': _selectedProjectId,
      });
      if (mounted) {
        Navigator.pop(context);
        showToast(context, 'Purchase order created successfully');
      }
    } catch (e) {
      if (mounted) showToast(context, 'Failed: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CivilTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Create PO',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: CivilTheme.textPrimary)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _vendorController,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Vendor Name',
                        labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _itemController,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Item Name',
                        labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _qtyController,
                          keyboardType: TextInputType.number,
                          style: const TextStyle(color: CivilTheme.textPrimary),
                          decoration: const InputDecoration(
                              labelText: 'Qty',
                              labelStyle:
                                  TextStyle(color: CivilTheme.textSecondary)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _unitController,
                          style: const TextStyle(color: CivilTheme.textPrimary),
                          decoration: const InputDecoration(
                              labelText: 'Unit',
                              labelStyle:
                                  TextStyle(color: CivilTheme.textSecondary)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _unitPriceController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Unit Price',
                        labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _orderDateController,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Order Date (YYYY-MM-DD)',
                        labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _expectedByController,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Expected By (YYYY-MM-DD)',
                        labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel',
                              style:
                                  TextStyle(color: CivilTheme.textSecondary))),
                      const SizedBox(width: 16),
                      ElevatedButton(
                          onPressed: _submit, child: const Text('Save')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
