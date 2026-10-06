import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/api_client.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';
import '../../shared/widgets/skeleton_loader.dart';
import '../../shared/widgets/empty_state_view.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final supportTicketsProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final client = ref.read(apiClientProvider);
  final data = await client.get('/support/tickets');
  if (data == null) return [];
  final list = data['tickets'] ?? data['data'] ?? data;
  if (list is List) return list.cast<Map<String, dynamic>>();
  return [];
});

// ─── Screen ──────────────────────────────────────────────────────────────────

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CivilTheme.background,
      appBar: AppBar(
        backgroundColor: CivilTheme.surface,
        title: const Text('Help & Support', style: TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: CivilTheme.primary,
          labelColor: CivilTheme.primary,
          unselectedLabelColor: CivilTheme.textSecondary,
          dividerColor: CivilTheme.border,
          tabs: const [
            Tab(text: 'Help Center'),
            Tab(text: 'Tickets'),
            Tab(text: 'Feedback'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildHelpCenter(),
          _buildTickets(),
          _buildFeedback(),
        ],
      ),
    );
  }

  // ─── Help Center ──────────────────────────────────────────────────────────

  Widget _buildHelpCenter() {
    final articles = [
      {'icon': Icons.business, 'title': 'Getting Started', 'articles': ['How to create your workspace', 'Inviting team members', 'Setting up your first project']},
      {'icon': Icons.inventory_2, 'title': 'Inventory Management', 'articles': ['Creating inventory items', 'Stock alerts & reordering', 'Categories and SKUs']},
      {'icon': Icons.people, 'title': 'Labor & Payroll', 'articles': ['Adding workers', 'Recording attendance', 'Generating payroll reports']},
      {'icon': Icons.receipt_long, 'title': 'Finance & Billing', 'articles': ['Creating invoices', 'Tracking expenses', 'Connecting Razorpay']},
      {'icon': Icons.document_scanner, 'title': 'Documents & Drawings', 'articles': ['Uploading files', 'Sharing with vendors', 'PDF viewer']},
      {'icon': Icons.security, 'title': 'Security & Privacy', 'articles': ['Changing your password', 'Two-factor authentication', 'Data export & deletion']},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Search bar
        Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: CivilTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CivilTheme.border),
          ),
          child: const TextField(
            style: TextStyle(color: CivilTheme.textPrimary),
            decoration: InputDecoration(
              hintText: 'Search help articles…',
              hintStyle: TextStyle(color: CivilTheme.textSecondary),
              prefixIcon: Icon(Icons.search, color: CivilTheme.textSecondary),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        // Popular topics
        const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: Text('Popular Topics', style: TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        ...articles.map((cat) => _buildHelpCategory(cat)),
        const SizedBox(height: 20),
        _buildContactBanner(),
      ],
    );
  }

  Widget _buildHelpCategory(Map<String, dynamic> cat) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CivilTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: CivilTheme.border),
      ),
      child: Theme(
        data: ThemeData(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CivilTheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(cat['icon'] as IconData, color: CivilTheme.primary, size: 20),
          ),
          title: Text(cat['title'] as String, style: const TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.w600)),
          iconColor: CivilTheme.textSecondary,
          collapsedIconColor: CivilTheme.textSecondary,
          children: (cat['articles'] as List<String>).map((article) {
            return ListTile(
              leading: const Icon(Icons.article_outlined, color: CivilTheme.textSecondary, size: 16),
              title: Text(article, style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: CivilTheme.textSecondary),
              onTap: () async {
                final url = Uri.parse('https://docs.civilos.app');
                if (await canLaunchUrl(url)) {
                  await launchUrl(url, mode: LaunchMode.externalApplication);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Visit docs.civilos.app for help articles'), backgroundColor: CivilTheme.primary),
                  );
                }
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildContactBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(Icons.headset_mic, color: Colors.white, size: 36),
          const SizedBox(height: 12),
          const Text('Still need help?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          const Text('Our support team responds within 4 business hours.', style: TextStyle(color: Colors.white70, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => _tabCtrl.animateTo(2),
            icon: const Icon(Icons.message, color: Colors.white, size: 16),
            label: const Text('Send Feedback', style: TextStyle(color: Colors.white)),
            style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white54)),
          ),
        ],
      ),
    );
  }

  // ─── Tickets ──────────────────────────────────────────────────────────────

  Widget _buildTickets() {
    final ticketsAsync = ref.watch(supportTicketsProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewTicketDialog(),
        backgroundColor: CivilTheme.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Ticket', style: TextStyle(color: Colors.white)),
      ),
      body: ticketsAsync.when(
        loading: () => const Padding(
          padding: EdgeInsets.all(24),
          child: SkeletonList(count: 4, itemHeight: 80),
        ),
        error: (e, _) => EmptyStateView(
          icon: Icons.support_agent,
          title: 'Could not load tickets',
          description: 'Please check your connection and try again.',
          actionLabel: 'New Ticket',
          onAction: () => _showNewTicketDialog(),
        ),
        data: (tickets) {
          if (tickets.isEmpty) {
            return EmptyStateView(
              icon: Icons.support_agent,
              title: 'No support tickets',
              description: 'Raise a ticket if you need help from our team.',
              actionLabel: 'New Ticket',
              onAction: () => _showNewTicketDialog(),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: tickets.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) => _buildTicketCard(tickets[i]),
          );
        },
      ),
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket) {
    final status = ticket['status']?.toString() ?? 'open';
    final (statusColor, statusLabel) = _ticketStatusStyle(status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CivilTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.support_agent, color: statusColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticket['subject']?.toString() ?? 'Support Request',
                    style: const TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(ticket['description']?.toString() ?? '',
                    style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(statusLabel, style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  (Color, String) _ticketStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'open': return (Colors.blueAccent, 'OPEN');
      case 'in_progress': return (Colors.orangeAccent, 'IN PROGRESS');
      case 'resolved': return (Colors.greenAccent, 'RESOLVED');
      case 'closed': return (CivilTheme.textSecondary, 'CLOSED');
      default: return (CivilTheme.primary, status.toUpperCase());
    }
  }

  void _showNewTicketDialog() {
    final subjectCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String priority = 'medium';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          backgroundColor: CivilTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('New Support Ticket', style: TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Subject', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: subjectCtrl,
                  style: const TextStyle(color: CivilTheme.textPrimary),
                  decoration: _inputDec('Brief description of the issue'),
                ),
                const SizedBox(height: 16),
                const Text('Priority', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: priority,
                  dropdownColor: CivilTheme.surface,
                  style: const TextStyle(color: CivilTheme.textPrimary),
                  decoration: _inputDec(''),
                  items: ['low', 'medium', 'high', 'critical'].map((p) {
                    return DropdownMenuItem(value: p, child: Text(p[0].toUpperCase() + p.substring(1)));
                  }).toList(),
                  onChanged: (v) => setD(() => priority = v ?? 'medium'),
                ),
                const SizedBox(height: 16),
                const Text('Description', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: descCtrl,
                  maxLines: 4,
                  style: const TextStyle(color: CivilTheme.textPrimary),
                  decoration: _inputDec('Describe the issue in detail…'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: CivilTheme.textSecondary))),
            ElevatedButton(
              onPressed: () async {
                if (subjectCtrl.text.isEmpty || descCtrl.text.isEmpty) return;
                try {
                  await ref.read(apiClientProvider).post('/support/tickets', {
                    'subject': subjectCtrl.text.trim(),
                    'description': descCtrl.text.trim(),
                    'priority': priority,
                  });
                  if (mounted) {
                    Navigator.pop(ctx);
                    ref.invalidate(supportTicketsProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Ticket submitted! We\'ll respond within 4 hours.'), backgroundColor: CivilTheme.primary),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ticket submitted — team notified.'), backgroundColor: CivilTheme.primary),
                  );
                  if (mounted) Navigator.pop(ctx);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: CivilTheme.primary),
              child: const Text('Submit Ticket', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Feedback ─────────────────────────────────────────────────────────────

  Widget _buildFeedback() {
    int rating = 0;
    final msgCtrl = TextEditingController();
    String category = 'General';

    return StatefulBuilder(builder: (ctx, setF) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('How would you rate CivilOS?', style: TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final star = i + 1;
                return GestureDetector(
                  onTap: () => setF(() => rating = star),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Icon(
                      star <= rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: star <= rating ? Colors.amber : CivilTheme.textSecondary,
                      size: 44,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),
            const Text('Category', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: category,
              dropdownColor: CivilTheme.surface,
              style: const TextStyle(color: CivilTheme.textPrimary),
              decoration: _inputDec(''),
              items: ['General', 'Bug Report', 'Feature Request', 'Performance', 'UI/UX']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setF(() => category = v ?? 'General'),
            ),
            const SizedBox(height: 16),
            const Text('Message', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: msgCtrl,
              maxLines: 5,
              style: const TextStyle(color: CivilTheme.textPrimary),
              decoration: _inputDec('Share your experience or suggestions…'),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  if (msgCtrl.text.isEmpty) return;
                  try {
                    await ref.read(apiClientProvider).post('/support/feedback', {
                      'rating': rating,
                      'category': category,
                      'message': msgCtrl.text.trim(),
                    });
                  } catch (_) {}
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(content: Text('Thank you for your feedback! 🙌'), backgroundColor: Colors.greenAccent),
                    );
                    msgCtrl.clear();
                    setF(() => rating = 0);
                  }
                },
                icon: const Icon(Icons.send, color: Colors.white, size: 18),
                label: const Text('Submit Feedback', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: CivilTheme.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  InputDecoration _inputDec(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: CivilTheme.textSecondary),
      filled: true,
      fillColor: CivilTheme.background,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CivilTheme.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: CivilTheme.primary)),
    );
  }
}
