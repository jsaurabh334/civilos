import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/widgets/civil_scaffold.dart';
import '../../core/theme.dart';
import '../../core/providers/partner_provider.dart';
import '../../core/empty_state.dart';

class VendorsScreen extends ConsumerStatefulWidget {
  const VendorsScreen({super.key});

  @override
  ConsumerState<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends ConsumerState<VendorsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(partnerProvider.notifier).fetchPartners(type: 'Vendor'));
  }

  @override
  Widget build(BuildContext context) {
    final partnerState = ref.watch(partnerProvider);

    return CivilScaffold(
      title: 'Vendors / Contractors',
      body: partnerState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : partnerState.partners.isEmpty
              ? EmptyState(
                  icon: Icons.store,
                  title: 'No Vendors Found',
                  subtitle: 'Start by onboarding your first vendor or contractor.',
                  actionLabel: 'Add Vendor',
                  onAction: () {},
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: partnerState.partners.length,
                  itemBuilder: (context, index) {
                    final vendor = partnerState.partners[index];
                    return Card(
                      color: CivilTheme.surface,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        side: const BorderSide(color: CivilTheme.border),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: CivilTheme.primary.withValues(alpha: 0.2),
                          child: const Icon(Icons.store, color: CivilTheme.primary),
                        ),
                        title: Text(vendor['name'] ?? 'Unknown', style: const TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold)),
                        subtitle: Text(vendor['services'] ?? 'No services listed', style: const TextStyle(color: CivilTheme.textSecondary)),
                        trailing: const Icon(Icons.chevron_right, color: CivilTheme.textSecondary),
                      ),
                    );
                  },
                ),
    );
  }
}
