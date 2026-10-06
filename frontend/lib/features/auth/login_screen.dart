import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';
import '../../core/auth_provider.dart';
import '../../core/api_client.dart';
import '../../core/theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _totpController = TextEditingController();

  String? _errorMessage;
  bool _requires2FA = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _ssoLogin(String provider) async {
    final emailCtrl = TextEditingController();
    final email = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('SSO Login ($provider)', style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Enter your email',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.2),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, emailCtrl.text.trim()),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlueAccent),
            child: const Text('Sign In', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (email == null || email.isEmpty) return;

    try {
      await ref.read(authProvider.notifier).ssoLogin(provider, email);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('SSO login failed: ${e.toString().replaceAll('Exception: ', '')}'), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
    });

    try {
      if (_requires2FA) {
         // Second step
         await ref.read(authProvider.notifier).loginWith2FA(
            _emailController.text.trim().replaceAll('`', ''),
            _passwordController.text.trim().replaceAll('`', ''),
            _totpController.text.trim()
         );
      } else {
         // First step
         await ref.read(authProvider.notifier).login(
            _emailController.text.trim().replaceAll('`', ''),
            _passwordController.text.trim().replaceAll('`', ''),
         );
      }
    } catch (e) {
      final errStr = e.toString();
      if (errStr.contains('2FA required')) {
         setState(() {
           _requires2FA = true;
           _errorMessage = null;
         });
      } else {
         setState(() {
           _errorMessage = errStr.replaceAll('Exception: ', '');
         });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF13151A), // Deep dark background
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 900) {
            return _buildDesktopLayout();
          } else {
            return _buildMobileLayout();
          }
        },
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        // Left side (Image and Branding)
        Expanded(
          flex: 5,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0A1628),
                  const Color(0xFF1A2E4A),
                  const Color(0xFF0D2137),
                ],
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(64.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      const Text('CONSTRUCT',
                          style: TextStyle(
                              color: Colors.lightBlueAccent,
                              fontSize: 32,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      const Icon(Icons.apartment,
                          color: Colors.orangeAccent, size: 36),
                      const SizedBox(width: 8),
                      const Text('ERP',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Welcome back to\nConstructConnect',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        height: 1.1),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'The single platform for all your\nconstruction project data. Secure Access.',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 18, height: 1.5),
                  ),
                  const SizedBox(height: 48),
                  Container(
                    height: 120,
                    width: 400,
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.lightBlueAccent.withValues(alpha: 0.5)),
                      borderRadius: BorderRadius.circular(16),
                      color: Colors.blue.withValues(alpha: 0.1),
                    ),
                    child: const Center(
                        child: Icon(Icons.timeline,
                            color: Colors.lightBlueAccent, size: 64)),
                  )
                ],
              ),
            ),
          ),
        ),

        // Right side (Login Form)
        Expanded(
          flex: 5,
          child: Container(
            color: const Color(0xFF13151A),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildGlassLoginForm(isMobile: false),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF0A1628),
            const Color(0xFF1A2E4A),
            const Color(0xFF0D2137),
          ],
        ),
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.handyman, color: CivilTheme.primary, size: 48),
              const SizedBox(height: 16),
              const Text('PROSTRUCT\nERP',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2)),
              const SizedBox(height: 32),
              const Text('Welcome to ProStruct ERP',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Your construction project hub',
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 32),
              _buildGlassLoginForm(isMobile: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassLoginForm({required bool isMobile}) {
    final isLoading = ref.watch(authProvider).isLoading;
    final primaryColor = isMobile ? CivilTheme.primary : Colors.lightBlueAccent;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border:
                Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!isMobile) ...[
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.domain,
                            color: Colors.lightBlueAccent),
                      ),
                      const SizedBox(width: 12),
                      const Text('Secure Sign In',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 32),
                ] else ...[
                  const Text('SIGN IN',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 32),
                ],

                // Error
                if (_errorMessage != null) ...[
                  Text(_errorMessage!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 13)),
                  const SizedBox(height: 16),
                ],

                if (_requires2FA) ...[
                  const Text('Two-Factor Authentication',
                      style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _totpController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '123456',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      labelText: isMobile ? '6-Digit Code' : null,
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.security, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.2),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor.withValues(alpha: 0.5))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor)),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  // Email
                  if (!isMobile)
                    const Text('Work Email',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  if (!isMobile) const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: isMobile
                          ? 'J.Miller@prostruct.co'
                          : 'user@construct.com',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      labelText: isMobile ? 'Username' : null,
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon:
                          const Icon(Icons.person_outline, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.2),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: primaryColor.withValues(alpha: 0.5))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor)),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 20),

                  // Password
                  if (!isMobile)
                    const Text('Password',
                        style: TextStyle(color: Colors.white70, fontSize: 13)),
                  if (!isMobile) const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
                      labelText: isMobile ? 'Password' : null,
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon:
                          const Icon(Icons.lock_outline, color: Colors.white70),
                      suffixIcon:
                          const Icon(Icons.visibility_off, color: Colors.white70),
                      filled: true,
                      fillColor: Colors.black.withValues(alpha: 0.2),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              BorderSide(color: primaryColor.withValues(alpha: 0.5))),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor)),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                ],

                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => context.push('/forgot-password'),
                    child: Text('Forgot Password?',
                        style: TextStyle(color: primaryColor, fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => context.push('/otp-login'),
                    child: Text('Login with OTP →',
                        style: TextStyle(color: primaryColor.withValues(alpha: 0.8), fontSize: 13)),
                  ),
                ),
                const SizedBox(height: 24),

                // Submit Button
                Container(
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: LinearGradient(
                      colors: isMobile
                          ? [
                              CivilTheme.primary,
                              CivilTheme.primary.withValues(alpha: 0.7)
                            ]
                          : [Colors.lightBlueAccent, Colors.blue],
                    ),
                    boxShadow: [
                      BoxShadow(
                          color: primaryColor.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : Text(isMobile ? 'LOG IN' : 'Sign In \u2192',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 32),

                // SSO
                Row(
                  children: [
                    const Expanded(child: Divider(color: Colors.white24)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                          isMobile ? 'Or sign in with:' : 'Or sign in with SSO',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12)),
                    ),
                    const Expanded(child: Divider(color: Colors.white24)),
                  ],
                ),
                const SizedBox(height: 24),

                if (isMobile)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSocialIcon(Icons.g_mobiledata, Colors.redAccent),
                      const SizedBox(width: 16),
                      _buildSocialIcon(Icons.window, Colors.lightBlue),
                      const SizedBox(width: 16),
                      _buildSocialIcon(Icons.cases_outlined, Colors.orange),
                    ],
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _ssoLogin('Google'),
                          icon: const Icon(Icons.g_mobiledata,
                              color: Colors.redAccent),
                          label: const Text('SSO (Email)',
                              style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.lightBlueAccent.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _ssoLogin('AzureAD'),
                          icon: const Icon(Icons.cloud,
                              color: Colors.lightBlueAccent),
                          label: const Text('SSO (Email)',
                              style: TextStyle(color: Colors.white)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                                color: Colors.lightBlueAccent.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),

                const SizedBox(height: 32),
                Center(
                  child: Text.rich(
                    TextSpan(
                      text: "Don't have an account? ",
                      style:
                          const TextStyle(color: Colors.white70, fontSize: 13),
                      children: [
                        TextSpan(
                            text:
                                isMobile ? 'Request access' : 'Request Access',
                            style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}
