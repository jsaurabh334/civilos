import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _tokenCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _tokenSent = false;
  String? _error;
  String? _success;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _tokenCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    if (_emailCtrl.text.trim().isEmpty) {
      setState(() => _error = 'Please enter your email address');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(apiClientProvider).post('/auth/forgot-password', {
        'email': _emailCtrl.text.trim().toLowerCase(),
      });
      setState(() {
        _isLoading = false;
        _tokenSent = true;
        _success = 'A reset link has been sent to ${_emailCtrl.text.trim()}';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  Future<void> _resetPassword() async {
    if (!_formKey.currentState!.validate()) return;
    if (_newPassCtrl.text != _confirmPassCtrl.text) {
      setState(() => _error = 'Passwords do not match');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(apiClientProvider).post('/auth/reset-password', {
        'token': _tokenCtrl.text.trim(),
        'new_password': _newPassCtrl.text,
      });
      setState(() { _isLoading = false; _success = 'Password reset! You can now log in.'; });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CivilTheme.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF0D1117), Color(0xFF161B22), Color(0xFF1A2332)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back_ios, color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.lock_reset, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _tokenSent ? 'Reset Your Password' : 'Forgot Password?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _tokenSent
                            ? 'Enter the token from your email along with your new password.'
                            : 'Enter your registered email and we\'ll send you a reset link.',
                        style: const TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 32),

                      // Error/Success Banner
                      if (_error != null)
                        _buildBanner(_error!, isError: true),
                      if (_success != null)
                        _buildBanner(_success!, isError: false),

                      const SizedBox(height: 8),

                      // Step 1: Email
                      if (!_tokenSent) ...[
                        _buildLabel('Email Address'),
                        const SizedBox(height: 8),
                        _buildTextField(
                          controller: _emailCtrl,
                          hint: 'you@company.com',
                          icon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 24),
                        _buildPrimaryButton(
                          label: 'Send Reset Link',
                          icon: Icons.send_outlined,
                          onTap: _isLoading ? null : _sendReset,
                          isLoading: _isLoading,
                        ),
                        const SizedBox(height: 24),
                        Center(
                          child: TextButton(
                            onPressed: () => setState(() { _tokenSent = true; }),
                            child: const Text(
                              'Already have a token? Enter it here →',
                              style: TextStyle(color: Color(0xFF667EEA), fontSize: 13),
                            ),
                          ),
                        ),
                      ],

                      // Step 2: Reset form
                      if (_tokenSent) ...[
                        Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Reset Token'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _tokenCtrl,
                                hint: 'Paste your reset token',
                                icon: Icons.vpn_key_outlined,
                                validator: (v) => (v == null || v.isEmpty) ? 'Token is required' : null,
                              ),
                              const SizedBox(height: 20),
                              _buildLabel('New Password'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _newPassCtrl,
                                hint: 'Min 8 chars, upper, digit, symbol',
                                icon: Icons.lock_outline,
                                obscure: _obscureNew,
                                toggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                                validator: (v) {
                                  if (v == null || v.length < 8) return 'Minimum 8 characters';
                                  if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Needs uppercase letter';
                                  if (!RegExp(r'[0-9]').hasMatch(v)) return 'Needs a number';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 20),
                              _buildLabel('Confirm Password'),
                              const SizedBox(height: 8),
                              _buildTextField(
                                controller: _confirmPassCtrl,
                                hint: 'Re-enter new password',
                                icon: Icons.lock_outline,
                                obscure: _obscureConfirm,
                                toggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                                validator: (v) => (v != _newPassCtrl.text) ? 'Passwords must match' : null,
                              ),
                              const SizedBox(height: 28),
                              _buildPrimaryButton(
                                label: 'Reset Password',
                                icon: Icons.check_circle_outline,
                                onTap: _isLoading ? null : _resetPassword,
                                isLoading: _isLoading,
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: TextButton(
                                  onPressed: () => setState(() { _tokenSent = false; _success = null; _error = null; }),
                                  child: const Text(
                                    '← Back to send reset link',
                                    style: TextStyle(color: Colors.white54, fontSize: 13),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    VoidCallback? toggleObscure,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIcon: Icon(icon, color: Colors.white38, size: 20),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: Colors.white38, size: 20),
                onPressed: toggleObscure,
              )
            : null,
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF667EEA)),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required bool isLoading,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: const Color(0xFF667EEA).withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Icon(icon, color: Colors.white, size: 18),
          label: Text(isLoading ? 'Please wait…' : label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
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
          Expanded(
            child: Text(msg, style: TextStyle(color: isError ? Colors.redAccent : Colors.greenAccent, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
