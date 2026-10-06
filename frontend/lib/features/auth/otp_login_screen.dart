import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api_client.dart';
import '../../core/auth_provider.dart';
import '../../core/theme.dart';

class OtpLoginScreen extends ConsumerStatefulWidget {
  const OtpLoginScreen({super.key});

  @override
  ConsumerState<OtpLoginScreen> createState() => _OtpLoginScreenState();
}

class _OtpLoginScreenState extends ConsumerState<OtpLoginScreen>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final List<TextEditingController> _otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool _isLoading = false;
  bool _otpSent = false;
  String? _error;
  int _resendCooldown = 0;

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    for (final c in _otpCtrls) { c.dispose(); }
    for (final f in _otpFocusNodes) { f.dispose(); }
    super.dispose();
  }

  String get _otpValue => _otpCtrls.map((c) => c.text).join();

  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _error = 'Enter a valid email address');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      await ref.read(apiClientProvider).post('/auth/send-otp', {'email': email});
      setState(() {
        _isLoading = false;
        _otpSent = true;
        _resendCooldown = 60;
      });
      _startCooldown();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  void _startCooldown() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _resendCooldown--);
      return _resendCooldown > 0;
    });
  }

  Future<void> _verifyOtp() async {
    final otp = _otpValue;
    if (otp.length != 6) {
      setState(() => _error = 'Please enter all 6 digits');
      return;
    }
    setState(() { _isLoading = true; _error = null; });
    try {
      final response = await ref.read(apiClientProvider).post('/auth/verify-otp', {
        'email': _emailCtrl.text.trim().toLowerCase(),
        'otp': otp,
      });
      final token = response['token'] as String;
      final user = response['user'] as Map<String, dynamic>;
      await ref.read(authProvider.notifier).setSession(token, user);
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
            colors: [Color(0xFF0D1117), Color(0xFF161B22), Color(0xFF0F2027)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
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
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF11998E), Color(0xFF38EF7D)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.phonelink_lock, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _otpSent ? 'Enter OTP Code' : 'OTP Login',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _otpSent
                            ? 'We sent a 6-digit code to ${_emailCtrl.text.trim()}. It expires in 10 minutes.'
                            : 'Login securely without a password using a one-time code.',
                        style: const TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
                      ),
                      const SizedBox(height: 32),

                      if (_error != null) _buildError(_error!),
                      const SizedBox(height: 8),

                      if (!_otpSent) ...[
                        const Text('Email Address',
                            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: Colors.white),
                          decoration: _inputDecoration('you@company.com', Icons.email_outlined),
                        ),
                        const SizedBox(height: 28),
                        _buildPrimaryButton(
                          label: 'Send OTP Code',
                          icon: Icons.send_outlined,
                          onTap: _isLoading ? null : _sendOtp,
                          isLoading: _isLoading,
                          gradientColors: const [Color(0xFF11998E), Color(0xFF38EF7D)],
                        ),
                      ],

                      if (_otpSent) ...[
                        const Text('6-Digit Code',
                            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 16),
                        _buildOtpBoxes(),
                        const SizedBox(height: 28),
                        _buildPrimaryButton(
                          label: 'Verify & Login',
                          icon: Icons.verified_user_outlined,
                          onTap: _isLoading ? null : _verifyOtp,
                          isLoading: _isLoading,
                          gradientColors: const [Color(0xFF11998E), Color(0xFF38EF7D)],
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: _resendCooldown > 0
                              ? Text(
                                  'Resend in $_resendCooldown seconds',
                                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                                )
                              : TextButton(
                                  onPressed: _sendOtp,
                                  child: const Text(
                                    'Resend OTP',
                                    style: TextStyle(color: Color(0xFF38EF7D), fontSize: 13),
                                  ),
                                ),
                        ),
                        Center(
                          child: TextButton(
                            onPressed: () => setState(() { _otpSent = false; _error = null; }),
                            child: const Text(
                              '← Change email',
                              style: TextStyle(color: Colors.white38, fontSize: 13),
                            ),
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

  Widget _buildOtpBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (i) {
        return SizedBox(
          width: 48,
          height: 60,
          child: TextField(
            controller: _otpCtrls[i],
            focusNode: _otpFocusNodes[i],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.07),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF38EF7D), width: 2),
              ),
            ),
            onChanged: (val) {
              if (val.isNotEmpty && i < 5) {
                _otpFocusNodes[i + 1].requestFocus();
              } else if (val.isEmpty && i > 0) {
                _otpFocusNodes[i - 1].requestFocus();
              }
              if (i == 5 && val.isNotEmpty) _verifyOtp();
            },
          ),
        );
      }),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.white38),
      prefixIcon: Icon(icon, color: Colors.white38, size: 20),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF11998E)),
      ),
    );
  }

  Widget _buildError(String msg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Row(children: [
        const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(color: Colors.redAccent, fontSize: 13))),
      ]),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onTap,
    required bool isLoading,
    required List<Color> gradientColors,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: gradientColors),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: gradientColors.first.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: onTap,
          icon: isLoading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Icon(icon, color: Colors.white, size: 18),
          label: Text(
            isLoading ? 'Please wait…' : label,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }
}
