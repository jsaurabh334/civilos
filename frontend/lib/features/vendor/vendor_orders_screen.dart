import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'vendor_po_provider.dart';

class VendorOrdersScreen extends ConsumerWidget {
  const VendorOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posAsync = ref.watch(vendorPOsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(vendorPOsProvider.notifier).fetchPOs(),
          ),
        ],
      ),
      body: posAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (pos) {
          if (pos.isEmpty) {
            return const Center(child: Text('No Purchase Orders assigned yet.'));
          }

          // Group POs by status for a simplified Kanban view
          final issuedPOs = pos.where((po) => po.status == 'Issued').toList();
          final acceptedPOs = pos.where((po) => po.status == 'Accepted').toList();
          final dispatchedPOs = pos.where((po) => po.status == 'Dispatched' || po.status == 'Delivered' || po.status == 'SupervisorVerified').toList();
          final confirmedPOs = pos.where((po) => po.status == 'ContractorConfirmed').toList();
          final historicalPOs = pos.where((po) => po.status == 'Invoiced' || po.status == 'Paid' || po.status == 'Completed').toList();

          return DefaultTabController(
            length: 5,
            child: Column(
              children: [
                const TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Inbox (New)'),
                    Tab(text: 'Processing'),
                    Tab(text: 'In Transit'),
                    Tab(text: 'Ready to Invoice'),
                    Tab(text: 'Completed'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _POList(pos: issuedPOs, type: 'issued'),
                      _POList(pos: acceptedPOs, type: 'accepted'),
                      _POList(pos: dispatchedPOs, type: 'dispatched'),
                      _POList(pos: confirmedPOs, type: 'confirmed'),
                      _POList(pos: historicalPOs, type: 'historical'),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _POList extends ConsumerWidget {
  final List<VendorPO> pos;
  final String type;

  const _POList({required this.pos, required this.type});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (pos.isEmpty) {
      return const Center(child: Text('No orders in this stage.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: pos.length,
      itemBuilder: (context, index) {
        final po = pos[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('PO #${po.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Chip(label: Text(po.status), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                  ],
                ),
                const SizedBox(height: 8),
                Text('${po.itemName} - ${po.quantity} ${po.unit}'),
                Text('Total: \$${po.totalCost.toStringAsFixed(2)}'),
                const SizedBox(height: 16),
                _buildActions(context, ref, po),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, VendorPO po) {
    if (type == 'issued') {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton(
            onPressed: () => ref.read(vendorPOsProvider.notifier).updateStatus(po.id, 'Rejected'),
            child: const Text('Reject', style: TextStyle(color: Colors.red)),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => ref.read(vendorPOsProvider.notifier).updateStatus(po.id, 'Accepted'),
            child: const Text('Accept Order'),
          ),
        ],
      );
    }
    if (type == 'accepted') {
      return Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          onPressed: () => ref.read(vendorPOsProvider.notifier).updateStatus(po.id, 'Dispatched'),
          child: const Text('Dispatch Material'),
        ),
      );
    }
    if (type == 'dispatched' && po.status == 'Dispatched') {
      return Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          onPressed: () => ref.read(vendorPOsProvider.notifier).updateStatus(po.id, 'Delivered'),
          child: const Text('Mark as Delivered to Site'),
        ),
      );
    }
    if (type == 'confirmed') {
      return Align(
        alignment: Alignment.centerRight,
        child: ElevatedButton(
          onPressed: () => _showInvoiceModal(context, ref, po),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
          child: const Text('Upload Invoice'),
        ),
      );
    }
    return const SizedBox.shrink(); // No actions for historical or waiting verification
  }

  void _showInvoiceModal(BuildContext context, WidgetRef ref, VendorPO po) {
    final amountCtrl = TextEditingController(text: po.totalCost.toStringAsFixed(2));
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // For glassmorphism effect later if needed
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Submit Invoice for PO #${po.id}', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                decoration: const InputDecoration(labelText: 'Invoice Amount', border: OutlineInputBorder()),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(labelText: 'Notes / Payment Terms', border: OutlineInputBorder()),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.upload_file, color: Colors.blue),
                    SizedBox(width: 8),
                    Text('Tap to upload PDF (Mocked)', style: TextStyle(color: Colors.blue)),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final amount = double.tryParse(amountCtrl.text) ?? 0.0;
                    if (amount > 0) {
                      ref.read(vendorPOsProvider.notifier).submitInvoice(po.id, amount, notesCtrl.text);
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice submitted successfully')));
                    }
                  },
                  child: const Text('Submit Invoice'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
