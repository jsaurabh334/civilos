import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/auth_provider.dart';

class VendorProfileScreen extends ConsumerStatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  ConsumerState<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends ConsumerState<VendorProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyController = TextEditingController();
  final _gstController = TextEditingController();
  final _bankAccountController = TextEditingController();
  final _ifscController = TextEditingController();
  bool _isSaving = false;
  bool _isLoadingProfile = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final response = await ref.read(apiClientProvider).get('/vendor/profile', forceRefresh: true);
      if (!mounted) return;
      final data = response is Map<String, dynamic> ? response : {};
      _companyController.text = data['name'] as String? ?? '';
      _gstController.text = data['gst_number'] as String? ?? '';
      _bankAccountController.text = data['bank_account'] as String? ?? '';
      _ifscController.text = data['ifsc_code'] as String? ?? '';
    } catch (e) {
      if (!mounted) return;
      _errorMessage = 'Failed to load profile: $e';
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  @override
  void dispose() {
    _companyController.dispose();
    _gstController.dispose();
    _bankAccountController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ref.read(apiClientProvider).put('/vendor/profile', {
        'gst_number': _gstController.text,
        'bank_account': _bankAccountController.text,
        'ifsc_code': _ifscController.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUser;

    if (_isLoadingProfile) {
      return Scaffold(
        appBar: AppBar(title: const Text('Company Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Company Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
                ),
              _buildSectionTitle('Basic Information'),
              const SizedBox(height: 16),
              _buildTextField('Company Name', _companyController, icon: Icons.business),
              const SizedBox(height: 16),
              _buildTextField('Email', TextEditingController(text: user?['email'] ?? ''), icon: Icons.email, readOnly: true),
              const SizedBox(height: 16),
              _buildTextField('Phone', TextEditingController(text: user?['phone'] ?? ''), icon: Icons.phone, readOnly: true),

              const SizedBox(height: 32),
              _buildSectionTitle('Tax & Compliance'),
              const SizedBox(height: 16),
              _buildTextField('GST Number', _gstController, icon: Icons.receipt_long),

              const SizedBox(height: 32),
              _buildSectionTitle('Bank Details'),
              const SizedBox(height: 16),
              _buildTextField('Account Number', _bankAccountController, icon: Icons.account_balance),
              const SizedBox(height: 16),
              _buildTextField('IFSC Code', _ifscController, icon: Icons.code),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CivilTheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _isSaving
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: CivilTheme.textPrimary),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {IconData? icon, bool readOnly = false}) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      validator: readOnly ? null : (v) => v!.isEmpty ? 'Required field' : null,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
        filled: true,
        fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.grey)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: CivilTheme.primary)),
      ),
    );
  }
}
