import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/confirm_dialog.dart';

class BillsScreen extends ConsumerStatefulWidget {
  const BillsScreen({super.key});

  @override
  ConsumerState<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _bills = [];
  bool _isSubmitting = false;

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
      final response = await ref.read(apiClientProvider).get('/expenses');
      final list = response is List
          ? response.cast<Map<String, dynamic>>()
          : response is Map && response['data'] is List
              ? (response['data'] as List).cast<Map<String, dynamic>>()
              : <Map<String, dynamic>>[];
      setState(() => _bills = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDetailSheet(Map<String, dynamic> bill) {
    final amount = (bill['amount'] ?? 0).toDouble();
    final status = bill['status']?.toString() ?? 'N/A';
    final Color statusColor = status == 'Paid'
        ? Colors.green
        : status == 'Approved'
            ? Colors.blue
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
                const Text('Bill Details',
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
            _detailRow('Bill ID', bill['id']?.toString() ?? 'N/A'),
            _detailRow('Vendor',
                bill['vendor']?.toString() ?? bill['vendor_name']?.toString() ?? 'N/A'),
            _detailRow('Category', bill['category']?.toString() ?? 'N/A'),
            _detailRow('Date',
                bill['expense_date']?.toString() ?? bill['date']?.toString() ?? 'N/A'),
            _detailRow('Due Date', bill['due_date']?.toString() ?? bill['dueDate']?.toString() ?? 'N/A'),
            _detailRow('Amount', '₹${amount.toStringAsFixed(2)}'),
            if (bill['description'] != null) ...[
              const SizedBox(height: 8),
              Text('Description: ${bill['description']}',
                  style: const TextStyle(color: CivilTheme.textSecondary)),
            ],
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
            width: 80,
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

  void _showUploadDialog() {
    final formKey = GlobalKey<FormState>();
    final vendorController = TextEditingController();
    final amountController = TextEditingController();
    final descController = TextEditingController();
    final dateController = TextEditingController();
    final dueDateController = TextEditingController();
    String category = 'Material';

    final List<String> categories = [
      'Material', 'Labour', 'Equipment', 'Fuel', 'Misc'
    ];

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
                      const Text('Upload New Bill',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: CivilTheme.textPrimary)),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: vendorController,
                        style: const TextStyle(color: CivilTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Vendor Name',
                          labelStyle:
                              TextStyle(color: CivilTheme.textSecondary),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: category,
                        dropdownColor: CivilTheme.surface,
                        style: const TextStyle(color: CivilTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          labelStyle:
                              TextStyle(color: CivilTheme.textSecondary),
                        ),
                        items: categories
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) =>
                            setDialogState(() => category = v!),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: CivilTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Amount (₹)',
                          labelStyle:
                              TextStyle(color: CivilTheme.textSecondary),
                        ),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: dateController,
                        style: const TextStyle(color: CivilTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Bill Date (YYYY-MM-DD)',
                          labelStyle:
                              TextStyle(color: CivilTheme.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: dueDateController,
                        style: const TextStyle(color: CivilTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Due Date (YYYY-MM-DD)',
                          labelStyle:
                              TextStyle(color: CivilTheme.textSecondary),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: descController,
                        maxLines: 2,
                        style: const TextStyle(color: CivilTheme.textPrimary),
                        decoration: const InputDecoration(
                          labelText: 'Description',
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
                            onPressed: _isSubmitting
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setState(() => _isSubmitting = true);
                                    try {
                                      await ref
                                          .read(apiClientProvider)
                                          .post('/expenses', {
                                        'vendor_name':
                                            vendorController.text.trim(),
                                        'category': category,
                                        'amount': double.tryParse(
                                                amountController.text) ??
                                            0,
                                        'expense_date':
                                            dateController.text.trim(),
                                        'due_date':
                                            dueDateController.text.trim(),
                                        'description':
                                            descController.text.trim(),
                                      });
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      if (mounted) {
                                        showToast(context,
                                            'Bill uploaded successfully');
                                        _fetchData();
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        showToast(context,
                                            'Failed: $e',
                                            isError: true);
                                      }
                                    } finally {
                                      if (mounted) {
                                        setState(
                                            () => _isSubmitting = false);
                                      }
                                    }
                                  },
                            child: const Text('Upload'),
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
        return Colors.green;
      case 'Approved':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Bills & Invoices')),
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
              : _bills.isEmpty
                  ? const Center(child: Text("No bills found."))
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _bills.length,
                        itemBuilder: (context, index) {
                          final bill = _bills[index];
                          final amount =
                              (bill['amount'] ?? 0).toDouble();
                          final status =
                              bill['status']?.toString() ?? 'Pending';
                          final color = _statusColor(status);

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor: color.withOpacity(0.1),
                                child: Icon(Icons.request_quote,
                                    color: color),
                              ),
                              title: Text(
                                  bill['id']?.toString() ?? 'N/A',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                      "Vendor: ${bill['vendor'] ?? bill['vendor_name'] ?? 'N/A'}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(
                                      "Received: ${bill['expense_date'] ?? bill['date'] ?? 'N/A'} | Due: ${bill['due_date'] ?? bill['dueDate'] ?? 'N/A'}"),
                                  const SizedBox(height: 4),
                                  Text(
                                      "Amount: ₹${amount.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15)),
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
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12),
                                ),
                              ),
                              onTap: () => _showDetailSheet(bill),
                            ),
                          );
                        },
                      ),
                    ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: CivilTheme.primary,
        onPressed: _showUploadDialog,
        icon: const Icon(Icons.upload_file, color: Colors.white),
        label: const Text('Upload Bill',
            style: TextStyle(color: Colors.white)),
      ),
    );
  }
}
