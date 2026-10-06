import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/auth_provider.dart';
import '../../core/providers/profile_provider.dart';
import '../../core/theme.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _currentPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;
  bool _isChangingPw = false;
  String? _successMsg;
  String? _errorMsg;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    final user = ref.read(authProvider).currentUser;
    _nameCtrl.text = user?['name']?.toString() ?? '';
    _phoneCtrl.text = user?['phone']?.toString() ?? '';
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _currentPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (_nameCtrl.text.trim().isEmpty) {
      setState(() => _errorMsg = 'Name is required');
      return;
    }
    setState(() { _isSaving = true; _errorMsg = null; _successMsg = null; });
    try {
      await ref.read(profileProvider.notifier).updateProfile(
        _nameCtrl.text.trim(),
        _phoneCtrl.text.trim(),
      );
      setState(() { _isSaving = false; _successMsg = 'Profile updated successfully!'; });
    } catch (e) {
      setState(() { _isSaving = false; _errorMsg = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  Future<void> _changePassword() async {
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      setState(() => _errorMsg = 'Passwords do not match');
      return;
    }
    if (_newPassCtrl.text.length < 8) {
      setState(() => _errorMsg = 'Password must be at least 8 characters');
      return;
    }
    setState(() { _isChangingPw = true; _errorMsg = null; _successMsg = null; });
    try {
      await ref.read(profileProvider.notifier).changePassword(
        _currentPassCtrl.text,
        _newPassCtrl.text,
      );
      _currentPassCtrl.clear();
      _newPassCtrl.clear();
      _confirmPassCtrl.clear();
      setState(() { _isChangingPw = false; _successMsg = 'Password changed successfully!'; });
    } catch (e) {
      setState(() { _isChangingPw = false; _errorMsg = e.toString().replaceAll('Exception: ', ''); });
    }
  }

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    final result = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512);
    if (result == null) return;

    final bytes = await result.readAsBytes();
    final fileName = result.name;

    try {
      final api = ref.read(apiClientProvider);
      final uploadResult = await api.uploadFile('/upload', 'file', bytes, fileName);
      final url = uploadResult['url']?.toString() ?? uploadResult['file_url']?.toString() ?? '';

      if (url.isNotEmpty) {
        final user = ref.read(authProvider).currentUser;
        await ref.read(profileProvider.notifier).updateProfile(
          user?['name']?.toString() ?? '',
          user?['phone']?.toString() ?? '',
          avatarUrl: url,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar updated successfully!'),
            backgroundColor: CivilTheme.secondary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: CivilTheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final user = auth.currentUser;
    final name = user?['name']?.toString() ?? 'User';
    final email = user?['email']?.toString() ?? '';
    final role = user?['role']?.toString() ?? 'Contractor';
    final initials = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Scaffold(
      backgroundColor: CivilTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: CivilTheme.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A237E), Color(0xFF0D47A1), Color(0xFF1565C0)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        GestureDetector(
                          onTap: _pickAvatar,
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 48,
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                backgroundImage: user?['avatar_url'] != null
                                    ? NetworkImage(user!['avatar_url'].toString())
                                    : null,
                                child: user?['avatar_url'] == null
                                    ? Text(initials,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold))
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: CivilTheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(role, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(48),
              child: Container(
                color: CivilTheme.surface,
                child: TabBar(
                  controller: _tabCtrl,
                  indicatorColor: CivilTheme.primary,
                  labelColor: CivilTheme.primary,
                  unselectedLabelColor: CivilTheme.textSecondary,
                  dividerColor: CivilTheme.border,
                  tabs: const [
                    Tab(text: 'Profile'),
                    Tab(text: 'Security'),
                    Tab(text: 'Activity'),
                  ],
                ),
              ),
            ),
          ),
          SliverFillRemaining(
            child: TabBarView(
              controller: _tabCtrl,
              children: [
                _buildProfileTab(email),
                _buildSecurityTab(),
                _buildActivityTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab(String email) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_successMsg != null) _buildBanner(_successMsg!, isError: false),
          if (_errorMsg != null) _buildBanner(_errorMsg!, isError: true),
          _buildSectionCard(
            title: 'Personal Information',
            icon: Icons.person_outline,
            children: [
              _buildField('Full Name', _nameCtrl, Icons.person_outline),
              const SizedBox(height: 16),
              _buildField('Phone Number', _phoneCtrl, Icons.phone_outlined, keyboardType: TextInputType.phone),
              const SizedBox(height: 16),
              _buildReadonlyField('Email Address', email, Icons.email_outlined),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _saveProfile,
              icon: _isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined, color: Colors.white),
              label: Text(_isSaving ? 'Saving…' : 'Save Changes',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: CivilTheme.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _enable2FA() async {
    final user = ref.read(authProvider).currentUser;
    final email = user?['email']?.toString() ?? '';
    if (email.isEmpty) return;

    try {
      await ref.read(apiClientProvider).post('/auth/send-otp', {'email': email});

      if (!mounted) return;
      final otpCtrl = TextEditingController();
      final otp = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: CivilTheme.surface,
          title: const Text('Enable 2FA', style: TextStyle(color: CivilTheme.textPrimary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Enter the OTP sent to your email.', style: TextStyle(color: CivilTheme.textSecondary)),
              const SizedBox(height: 16),
              TextField(
                controller: otpCtrl,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: CivilTheme.textPrimary, fontSize: 24, letterSpacing: 8),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: '000000',
                  hintStyle: TextStyle(color: CivilTheme.textSecondary.withValues(alpha: 0.4)),
                  filled: true,
                  fillColor: CivilTheme.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: CivilTheme.border)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: CivilTheme.textSecondary))),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, otpCtrl.text.trim()),
              style: ElevatedButton.styleFrom(backgroundColor: CivilTheme.primary),
              child: const Text('Verify', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (otp == null || otp.isEmpty) return;

      await ref.read(apiClientProvider).post('/auth/verify-otp', {
        'email': email,
        'otp': otp,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('2FA enabled successfully!'), backgroundColor: CivilTheme.secondary),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('2FA setup failed: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: CivilTheme.error),
        );
      }
    }
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_successMsg != null) _buildBanner(_successMsg!, isError: false),
          if (_errorMsg != null) _buildBanner(_errorMsg!, isError: true),
          _buildSectionCard(
            title: 'Change Password',
            icon: Icons.lock_outline,
            children: [
              _buildPasswordField('Current Password', _currentPassCtrl, _obscureCurrent,
                  () => setState(() => _obscureCurrent = !_obscureCurrent)),
              const SizedBox(height: 16),
              _buildPasswordField('New Password', _newPassCtrl, _obscureNew,
                  () => setState(() => _obscureNew = !_obscureNew)),
              const SizedBox(height: 16),
              _buildPasswordField('Confirm New Password', _confirmPassCtrl, _obscureConfirm,
                  () => setState(() => _obscureConfirm = !_obscureConfirm)),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _isChangingPw ? null : _changePassword,
              icon: _isChangingPw
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.lock_reset, color: Colors.white),
              label: Text(_isChangingPw ? 'Updating…' : 'Update Password',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildSectionCard(
            title: 'Two-Factor Authentication',
            icon: Icons.security_outlined,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Authenticator App (TOTP)', style: TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Use Google Authenticator or Authy for secure 2FA', style: TextStyle(color: CivilTheme.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ),
                  Switch(
                    value: false,
                    onChanged: (_) => _enable2FA(),
                    activeColor: CivilTheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: CivilTheme.textSecondary),
          SizedBox(height: 16),
          Text('Activity log is in the Activity Log section', style: TextStyle(color: CivilTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: CivilTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: CivilTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: CivilTheme.primary, size: 20),
              const SizedBox(width: 10),
              Text(title, style: const TextStyle(color: CivilTheme.textPrimary, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon,
      {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          style: const TextStyle(color: CivilTheme.textPrimary),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: CivilTheme.textSecondary, size: 18),
            filled: true,
            fillColor: CivilTheme.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CivilTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CivilTheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField(String label, TextEditingController ctrl, bool obscure, VoidCallback toggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: obscure,
          style: const TextStyle(color: CivilTheme.textPrimary),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outline, color: CivilTheme.textSecondary, size: 18),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: CivilTheme.textSecondary, size: 18),
              onPressed: toggle,
            ),
            filled: true,
            fillColor: CivilTheme.background,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CivilTheme.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: CivilTheme.primary),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReadonlyField(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: CivilTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: CivilTheme.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: CivilTheme.border),
          ),
          child: Row(
            children: [
              Icon(icon, color: CivilTheme.textSecondary, size: 18),
              const SizedBox(width: 8),
              Text(value, style: const TextStyle(color: CivilTheme.textSecondary)),
              const Spacer(),
              const Icon(Icons.lock_outline, color: CivilTheme.textSecondary, size: 14),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBanner(String msg, {required bool isError}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isError
            ? Colors.redAccent.withValues(alpha: 0.12)
            : Colors.greenAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isError ? Colors.redAccent.withValues(alpha: 0.4) : Colors.greenAccent.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
              color: isError ? Colors.redAccent : Colors.greenAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: TextStyle(color: isError ? Colors.redAccent : Colors.greenAccent, fontSize: 13))),
        ],
      ),
    );
  }
}
