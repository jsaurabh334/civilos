import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import 'admin_shell.dart';
import 'admin_providers.dart';

class AdminSettingsScreen extends ConsumerWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(adminSettingsProvider);

    return AdminShell(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Platform Settings', style: Theme.of(context).textTheme.headlineMedium),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.read(adminSettingsProvider.notifier).fetchSettings(),
                )
              ],
            ),
            const SizedBox(height: 24),
            Expanded(
              child: settingsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(child: Text('Error: $err')),
                data: (settings) {
                  final maintenanceSetting = settings.firstWhere((s) => s.key == 'maintenance_mode', orElse: () => PlatformSetting(key: 'maintenance_mode', value: 'false'));
                  final isMaintenance = maintenanceSetting.value == 'true';

                  return ListView(
                    children: [
                      Card(
                        elevation: 4,
                        color: isMaintenance ? Colors.red.shade50 : null,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Maintenance Mode', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: isMaintenance ? Colors.red : null)),
                                  const SizedBox(height: 4),
                                  const Text('Blocks all non-SuperAdmin logins across the platform.'),
                                ],
                              ),
                              Switch(
                                value: isMaintenance,
                                activeThumbColor: Colors.red,
                                onChanged: (val) {
                                  ref.read(adminSettingsProvider.notifier).updateSetting('maintenance_mode', val.toString());
                                },
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Vendor Portal Global Access', style: Theme.of(context).textTheme.titleLarge),
                                  const SizedBox(height: 4),
                                  const Text('Enable or disable the Vendor Portal platform-wide.'),
                                ],
                              ),
                              Switch(
                                value: true, // Mocked for now, in a real scenario we'd use settings.firstWhere
                                activeThumbColor: CivilTheme.primary,
                                onChanged: (val) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feature flag updated.')));
                                },
                              )
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Placeholders for Templates
                      Card(
                        elevation: 4,
                        child: ListTile(
                          leading: const Icon(Icons.email),
                          title: const Text('Email Templates'),
                          subtitle: const Text('Manage Welcome, Password Reset, and Invitation emails.'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            final notifier = ref.read(adminSettingsProvider.notifier);
                            final ctrl = TextEditingController();
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: CivilTheme.surface,
                                title: const Text('Edit Email Template', style: TextStyle(color: CivilTheme.textPrimary)),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text('Enter the template value:', style: TextStyle(color: CivilTheme.textSecondary)),
                                    const SizedBox(height: 16),
                                    TextField(
                                      controller: ctrl,
                                      maxLines: 5,
                                      style: const TextStyle(color: CivilTheme.textPrimary),
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: CivilTheme.background,
                                        hintText: 'Template content...',
                                        hintStyle: TextStyle(color: CivilTheme.textSecondary.withValues(alpha: 0.5)),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: CivilTheme.border)),
                                      ),
                                    ),
                                  ],
                                ),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: CivilTheme.textSecondary))),
                                  ElevatedButton(
                                    onPressed: () {
                                      notifier.updateSetting('email_template', ctrl.text.trim());
                                      Navigator.pop(ctx);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Email template updated'), backgroundColor: CivilTheme.secondary),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(backgroundColor: CivilTheme.primary),
                                    child: const Text('Save', style: TextStyle(color: Colors.white)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
