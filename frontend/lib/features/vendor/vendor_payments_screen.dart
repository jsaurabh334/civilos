import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/confirm_dialog.dart';

class VendorPaymentsScreen extends ConsumerStatefulWidget {
  const VendorPaymentsScreen({super.key});

  @override
  ConsumerState<VendorPaymentsScreen> createState() =>
      _VendorPaymentsScreenState();
}

class _VendorPaymentsScreenState extends ConsumerState<VendorPaymentsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _payments = [];

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
      final response = await ref.read(apiClientProvider).get('/invoices');
      final list = response is List
          ? response.cast<Map<String, dynamic>>()
          : response is Map && response['data'] is List
              ? (response['data'] as List).cast<Map<String, dynamic>>()
              : <Map<String, dynamic>>[];
      setState(() => _payments = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDetailSheet(Map<String, dynamic> payment) {
    final amount = (payment['amount'] ?? 0).toDouble();
    final status = payment['status']?.toString() ?? 'N/A';
    final Color statusColor = status == 'Completed' || status == 'Paid'
        ? Colors.green
        : status == 'Failed'
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
                const Text('Payment Details',
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
            _detailRow('Reference', payment['id']?.toString() ?? 'N/A'),
            _detailRow('Invoice',
                payment['invoice_id']?.toString() ?? payment['po_id']?.toString() ?? 'N/A'),
            _detailRow('Date', payment['payment_date']?.toString() ??
                payment['date']?.toString() ?? 'N/A'),
            _detailRow('Method',
                payment['payment_method']?.toString() ?? payment['method']?.toString() ?? 'N/A'),
            _detailRow('Amount', '₹${amount.toStringAsFixed(2)}'),
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
            if (payment['notes'] != null) ...[
              const SizedBox(height: 12),
              Text('Notes: ${payment['notes']}',
                  style: const TextStyle(color: CivilTheme.textSecondary)),
            ],
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

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
      case 'Paid':
        return Colors.green;
      case 'Failed':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payments Received')),
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
              : _payments.isEmpty
                  ? const Center(child: Text("No payments found."))
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _payments.length,
                        itemBuilder: (context, index) {
                          final payment = _payments[index];
                          final amount =
                              (payment['amount'] ?? 0).toDouble();
                          final status =
                              payment['status']?.toString() ?? 'N/A';
                          final color = _statusColor(status);

                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: CircleAvatar(
                                backgroundColor:
                                    CivilTheme.primary.withOpacity(0.1),
                                child: const Icon(Icons.account_balance_wallet,
                                    color: CivilTheme.primary),
                              ),
                              title: Text(
                                  "Amount: ₹${amount.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                      "Ref ID: ${payment['id'] ?? payment['invoice_id'] ?? 'N/A'}"),
                                  const SizedBox(height: 4),
                                  Text(
                                      "Date: ${payment['payment_date'] ?? payment['date'] ?? 'N/A'} | Method: ${payment['payment_method'] ?? payment['method'] ?? 'N/A'}"),
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
                              onTap: () => _showDetailSheet(payment),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
