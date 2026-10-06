import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_provider.dart';

class VendorDashboardScreen extends ConsumerWidget {
  const VendorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(context),
            const SizedBox(height: 24),
            _buildMetricsRow(context),
            const SizedBox(height: 24),
            Text('Quick Actions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildQuickActions(context),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade800, Colors.blue.shade500]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.store, size: 48, color: Colors.white),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Welcome to CivilOS Vendor Portal', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                Text('Manage your catalog, fulfill orders, and track invoices seamlessly.', style: TextStyle(color: Colors.white70)),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMetricsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildMetricCard(context, 'New Orders', '3', Icons.shopping_cart, Colors.orange)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard(context, 'In Transit', '5', Icons.local_shipping, Colors.blue)),
        const SizedBox(width: 12),
        Expanded(child: _buildMetricCard(context, 'Unpaid Bills', '12', Icons.receipt_long, Colors.red)),
      ],
    );
  }

  Widget _buildMetricCard(BuildContext context, String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 2.5,
      children: [
        _buildActionBtn(context, 'Purchase Orders', Icons.assignment, '/vendor/orders'),
        _buildActionBtn(context, 'Invoicing', Icons.request_quote, '/vendor/invoicing'),
        _buildActionBtn(context, 'Product Catalog', Icons.inventory_2, '/vendor/products'),
        _buildActionBtn(context, 'Company Profile', Icons.business, '/vendor/profile'),
      ],
    );
  }

  Widget _buildActionBtn(BuildContext context, String label, IconData icon, String route) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      onPressed: () => context.push(route),
      style: ElevatedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
