import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/confirm_dialog.dart';

class VendorInvoicingScreen extends ConsumerStatefulWidget {
  const VendorInvoicingScreen({super.key});

  @override
  ConsumerState<VendorInvoicingScreen> createState() =>
      _VendorInvoicingScreenState();
}

class _VendorInvoicingScreenState
    extends ConsumerState<VendorInvoicingScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _invoices = [];
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response =
          await ref.read(apiClientProvider).get('/vendor/purchase-orders');
      final list = response is List
          ? response.cast<Map<String, dynamic>>()
          : <Map<String, dynamic>>[];
      setState(() => _invoices = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDetailSheet(Map<String, dynamic> invoice) {
    final amount = (invoice['total_cost'] ?? invoice['amount'] ?? 0).toDouble();
    final status = invoice['status'] ?? 'N/A';
    final Color statusColor = status == 'Paid' || status == 'Approved'
        ? Colors.green
        : status == 'Overdue' || status == 'Rejected'
            ? Colors.red
            : Colors.orange;

    showModalBottomSheet(
      context: context,
      backgroundColor: CivilTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('Invoice Details',
                    style: TextStyle(
                        color: CivilTheme.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: CivilTheme.textSecondary),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            const Divider(color: CivilTheme.border),
            const SizedBox(height: 8),
            _detailRow('PO / Reference', invoice['id']?.toString() ?? 'N/A'),
            _detailRow('Item',
                invoice['item_name'] ?? invoice['description'] ?? 'N/A'),
            _detailRow('Quantity',
                '${invoice['quantity'] ?? 'N/A'} ${invoice['unit'] ?? ''}'),
            _detailRow('Amount', '₹${amount.toStringAsFixed(2)}'),
            _detailRow('Order Date', invoice['order_date'] ?? 'N/A'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                'Status: $status',
                style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: const TextStyle(
                    color: CivilTheme.textSecondary, fontSize: 14)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: CivilTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    final formKey = GlobalKey<FormState>();
    final amountController = TextEditingController();
    final descController = TextEditingController();
    int? selectedPoId;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: CivilTheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Create Invoice',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: CivilTheme.textPrimary)),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<int>(
                        value: selectedPoId,
                        dropdownColor: CivilTheme.surface,
                        style: const TextStyle(color: CivilTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Purchase Order',
                          labelStyle:
                              TextStyle(color: CivilTheme.textSecondary),
                        ),
                        items: _invoices.map((po) {
                          return DropdownMenuItem<int>(
                            value: po['id'] is int ? po['id'] : int.tryParse(po['id']?.toString() ?? ''),
                            child: Text(
                                '${po['id']} - ${po['item_name'] ?? 'N/A'}'),
                          );
                        }).toList(),
                        onChanged: (v) => setDialogState(() => selectedPoId = v),
                        validator: (v) => v == null ? 'Select a PO' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: CivilTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Invoice Amount',
                          labelStyle:
                              TextStyle(color: CivilTheme.textSecondary),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descController,
                        maxLines: 3,
                        style: const TextStyle(color: CivilTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Description / Notes',
                          labelStyle:
                              TextStyle(color: CivilTheme.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel',
                                style: TextStyle(
                                    color: CivilTheme.textSecondary)),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: _isCreating
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setState(() => _isCreating = true);
                                    try {
                                      await ref
                                          .read(apiClientProvider)
                                          .post(
                                              '/vendor/purchase-orders/$selectedPoId/invoice',
                                              {
                                                'amount': double.tryParse(
                                                        amountController.text) ??
                                                    0,
                                                'notes': descController.text.trim(),
                                              });
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (mounted) {
                                        showToast(context,
                                            'Invoice created successfully');
                                        _fetchData();
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        showToast(context,
                                            'Failed: $e',
                                            isError: true);
                                      }
                                    } finally {
                                      if (mounted) setState(() => _isCreating = false);
                                    }
                                  },
                            child: const Text('Submit Invoice'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Paid':
      case 'Approved':
        return Colors.green;
      case 'Overdue':
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoices')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Error: $_error',
                          style: const TextStyle(color: CivilTheme.error)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                          onPressed: _fetchData,
                          child: const Text('Retry')),
                    ],
                  ),
                )
              : _invoices.isEmpty
                  ? const Center(child: Text("No invoices found."))
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _invoices.length,
                        itemBuilder: (context, index) {
                          final invoice = _invoices[index];
                          final status =
                              invoice['status']?.toString() ?? 'Issued';
                          final color = _statusColor(status);
                          final amount =
                              (invoice['total_cost'] ?? invoice['amount'] ?? 0)
                                  .toDouble();

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: color.withOpacity(0.1),
                                child:
                                    Icon(Icons.receipt, color: color),
                              ),
                              title: Text(
                                  invoice['id']?.toString() ?? 'N/A',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                      "${invoice['item_name'] ?? invoice['description'] ?? ''}"),
                                  const SizedBox(height: 4),
                                  Text("Amount: ₹${amount.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold)),
                                ],
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: color),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold),
                                ),
                              ),
                              onTap: () => _showDetailSheet(invoice),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: CivilTheme.primary,
        onPressed: _invoices.isEmpty ? null : _showCreateDialog,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Invoice',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
