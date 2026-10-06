import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';

class FeatureGate extends ConsumerWidget {
  final String featureKey;
  final Widget child;
  final Widget? fallback;

  const FeatureGate({
    super.key,
    required this.featureKey,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    if (authState.isFeatureEnabled(featureKey)) return child;

    return fallback ?? Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.lock_outline, color: CivilTheme.textSecondary, size: 48),
        const SizedBox(height: 12),
        Text('Feature not available',
            style: TextStyle(color: CivilTheme.textSecondary)),
      ],
    );
  }
}

class RoleGate extends ConsumerWidget {
  final List<String> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleGate({
    super.key,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final role = auth.currentUser?['role'] as String?;
    if (role != null && allowedRoles.contains(role)) return child;
    if (auth.isSuperAdmin) return child;

    return fallback ?? const SizedBox.shrink();
  }
}

class PermissionGate extends ConsumerWidget {
  final String permission;
  final Widget child;
  final Widget? fallback;

  const PermissionGate({
    super.key,
    required this.permission,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final role = auth.currentUser?['role'] as String?;

    if (auth.isSuperAdmin) return child;

    const rolePermissions = <String, List<String>>{
      'ContractorOwner': [
        'projects.read', 'projects.write', 'projects.delete',
        'diaries.read', 'diaries.write', 'diaries.approve',
        'work_orders.read', 'work_orders.write', 'work_orders.delete',
        'expenses.read', 'expenses.write', 'expenses.delete',
      ],
      'ProjectManager': [
        'projects.read', 'projects.write',
        'diaries.read', 'diaries.write', 'diaries.approve',
        'work_orders.read', 'work_orders.write',
        'expenses.read', 'expenses.write',
      ],
      'SiteEngineer': [
        'projects.read',
        'diaries.read', 'diaries.write',
        'work_orders.read',
        'expenses.read', 'expenses.write',
      ],
    };

    final perms = rolePermissions[role] ?? [];
    if (perms.contains(permission)) return child;

    return fallback ?? const SizedBox.shrink();
  }
}
