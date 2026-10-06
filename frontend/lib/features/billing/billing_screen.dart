import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/billing_provider.dart';
import '../../core/providers/project_provider.dart';
import '../../core/theme.dart';
import '../../core/download_helper.dart';

class BillingScreen extends ConsumerStatefulWidget {
  const BillingScreen({super.key});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  final _searchController = TextEditingController();
  String _filterStatus = 'All';
  String _filterDateRange = 'All';
  bool _showFilters = false;

  static const _statuses = ['All', 'Paid', 'Pending', 'Overdue'];
  static const _dateRanges = ['All', 'Last 7 days', 'Last 30 days', 'Last 90 days'];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(billingProvider.notifier).fetchInvoices();
      ref.read(projectProvider.notifier).fetchProjects();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    ref.read(billingProvider.notifier).fetchInvoices(
      status: _filterStatus,
      dateRange: _filterDateRange == 'All' ? null : _filterDateRange,
    );
  }

  void _showCreateInvoiceDialog(BuildContext ctx) {
    final clientController = TextEditingController();
    final amountController = TextEditingController();
    String status = 'Pending';

    showDialog(
      context: ctx,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setDState) => AlertDialog(
          backgroundColor: CivilTheme.surface,
          title: const Text('Create Invoice', style: TextStyle(color: CivilTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: clientController,
                style: const TextStyle(color: CivilTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Client Name', labelStyle: TextStyle(color: CivilTheme.textSecondary)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: CivilTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Amount (₹)', labelStyle: TextStyle(color: CivilTheme.textSecondary)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: status,
                dropdownColor: CivilTheme.surface,
                style: const TextStyle(color: CivilTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Status', labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                items: ['Pending', 'Paid', 'Overdue', 'Cancelled']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) { if (val != null) setDState(() => status = val); },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel', style: TextStyle(color: CivilTheme.textSecondary))),
            ElevatedButton(
              onPressed: () async {
                if (clientController.text.isEmpty || amountController.text.isEmpty) return;
                try {
                  await ref.read(billingProvider.notifier).createInvoice(
                    1,
                    'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
                    clientController.text.trim(),
                    DateTime.now().toIso8601String().split('T')[0],
                    DateTime.now().add(const Duration(days: 30)).toIso8601String().split('T')[0],
                    double.tryParse(amountController.text) ?? 0,
                  );
                  if (dCtx.mounted) Navigator.pop(dCtx);
                } catch (e) {
                  if (dCtx.mounted) {
                    ScaffoldMessenger.of(dCtx).showSnackBar(SnackBar(content: Text('Error: ${e.toString().replaceAll("Exception: ", "")}')));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: CivilTheme.primary),
              child: const Text('Create', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showFilterDialog(BuildContext ctx) {
    String filterStatus = 'All';
    String filterDateRange = 'All';
    showDialog(
      context: ctx,
      builder: (dCtx) => StatefulBuilder(
        builder: (dCtx, setDState) => AlertDialog(
          backgroundColor: CivilTheme.surface,
          title: const Text('Filter Invoices', style: TextStyle(color: CivilTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: filterStatus,
                dropdownColor: CivilTheme.surface,
                style: const TextStyle(color: CivilTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Status', labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                items: ['All', 'Pending', 'Paid', 'Overdue', 'Cancelled']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (val) { if (val != null) setDState(() => filterStatus = val); },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: filterDateRange,
                dropdownColor: CivilTheme.surface,
                style: const TextStyle(color: CivilTheme.textPrimary),
                decoration: const InputDecoration(labelText: 'Date Range', labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                items: ['All', 'Last 7 days', 'Last 30 days', 'Last 90 days']
                    .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (val) { if (val != null) setDState(() => filterDateRange = val); },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dCtx), child: const Text('Cancel', style: TextStyle(color: CivilTheme.textSecondary))),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dCtx);
                setState(() {
                  _filterStatus = filterStatus;
                  _filterDateRange = filterDateRange;
                });
                _applyFilters();
              },
              style: ElevatedButton.styleFrom(backgroundColor: CivilTheme.primary),
              child: const Text('Apply', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bill = ref.watch(billingProvider);
    final invoices = bill.invoices;

    // Calculate metrics
    double totalOwed = 0.0;
    double totalPaid = 0.0;
    double totalOverdue = 0.0;

    for (final inv in invoices) {
      final amt = (inv['total_amount'] as num?)?.toDouble() ?? 0.0;
      final status = inv['status'] ?? 'Unpaid';

      double paidForInv = 0.0;
      final payments = inv['payments'] as List?;
      if (payments != null) {
        for (final p in payments) {
          paidForInv += (p['amount'] as num?)?.toDouble() ?? 0.0;
        }
      }

      totalOwed += amt;
      totalPaid += paidForInv;
      if (status == 'Overdue') {
        totalOverdue += (amt - paidForInv);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 900;
        return Scaffold(


          backgroundColor: CivilTheme.background,
          body: isMobile
              ? _buildMobileLayout(invoices)
              : _buildDesktopLayout(
                  invoices, totalOwed, totalPaid, totalOverdue),
          floatingActionButton: isMobile
              ? FloatingActionButton(
                  backgroundColor: Colors.orangeAccent,
                  onPressed: () => _showCreateInvoiceDialog(context),
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null,
        );
      },
    );
  }

  // --- DESKTOP LAYOUT ---

  Widget _buildDesktopLayout(
      List<dynamic> invoices, double owed, double paid, double overdue) {
    final List<dynamic> displayInvoices = invoices;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(32.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Billing & Invoices',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: CivilTheme.textPrimary)),
              Row(
                children: [
                  _buildDesktopSummaryCard(
                      'Total Owed', '₹1,85,420', Colors.orangeAccent),
                  const SizedBox(width: 16),
                  _buildDesktopSummaryCard(
                      'Total Paid', '₹3,12,850', Colors.greenAccent),
                  const SizedBox(width: 16),
                  _buildDesktopSummaryCard(
                      'Overdue', '₹24,500', Colors.redAccent),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  height: 40,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: CivilTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: CivilTheme.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search,
                          color: CivilTheme.textSecondary, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: const TextStyle(
                              color: CivilTheme.textPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            hintText: 'Search invoices, clients...',
                            hintStyle:
                                TextStyle(color: CivilTheme.textSecondary),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(flex: 3),
              ElevatedButton(
                onPressed: () => _showCreateInvoiceDialog(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E5B7E),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                child: const Text('Create New Invoice',
                    style: TextStyle(color: Colors.white, fontSize: 13)),
              ),
              IconButton(
                icon: const Icon(Icons.download, color: CivilTheme.secondary),
                tooltip: 'Download Invoice PDF',
                onPressed: () {
                  final invoices = ref.read(billingProvider).invoices;
                  if (invoices.isNotEmpty) {
                    final first = invoices.first;
                    downloadExport('/export/invoices/${first['id']}/pdf', 'invoice_${first['invoice_number'] ?? first['id']}.pdf');
                  }
                },
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () => _showFilterDialog(context),
                icon: const Text('Filter/Export',
                    style: TextStyle(
                        color: CivilTheme.textSecondary, fontSize: 13)),
                label: const Icon(Icons.keyboard_arrow_down,
                    color: CivilTheme.textSecondary, size: 16),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: CivilTheme.border),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            decoration: BoxDecoration(
              color: CivilTheme.surface.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CivilTheme.border),
            ),
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      _buildHeader('Invoice #',
                          flex: 2, icon: Icons.keyboard_arrow_up),
                      _buildHeader('Client', flex: 2),
                      _buildHeader('Project', flex: 3),
                      _buildHeader('Date', flex: 2),
                      _buildHeader('Due Date', flex: 2),
                      _buildHeader('Amount', flex: 2),
                      _buildHeader('Status', flex: 2),
                      _buildHeader('Actions', flex: 2),
                    ],
                  ),
                ),
                const Divider(height: 1, color: CivilTheme.border),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: displayInvoices.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1, color: CivilTheme.border),
                    itemBuilder: (context, index) =>
                        _buildDesktopTableRow(displayInvoices[index]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopSummaryCard(
      String title, String amount, Color glowColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: CivilTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: glowColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(color: glowColor.withValues(alpha: 0.1), blurRadius: 20)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: CivilTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text(amount,
              style: const TextStyle(
                  color: CivilTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, {required int flex, IconData? icon}) {
    return Expanded(
      flex: flex,
      child: Row(
        children: [
          Text(title,
              style: const TextStyle(
                  color: CivilTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
          if (icon != null) ...[
            const SizedBox(width: 4),
            Icon(icon, size: 14, color: CivilTheme.textSecondary),
          ],
        ],
      ),
    );
  }

  Widget _buildDesktopTableRow(Map<String, dynamic> invoice) {
    final status = invoice['status']?.toString().toUpperCase() ?? 'UNPAID';
    Color statusColor = Colors.orangeAccent;
    if (status == 'PAID') statusColor = Colors.greenAccent;
    if (status == 'OVERDUE') statusColor = Colors.redAccent;

    final amt = (invoice['total_amount'] as num?)?.toDouble() ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Expanded(
              flex: 2,
              child: Text(invoice['invoice_number'] ?? '',
                  style: const TextStyle(
                      color: CivilTheme.textSecondary, fontSize: 13))),
          Expanded(
              flex: 2,
              child: Text(invoice['client_name'] ?? '',
                  style: const TextStyle(
                      color: CivilTheme.textPrimary, fontSize: 13))),
          Expanded(
              flex: 3,
              child: Text(
                  invoice['project']?['name'] ??
                      invoice['project'] ??
                      'General',
                  style: const TextStyle(
                      color: Colors.lightBlueAccent,
                      fontSize: 13,
                      decoration: TextDecoration.underline))),
          Expanded(
              flex: 2,
              child: Text(invoice['date'] ?? invoice['issue_date'] ?? '',
                  style: const TextStyle(
                      color: CivilTheme.textPrimary, fontSize: 13))),
          Expanded(
              flex: 2,
              child: Text(invoice['due_date'] ?? '',
                  style: const TextStyle(
                      color: CivilTheme.textPrimary, fontSize: 13))),
          Expanded(
              flex: 2,
              child: Text('\$${amt.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: CivilTheme.textPrimary, fontSize: 13))),
          Expanded(
              flex: 2,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(12)),
                  child: Text(status,
                      style: const TextStyle(
                          color: CivilTheme.background,
                          fontSize: 10,
                          fontWeight: FontWeight.bold)),
                ),
              )),
          Expanded(
              flex: 2,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.remove_red_eye_outlined,
                      color: CivilTheme.textSecondary, size: 16),
                  const SizedBox(width: 16),
                  const Icon(Icons.edit_outlined,
                      color: CivilTheme.textSecondary, size: 16),
                  const SizedBox(width: 16),
                  const Icon(Icons.more_horiz,
                      color: CivilTheme.textSecondary, size: 16),
                ],
              )),
        ],
      ),
    );
  }

  // --- MOBILE LAYOUT ---

  Widget _buildMobileLayout(List<dynamic> invoices) {
    final List<dynamic> displayInvoices = invoices.isNotEmpty
        ? invoices
        : [
            {
              'invoice_number': '#001245',
              'client_name': 'Apex Heights',
              'project': 'Apex Tower B',
              'date': 'Nov 10, 2023',
              'total_amount': 24500.0,
              'status': 'Paid'
            },
            {
              'invoice_number': '#001244',
              'client_name': 'Urban Build',
              'project': 'Oakwood Project',
              'date': 'Oct 28, 2023',
              'total_amount': 18750.0,
              'status': 'Unpaid'
            },
            {
              'invoice_number': '#001243',
              'client_name': 'Skyline Corp',
              'project': 'Riverwalk Phase 2',
              'date': 'Nov 25, 2023',
              'total_amount': 9300.0,
              'status': 'Pending'
            },
            {
              'invoice_number': '#001242',
              'client_name': 'Coastal Devs',
              'project': 'Harbor Project',
              'date': 'Dec 15, 2023',
              'total_amount': 45000.0,
              'status': 'Overdue'
            },
          ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF2C3545), Color(0xFF1B2330)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text('🏗️', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      const Text('Billing & Invoices',
                          style: TextStyle(
                              color: CivilTheme.textPrimary,
                              fontSize: 22,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
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
                                  style: const TextStyle(
                                      color: CivilTheme.textPrimary,
                                      fontSize: 14),
                                  decoration: const InputDecoration(
                                    hintText: 'Search Invoices...',
                                    hintStyle: TextStyle(
                                        color: CivilTheme.textSecondary),
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
                            color: CivilTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CivilTheme.border)),
                        child: GestureDetector(
                          onTap: () => setState(() => _showFilters = !_showFilters),
                          child: Icon(Icons.filter_list,
                              color: _showFilters ? CivilTheme.primary : CivilTheme.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                            color: CivilTheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: CivilTheme.border)),
                        child: const Icon(Icons.swap_vert,
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
                          ..._statuses.map((s) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(s, style: const TextStyle(fontSize: 12, color: Colors.white)),
                              selected: _filterStatus == s,
                              onSelected: (_) {
                                setState(() => _filterStatus = s);
                                _applyFilters();
                              },
                              selectedColor: CivilTheme.primary,
                              backgroundColor: CivilTheme.surface,
                              checkmarkColor: Colors.white,
                              side: BorderSide(color: CivilTheme.border),
                            ),
                          )),
                          const SizedBox(width: 8),
                          ..._dateRanges.map((d) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(d, style: const TextStyle(fontSize: 12, color: Colors.white)),
                              selected: _filterDateRange == d,
                              onSelected: (_) {
                                setState(() => _filterDateRange = d);
                                _applyFilters();
                              },
                              selectedColor: CivilTheme.secondary,
                              backgroundColor: CivilTheme.surface,
                              checkmarkColor: Colors.white,
                              side: BorderSide(color: CivilTheme.border),
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
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: displayInvoices.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) =>
                  _buildMobileInvoiceCard(displayInvoices[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileInvoiceCard(Map<String, dynamic> invoice) {
    final status = invoice['status']?.toString().toUpperCase() ?? 'UNPAID';
    Color statusColor = Colors.redAccent;
    Color bgColor = CivilTheme.surface;

    if (status == 'PAID') {
      statusColor = Colors.greenAccent;
    }
    if (status == 'PENDING') {
      statusColor = Colors.orangeAccent;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CivilTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text('Client: ${invoice['client_name']}',
                    style: const TextStyle(
                        color: CivilTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Text(status,
                        style: const TextStyle(
                            color: CivilTheme.background,
                            fontSize: 10,
                            fontWeight: FontWeight.bold)),
                    if (status == 'PAID') ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.check_circle,
                          color: CivilTheme.background, size: 12),
                    ] else if (status == 'UNPAID') ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.error,
                          color: CivilTheme.background, size: 12),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
              '(${invoice['project'] is String ? invoice['project'] : invoice['project']?['name'] ?? 'General Project'})',
              style: const TextStyle(
                  color: CivilTheme.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.description_outlined,
                  color: CivilTheme.textSecondary, size: 16),
              const SizedBox(width: 6),
              Text('Inv ${invoice['invoice_number']}',
                  style: const TextStyle(
                      color: CivilTheme.textSecondary, fontSize: 13)),
              const Spacer(),
              const Icon(Icons.calendar_today_outlined,
                  color: CivilTheme.textSecondary, size: 16),
              const SizedBox(width: 6),
              Text('${invoice['date'] ?? invoice['issue_date']}',
                  style: const TextStyle(
                      color: CivilTheme.textSecondary, fontSize: 13)),
              const Spacer(),
              Text('\$${(invoice['total_amount'] as num?)?.toStringAsFixed(2)}',
                  style: const TextStyle(
                      color: CivilTheme.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: CivilTheme.border, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMobileAction(Icons.download, 'Download'),
              _buildMobileAction(Icons.remove_red_eye_outlined, 'View'),
              _buildMobileAction(Icons.credit_card, 'PayNow'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileAction(IconData icon, String label) {
    return Row(
      children: [
        Icon(icon, color: CivilTheme.textSecondary, size: 16),
        const SizedBox(width: 6),
        Text(label,
            style:
                const TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
      ],
    );
  }
}
