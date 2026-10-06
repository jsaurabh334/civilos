import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'admin_shell.dart';
import 'admin_providers.dart';

class AdminVendorsScreen extends ConsumerWidget {
  const AdminVendorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorsAsync = ref.watch(adminVendorsProvider);

    return AdminShell(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Vendor Oversight', style: Theme.of(context).textTheme.headlineMedium),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.read(adminVendorsProvider.notifier).fetchVendors(),
                )
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: vendorsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (vendors) {
                  if (vendors.isEmpty) return const Center(child: Text('No vendors found.'));

                  return Card(
                    elevation: 4,
                    child: ListView.separated(
                      itemCount: vendors.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final vendor = vendors[index];
                        return ListTile(
                          leading: CircleAvatar(child: Text(vendor.name.substring(0, 1).toUpperCase())),
                          title: Text(vendor.name),
                          subtitle: Text(vendor.email),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildStatusChip(vendor.verificationStatus),
                              const SizedBox(width: 16),
                              PopupMenuButton<String>(
                                onSelected: (status) {
                                  ref.read(adminVendorsProvider.notifier).updateVendorStatus(vendor.id, status);
                                },
                                itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                  const PopupMenuItem<String>(value: 'Verified', child: Text('Verify')),
                                  const PopupMenuItem<String>(value: 'Pending', child: Text('Mark Pending')),
                                  const PopupMenuItem<String>(value: 'Suspended', child: Text('Suspend')),
                                  const PopupMenuItem<String>(value: 'Blacklisted', child: Text('Blacklist (Danger)', style: TextStyle(color: Colors.red))),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status) {
      case 'Verified': color = Colors.green; break;
      case 'Pending': color = Colors.orange; break;
      case 'Suspended': color = Colors.brown; break;
      case 'Blacklisted': color = Colors.red; break;
      default: color = Colors.grey;
    }
    return Chip(
      label: Text(status, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }
}
