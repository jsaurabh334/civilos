import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_provider.dart';

class AdminShell extends ConsumerWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('CivilOS Super Admin'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.admin_panel_settings, color: Colors.white, size: 48),
                  SizedBox(height: 16),
                  Text('Platform Owner', style: TextStyle(color: Colors.white, fontSize: 20)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Analytics Dashboard'),
              onTap: () {
                Navigator.pop(context); // close drawer
                context.go('/admin');
              },
            ),
            ListTile(
              leading: const Icon(Icons.verified_user),
              title: const Text('Vendor Oversight'),
              onTap: () {
                Navigator.pop(context);
                context.go('/admin/vendors');
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Platform Settings'),
              onTap: () {
                Navigator.pop(context);
                context.go('/admin/settings');
              },
            ),
          ],
        ),
      ),
      body: child,
    );
  }
}
