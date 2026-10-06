import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/civil_scaffold.dart';
import '../../core/theme.dart';
import '../../core/providers/billing_provider.dart';
import '../../core/empty_state.dart';

class PaymentsScreen extends ConsumerStatefulWidget {
  const PaymentsScreen({super.key});

  @override
  ConsumerState<PaymentsScreen> createState() => _PaymentsScreenState();
}

class _PaymentsScreenState extends ConsumerState<PaymentsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(billingProvider.notifier).fetchInvoices());
  }

  @override
  Widget build(BuildContext context) {
    final billingState = ref.watch(billingProvider);

    return CivilScaffold(
      title: 'Payments & Invoicing',
      body: billingState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : billingState.invoices.isEmpty
              ? EmptyState(
                  icon: Icons.receipt_long,
                  title: 'No Payments Found',
                  subtitle: 'Start generating invoices and tracking payments.',
                  actionLabel: 'Create Invoice',
                  onAction: () {},
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: billingState.invoices.length,
                  itemBuilder: (context, index) {
                    final invoice = billingState.invoices[index];
                    final issueDate = DateTime.tryParse(invoice['issue_date'] ?? '');
                    final formattedDate = issueDate != null ? DateFormat('MMM d, yyyy').format(issueDate) : '';
                    final isPaid = invoice['status'] == 'Paid';

                    return Card(
                      color: CivilTheme.surface,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: CivilTheme.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isPaid ? Colors.green.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                          child: Icon(
                            isPaid ? Icons.check_circle : Icons.pending,
                            color: isPaid ? Colors.green : Colors.orange,
                          ),
                        ),
                        title: Text(
                          '${invoice['invoice_number']} - ${invoice['client_name']}',
                          style: const TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Issued: $formattedDate',
                          style: const TextStyle(color: CivilTheme.textSecondary),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '₹${invoice['total_amount'] ?? 0}',
                              style: const TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              invoice['status'] ?? 'Pending',
                              style: TextStyle(
                                color: isPaid ? Colors.green : Colors.orange,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
