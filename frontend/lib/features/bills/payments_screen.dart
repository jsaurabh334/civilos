import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';
import '../../core/confirm_dialog.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _transactions = [];

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
      final response = await ref.read(apiClientProvider).get('/payments');
      final list = response is List
          ? response.cast<Map<String, dynamic>>()
          : response is Map && response['data'] is List
              ? (response['data'] as List).cast<Map<String, dynamic>>()
              : <Map<String, dynamic>>[];
      setState(() => _transactions = list);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showDetailSheet(Map<String, dynamic> txn) {
    final amount = (txn['amount'] ?? 0).toDouble();
    final status = txn['status']?.toString() ?? 'N/A';
    final Color statusColor = status == 'Successful' || status == 'Completed'
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
                const Text('Transaction Details',
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
            _detailRow('Txn ID', txn['id']?.toString() ?? 'N/A'),
            _detailRow('Vendor',
                txn['vendor']?.toString() ?? txn['vendor_name']?.toString() ?? 'N/A'),
            _detailRow('Date',
                txn['payment_date']?.toString() ?? txn['date']?.toString() ?? 'N/A'),
            _detailRow('Method',
                txn['payment_method']?.toString() ?? txn['method']?.toString() ?? 'N/A'),
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
            if (txn['notes'] != null) ...[
              const SizedBox(height: 12),
              Text('Notes: ${txn['notes']}',
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

  Color _statusColor(String status) {
    switch (status) {
      case 'Successful':
      case 'Completed':
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
      appBar: AppBar(title: const Text('Payments & Transactions')),
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
              : _transactions.isEmpty
                  ? const Center(child: Text("No transactions found."))
                  : RefreshIndicator(
                      onRefresh: _fetchData,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _transactions.length,
                        itemBuilder: (context, index) {
                          final txn = _transactions[index];
                          final amount =
                              (txn['amount'] ?? 0).toDouble();
                          final status =
                              txn['status']?.toString() ?? 'N/A';
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
                                child: Icon(Icons.swap_horiz,
                                    color: color),
                              ),
                              title: Text(
                                  "Paid: ₹${amount.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                      "To: ${txn['vendor'] ?? txn['vendor_name'] ?? 'N/A'}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(
                                      "Txn ID: ${txn['id'] ?? 'N/A'}"),
                                  const SizedBox(height: 4),
                                  Text(
                                      "Date: ${txn['payment_date'] ?? txn['date'] ?? 'N/A'} | Via: ${txn['payment_method'] ?? txn['method'] ?? 'N/A'}"),
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
                              onTap: () => _showDetailSheet(txn),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
