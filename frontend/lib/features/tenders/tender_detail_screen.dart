import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme.dart';
import '../../core/empty_state.dart';

class TenderDetailScreen extends ConsumerWidget {
  final Map<String, dynamic> tender;

  const TenderDetailScreen({super.key, required this.tender});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        backgroundColor: CivilTheme.background,
        appBar: AppBar(
          backgroundColor: CivilTheme.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              context.go('/tenders'); // Back to Tenders
            },
          ),
          title: Text(
            tender['tender_name'] ?? 'Tender Details',
            style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 16),
          ),
          iconTheme: const IconThemeData(color: CivilTheme.textPrimary),
          bottom: const TabBar(
            isScrollable: true,
            indicatorColor: CivilTheme.primary,
            labelColor: CivilTheme.primary,
            unselectedLabelColor: CivilTheme.textSecondary,
            tabs: [
              Tab(text: 'Overview'),
              Tab(text: 'Documents'),
              Tab(text: 'BOQ'),
              Tab(text: 'Risk & Strategy'),
              Tab(text: 'Competitors'),
              Tab(text: 'Approvals'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOverviewTab(),
            EmptyState(icon: Icons.description, title: 'No Tender Documents', subtitle: 'Upload NIT or Corrigendum in the Documents workspace', actionLabel: 'Upload', onAction: () {}),
            EmptyState(icon: Icons.list_alt, title: 'No BOQ Items', subtitle: 'Import BOQ items from Excel or create manually', actionLabel: 'Import BOQ', onAction: () {}),
            EmptyState(icon: Icons.warning, title: 'No Risk Assessment', subtitle: 'Perform risk assessment to calculate contingencies'),
            EmptyState(icon: Icons.business, title: 'No Competitors Logged', subtitle: 'Track other bidders to improve win probability'),
            EmptyState(icon: Icons.check_circle, title: 'No Approvals Needed', subtitle: 'Tender is in preparation phase'),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewTab() {
    final details = tender['details'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoCard('Basic Information', [
            _buildDetailRow('Tender No', tender['tender_no'] ?? 'N/A'),
            _buildDetailRow('Department', tender['department'] ?? 'N/A'),
            _buildDetailRow('Type', tender['tender_type'] ?? 'N/A'),
            _buildDetailRow('Status', tender['status'] ?? 'N/A'),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard('Financial Overview', [
            _buildDetailRow('Estimated Cost', '₹${details['estimated_cost'] ?? 0}'),
            _buildDetailRow('EMD Amount', '₹${details['emd_amount'] ?? 0}'),
            _buildDetailRow('Tender Fee', '₹${details['tender_fee'] ?? 0}'),
            _buildDetailRow('Security Deposit', '${details['security_deposit_pct'] ?? 0}%'),
          ]),
          const SizedBox(height: 16),
          _buildInfoCard('Important Dates', [
            _buildDetailRow('Publish Date', _formatDate(tender['important_dates']?['publish_date'])),
            _buildDetailRow('Submission Last Date', _formatDate(tender['important_dates']?['submission_last_date'])),
            _buildDetailRow('Technical Opening', _formatDate(tender['important_dates']?['technical_opening_date'])),
          ]),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CivilTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CivilTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
          const Divider(color: CivilTheme.border, height: 24),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 14)),
          Text(value, style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return 'N/A';
    try {
      final date = DateTime.parse(isoString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return isoString;
    }
  }
}
