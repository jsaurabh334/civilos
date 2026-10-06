import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme.dart';
import '../../core/auth_provider.dart';

class TenantDetailsScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> tenant;

  const TenantDetailsScreen({super.key, required this.tenant});

  @override
  ConsumerState<TenantDetailsScreen> createState() => _TenantDetailsScreenState();
}

class _TenantDetailsScreenState extends ConsumerState<TenantDetailsScreen> {
  bool _isLoadingCheckout = false;

  Future<void> _upgradeToPro() async {
    setState(() => _isLoadingCheckout = true);
    try {
      final tId = widget.tenant['id'];
      final response = await ref.read(apiClientProvider).post('/admin/tenants/$tId/checkout', {
        'amount': 29900, // 299.00 USD/INR in cents/paise
        'currency': 'USD',
        'description': 'Upgrade to Pro Plan',
      });
      
      if (response != null && response['short_url'] != null) {
        final url = Uri.parse(response['short_url']);
        if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
          throw Exception('Could not launch $url');
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to generate checkout link: $e')));
    } finally {
      setState(() => _isLoadingCheckout = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.tenant;
    
    return Scaffold(
      backgroundColor: CivilTheme.background,
      appBar: AppBar(
        backgroundColor: CivilTheme.surface,
        iconTheme: const IconThemeData(color: CivilTheme.textPrimary),
        title: Text(t['name'] ?? 'Tenant Details', style: const TextStyle(color: CivilTheme.textPrimary)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Overview', style: TextStyle(color: CivilTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: CivilTheme.surface, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Domain', style: TextStyle(color: CivilTheme.textSecondary)),
                        const SizedBox(height: 4),
                        Text(t['slug'] ?? 'Unknown', style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: CivilTheme.surface, borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status', style: TextStyle(color: CivilTheme.textSecondary)),
                        const SizedBox(height: 4),
                        Text((t['is_active'] == true) ? 'Active' : 'Suspended', style: TextStyle(color: (t['is_active'] == true) ? Colors.teal : Colors.red, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text('Billing & Plan', style: TextStyle(color: CivilTheme.textPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: CivilTheme.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.purpleAccent.withValues(alpha: 0.3))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Current Plan: BASIC', style: TextStyle(color: CivilTheme.textSecondary, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('This tenant is currently on the free Basic plan.', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 13)),
                    ],
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    ),
                    icon: _isLoadingCheckout ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.payment),
                    label: Text(_isLoadingCheckout ? 'Generating Link...' : 'Upgrade to PRO via Razorpay'),
                    onPressed: _isLoadingCheckout ? null : _upgradeToPro,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
