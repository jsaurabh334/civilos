import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme.dart';
import '../../../core/responsive.dart';
import '../../../core/providers/dashboard_provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';


class DashboardKPIs extends ConsumerWidget {
  const DashboardKPIs({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);
    final stats = dashboardState.stats ?? {};
    final isMobile = Responsive.isMobile(context);

    final outstandingPayments = stats['outstanding_payments'] ?? stats['total_outstanding'] ?? 0;
    final vendorPaymentsDue = stats['vendor_payments_due'] ?? 0;
    final runningProjects = stats['active_projects'] ?? stats['running_projects'] ?? 0;
    final todaysLabour = stats['workers_present_today'] ?? stats['todays_labour'] ?? 0;

    final kpis = [
      {
        'title': 'Outstanding Payments',
        'value': _fmtMoney(outstandingPayments),
        'icon': FontAwesomeIcons.fileInvoiceDollar,
        'color': CivilTheme.primary,
      },
      {
        'title': 'Vendor Payments Due',
        'value': _fmtMoney(vendorPaymentsDue),
        'icon': FontAwesomeIcons.moneyBillTransfer,
        'color': CivilTheme.warning,
      },
      {
        'title': 'Running Projects',
        'value': '$runningProjects',
        'icon': FontAwesomeIcons.building,
        'color': CivilTheme.secondary,
      },
      {
        'title': 'Today\'s Labour',
        'value': '$todaysLabour',
        'icon': FontAwesomeIcons.helmetSafety,
        'color': const Color(0xFF8B5CF6),
      },
    ];

    if (isMobile) {
      return Column(
        children: kpis.map((kpi) => Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: _buildKPICard(context, kpi),
        )).toList(),
      );
    }

    return Row(
      children: kpis.map((kpi) => Expanded(
        child: Padding(
          padding: EdgeInsets.only(right: kpi == kpis.last ? 0 : 16.0),
          child: _buildKPICard(context, kpi),
        ),
      )).toList(),
    );
  }

  Widget _buildKPICard(BuildContext context, Map<String, dynamic> kpi) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: CivilTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CivilTheme.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (kpi['color'] as Color).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: FaIcon(
              kpi['icon'],
              color: kpi['color'] as Color,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kpi['title'] as String,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  kpi['value'] as String,
                  style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 36,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtMoney(dynamic value) {
    final num v = (value ?? 0) as num;
    if (v >= 10000000) return '${(v / 10000000).toStringAsFixed(1)} Cr';
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)} L';
    return v.toStringAsFixed(0);
  }
}
