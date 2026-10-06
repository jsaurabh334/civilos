import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/auth_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/theme.dart';
import '../../core/confirm_dialog.dart';
import '../../core/loading_overlay.dart';
import '../auth/login_screen.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    )..forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedSection({required int index, required Widget child}) {
    final delay = index * 0.12;
    return FadeTransition(
      opacity: Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
            parent: _animController,
            curve: Interval(delay, (delay + 0.35).clamp(0, 1),
                curve: Curves.easeOut)),
      ),
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
            .animate(
          CurvedAnimation(
              parent: _animController,
              curve: Interval(delay, (delay + 0.35).clamp(0, 1),
                  curve: Curves.easeOutCubic)),
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.currentUser;
    final name = user?['name']?.toString() ?? '';
    final email = user?['email']?.toString() ?? '';
    final role = user?['role']?.toString() ?? '';

    return Scaffold(
      backgroundColor: CivilTheme.background,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 900;
          return Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF222B38), Color(0xFF161F2E)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: isMobile ? 600 : 800),
                  child: Column(
                    children: [
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                    color: CivilTheme.surface.withValues(alpha: 0.5),
                                    borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.settings,
                                    color: CivilTheme.textSecondary, size: 24),
                              ),
                              const SizedBox(width: 16),
                              const Text('Settings',
                                  style: TextStyle(
                                      color: CivilTheme.textPrimary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildAnimatedSection(
                                  index: 0,
                                  child: _buildProfileSection(
                                      context, name, email, role)),
                              const SizedBox(height: 24),
                              _buildAnimatedSection(
                                  index: 1,
                                  child: _buildSecuritySection(context)),
                              const SizedBox(height: 24),
                              _buildAnimatedSection(
                                  index: 2,
                                  child: _buildAccountSection(context)),
                              const SizedBox(height: 24),
                              _buildAnimatedSection(
                                  index: 3, child: _buildAboutSection()),
                              const SizedBox(height: 24),
                              _buildAnimatedSection(
                                  index: 4, child: _buildQuickLinksSection(context)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGlassCard({required String title, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: CivilTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10)
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: CivilTheme.textPrimary)),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildProfileSection(
      BuildContext context, String name, String email, String role) {
    return _buildGlassCard(
      title: 'Profile',
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5)),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 28,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: CivilTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text(email,
                        style:
                            const TextStyle(color: CivilTheme.textSecondary)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.blueAccent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(role.toUpperCase(),
                          style: const TextStyle(
                              color: Colors.blueAccent,
                              fontSize: 10,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _showEditProfileDialog(context),
              icon: const Icon(Icons.edit, size: 18),
              label: const Text('Edit Profile'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blueAccent,
                side: BorderSide(color: Colors.blueAccent.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecuritySection(BuildContext context) {
    return _buildGlassCard(
      title: 'Security',
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showChangePasswordDialog(context),
          icon: const Icon(Icons.lock_outline, size: 18, color: Colors.white),
          label: const Text('Change Password',
              style: TextStyle(color: Colors.white)),
          style: ElevatedButton.styleFrom(
            backgroundColor: CivilTheme.primary,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountSection(BuildContext context) {
    return _buildGlassCard(
      title: 'Account',
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () async {
            final confirm = await showConfirmDialog(
              context,
              title: 'Logout',
              message: 'Are you sure you want to log out?',
              confirmLabel: 'Logout',
              confirmColor: Colors.redAccent,
            );
            if (confirm) {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            }
          },
          icon: const Icon(Icons.logout, size: 18, color: Colors.redAccent),
          label:
              const Text('Logout', style: TextStyle(color: Colors.redAccent)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return _buildGlassCard(
      title: 'About',
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.info_outline,
                    color: CivilTheme.textPrimary, size: 24),
              ),
              const SizedBox(width: 16),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CivilOS',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: CivilTheme.textPrimary)),
                  SizedBox(height: 4),
                  Text('Version 1.0.0 (Build 2024.1)',
                      style: TextStyle(
                          fontSize: 13, color: CivilTheme.textSecondary)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(color: CivilTheme.border, height: 1),
          const SizedBox(height: 20),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.dark_mode, color: Colors.amber, size: 16),
              SizedBox(width: 8),
              Text('Dark Theme Active',
                  style:
                      TextStyle(fontSize: 13, color: CivilTheme.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLinksSection(BuildContext context) {
    return _buildGlassCard(
      title: 'Quick Links',
      child: Column(
        children: [
          _buildQuickLink(
            icon: Icons.search,
            color: CivilTheme.primary,
            label: 'Global Search',
            subtitle: 'Search across all modules',
            onTap: () => context.push('/search'),
          ),
          const Divider(color: CivilTheme.border, height: 1),
          _buildQuickLink(
            icon: Icons.history,
            color: Colors.tealAccent,
            label: 'Activity Log',
            subtitle: 'Your recent actions',
            onTap: () => context.push('/activity-log'),
          ),
          const Divider(color: CivilTheme.border, height: 1),
          _buildQuickLink(
            icon: Icons.trending_up,
            color: Colors.orangeAccent,
            label: 'Material Price History',
            subtitle: 'Track 12-month material costs',
            onTap: () => context.push('/material-price-history'),
          ),
          const Divider(color: CivilTheme.border, height: 1),
          _buildQuickLink(
            icon: Icons.help_outline,
            color: Colors.purpleAccent,
            label: 'Help & Support',
            subtitle: 'Help center, tickets, feedback',
            onTap: () => context.push('/support'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLink({
    required IconData icon,
    required Color color,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label, style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 12)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: CivilTheme.textSecondary),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final auth = ref.read(authProvider);
    final nameController = TextEditingController(
        text: auth.currentUser?['name']?.toString() ?? '');
    final phoneController = TextEditingController(
        text: auth.currentUser?['phone']?.toString() ?? '');
    var isLoading = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return LoadingOverlay(
              isLoading: isLoading,
              child: AlertDialog(
                backgroundColor: CivilTheme.surface,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text('Edit Profile',
                    style: TextStyle(color: CivilTheme.textPrimary)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      style: const TextStyle(color: CivilTheme.textPrimary),
                      decoration: const InputDecoration(
                          labelText: 'Name',
                          labelStyle:
                              TextStyle(color: CivilTheme.textSecondary)),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: phoneController,
                      style: const TextStyle(color: CivilTheme.textPrimary),
                      decoration: const InputDecoration(
                          labelText: 'Phone',
                          labelStyle:
                              TextStyle(color: CivilTheme.textSecondary)),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: CivilTheme.textSecondary)),
                  ),
                  ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () async {
                            setDialogState(() => isLoading = true);
                            try {
                              await ref
                                  .read(profileProvider.notifier)
                                  .updateProfile(nameController.text.trim(),
                                      phoneController.text.trim());
                              if (context.mounted) {
                                Navigator.pop(context);
                                showToast(
                                    context, 'Profile updated successfully');
                              }
                            } catch (e) {
                              if (context.mounted) {
                                setDialogState(() => isLoading = false);
                                showToast(context, 'Failed: $e', isError: true);
                              }
                            }
                          },
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: CivilTheme.surface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Change Password',
              style: TextStyle(color: CivilTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                style: const TextStyle(color: CivilTheme.textPrimary),
                decoration: const InputDecoration(
                    labelText: 'Current Password',
                    labelStyle: TextStyle(color: CivilTheme.textSecondary)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newController,
                obscureText: true,
                style: const TextStyle(color: CivilTheme.textPrimary),
                decoration: const InputDecoration(
                    labelText: 'New Password',
                    labelStyle: TextStyle(color: CivilTheme.textSecondary)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                obscureText: true,
                style: const TextStyle(color: CivilTheme.textPrimary),
                decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    labelStyle: TextStyle(color: CivilTheme.textSecondary)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: CivilTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newController.text != confirmController.text) {
                  showToast(context, 'Passwords do not match', isError: true);
                  return;
                }
                if (newController.text.length < 6) {
                  showToast(context, 'Password must be at least 6 characters',
                      isError: true);
                  return;
                }
                try {
                  await ref.read(profileProvider.notifier).changePassword(
                      currentController.text, newController.text);
                  if (context.mounted) {
                    Navigator.pop(context);
                    showToast(context, 'Password changed successfully');
                  }
                } catch (e) {
                  if (context.mounted) {
                    showToast(context, 'Failed: $e', isError: true);
                  }
                }
              },
              child: const Text('Change Password'),
            ),
          ],
        );
      },
    );
  }
}
