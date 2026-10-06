import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/auth_provider.dart';
import '../../core/providers/user_provider.dart';
import '../../core/theme.dart';
import '../../core/confirm_dialog.dart';
import '../../core/empty_state.dart';

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() =>
      _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(userProvider.notifier).fetchUsers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _filteredUsers(List<dynamic> users) {
    if (_searchQuery.isEmpty) return users.cast<Map<String, dynamic>>();
    return users
        .where((u) {
          final user = u as Map<String, dynamic>;
          final query = _searchQuery.toLowerCase();
          return (user['name']?.toString().toLowerCase().contains(query) ??
                  false) ||
              (user['email']?.toString().toLowerCase().contains(query) ??
                  false);
        })
        .cast<Map<String, dynamic>>()
        .toList();
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'SuperAdmin':
        return Colors.redAccent;
      case 'ContractorOwner':
        return Colors.blueAccent;
      case 'ProjectManager':
        return Colors.greenAccent;
      case 'SiteEngineer':
        return Colors.amber;
      default:
        return CivilTheme.textSecondary;
    }
  }

  void _showInviteDialog() {
    showDialog(
        context: context, builder: (context) => const _InviteUserDialog());
  }

  void _editUser(Map<String, dynamic> user) {
    showDialog(
        context: context, builder: (context) => _EditUserDialog(user: user));
  }

  Future<void> _deleteUser(Map<String, dynamic> user) async {
    final currentUserId = ref.read(authProvider).currentUser?['id'];
    if (user['id'] == currentUserId) {
      showToast(context, 'Cannot delete your own account', isError: true);
      return;
    }
    final confirm = await showConfirmDialog(
      context,
      title: 'Delete User',
      message:
          'Delete ${user['name'] ?? 'this user'}? This action cannot be undone.',
    );
    if (!confirm) return;

    try {
      await ref.read(userProvider.notifier).deleteUser(user['id'] as int);
      if (mounted) showToast(context, 'User deleted successfully');
    } catch (e) {
      if (mounted) showToast(context, 'Failed to delete: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProv = ref.watch(userProvider);
    final users = _filteredUsers(userProv.users);

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
                  constraints: BoxConstraints(maxWidth: isMobile ? 600 : 1000),
                  child: Column(
                    children: [
                      SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                        color:
                                            CivilTheme.surface.withValues(alpha: 0.5),
                                        borderRadius:
                                            BorderRadius.circular(12)),
                                    child: const Icon(Icons.people,
                                        color: CivilTheme.textSecondary,
                                        size: 20),
                                  ),
                                  const Spacer(),
                                  const Text('Team Management',
                                      style: TextStyle(
                                          color: CivilTheme.textPrimary,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold)),
                                  const Spacer(),
                                  ElevatedButton.icon(
                                    onPressed: _showInviteDialog,
                                    icon: const Icon(Icons.person_add,
                                        color: CivilTheme.background, size: 18),
                                    label: const Text('Invite',
                                        style: TextStyle(
                                            color: CivilTheme.background)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: CivilTheme.primary,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Container(
                                height: 48,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: CivilTheme.surface.withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: CivilTheme.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.search,
                                        color: CivilTheme.textSecondary,
                                        size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextField(
                                        controller: _searchController,
                                        style: const TextStyle(
                                            color: CivilTheme.textPrimary,
                                            fontSize: 14),
                                        decoration: const InputDecoration(
                                          hintText: 'Search team members...',
                                          hintStyle: TextStyle(
                                              color: CivilTheme.textSecondary),
                                          border: InputBorder.none,
                                          isDense: true,
                                        ),
                                        onChanged: (v) =>
                                            setState(() => _searchQuery = v),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: userProv.isLoading && userProv.users.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : userProv.users.isEmpty
                                ? EmptyState(
                                    icon: Icons.group,
                                    title: 'No team members',
                                    actionLabel: 'Invite User',
                                    onAction: _showInviteDialog,
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.all(20),
                                    itemCount: users.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 12),
                                    itemBuilder: (context, index) {
                                      final user = users[index];
                                      return _buildUserCard(user);
                                    },
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

  Widget _buildUserCard(Map<String, dynamic> user) {
    final role = user['role']?.toString() ?? '';
    final roleColor = _roleColor(role);
    final auth = ref.read(authProvider);
    final isCurrentUser = user['id'] == auth.currentUser?['id'];

    return Container(
      decoration: BoxDecoration(
        color: CivilTheme.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: roleColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
              color: roleColor.withValues(alpha: 0.05),
              blurRadius: 20,
              spreadRadius: -5)
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: roleColor.withValues(alpha: 0.3)),
            ),
            child: Center(
              child: Text(
                (user['name']?.toString() ?? '?')[0].toUpperCase(),
                style: TextStyle(
                    color: roleColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user['name']?.toString() ?? 'Unknown',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: CivilTheme.textPrimary),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: CivilTheme.primary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('YOU',
                            style: TextStyle(
                                color: CivilTheme.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(user['email']?.toString() ?? '',
                    style: const TextStyle(
                        color: CivilTheme.textSecondary, fontSize: 13)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: roleColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: roleColor),
                ),
                child: Text(
                  role,
                  style: TextStyle(
                      color: roleColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
              if (!isCurrentUser) ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined,
                          color: Colors.blueAccent, size: 18),
                      onPressed: () => _editUser(user),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent, size: 18),
                      onPressed: () => _deleteUser(user),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _EditUserDialog extends ConsumerStatefulWidget {
  final Map<String, dynamic> user;
  const _EditUserDialog({required this.user});
  @override
  ConsumerState<_EditUserDialog> createState() => _EditUserDialogState();
}

class _EditUserDialogState extends ConsumerState<_EditUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  late String _role;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.user['name']?.toString() ?? '';
    _phoneController.text = widget.user['phone']?.toString() ?? '';
    _role = widget.user['role']?.toString() ?? 'ProjectManager';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      final data = {
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'role': _role
      };
      await ref
          .read(userProvider.notifier)
          .updateUser(widget.user['id'] as int, data);
      if (mounted) {
        Navigator.pop(context);
        showToast(context, 'User updated successfully');
      }
    } catch (e) {
      if (mounted) showToast(context, 'Failed to update: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CivilTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Edit User',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: CivilTheme.textPrimary)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Name',
                        labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Phone',
                        labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    dropdownColor: CivilTheme.surface,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Role',
                        labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                    items: ['ContractorOwner', 'ProjectManager', 'SiteEngineer']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _role = v ?? 'ProjectManager'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel',
                              style:
                                  TextStyle(color: CivilTheme.textSecondary))),
                      const SizedBox(width: 16),
                      ElevatedButton(
                          onPressed: _submit, child: const Text('Save')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InviteUserDialog extends ConsumerStatefulWidget {
  const _InviteUserDialog();
  @override
  ConsumerState<_InviteUserDialog> createState() => _InviteUserDialogState();
}

class _InviteUserDialogState extends ConsumerState<_InviteUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _role = 'ProjectManager';

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(userProvider.notifier).inviteUser(
          _nameController.text.trim(),
          _emailController.text.trim(),
          _role,
          _passwordController.text);
      if (mounted) {
        Navigator.pop(context);
        showToast(context, 'User invited successfully');
      }
    } catch (e) {
      if (mounted) showToast(context, 'Failed: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: CivilTheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Invite Member',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: CivilTheme.textPrimary)),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Name',
                        labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (!v.contains('@')) return 'Invalid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (v.length < 6) return 'Min 6 characters';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    dropdownColor: CivilTheme.surface,
                    style: const TextStyle(color: CivilTheme.textPrimary),
                    decoration: const InputDecoration(
                        labelText: 'Role',
                        labelStyle: TextStyle(color: CivilTheme.textSecondary)),
                    items: ['ProjectManager', 'SiteEngineer', 'ContractorOwner']
                        .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _role = v ?? 'ProjectManager'),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel',
                              style:
                                  TextStyle(color: CivilTheme.textSecondary))),
                      const SizedBox(width: 16),
                      ElevatedButton(
                          onPressed: _submit, child: const Text('Invite')),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
