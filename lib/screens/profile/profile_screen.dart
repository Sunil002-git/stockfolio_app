import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/auth_text_field.dart';
 
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}
 
class _ProfileScreenState extends State<ProfileScreen> {
  // Profile form
  final _firstCtrl = TextEditingController();
  final _lastCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
 
  // Password form
  final _curPswCtrl = TextEditingController();
  final _newPswCtrl = TextEditingController();
  final _cfmPswCtrl = TextEditingController();
 
  Map<String,dynamic>? _profile;
  bool    _loading   = true;
  bool    _saving    = false;
  bool    _savingPsw = false;
  String? _profileMsg;
  String? _pswMsg;
  bool    _profileSuccess = false;
  bool    _pswSuccess     = false;
  bool    _obscureCur = true;
  bool    _obscureNew = true;
  bool    _obscureCfm = true;
 
  @override
  void initState() { super.initState(); _loadProfile(); }
 
  @override
  void dispose() {
    _firstCtrl.dispose(); _lastCtrl.dispose();
    _emailCtrl.dispose(); _phoneCtrl.dispose();
    _curPswCtrl.dispose(); _newPswCtrl.dispose(); _cfmPswCtrl.dispose();
    super.dispose();
  }
 
  Future<void> _loadProfile() async {
    try {
      final res = await context.read<ApiService>().get('profile/');
      final data = res.data as Map<String,dynamic>;
      setState(() {
        _profile = data;
        _firstCtrl.text = data['first_name'] as String? ?? '';
        _lastCtrl.text  = data['last_name']  as String? ?? '';
        _emailCtrl.text = data['email']      as String? ?? '';
        _phoneCtrl.text = data['phone']      as String? ?? '';
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }
 
  Future<void> _saveProfile() async {
    setState(() { _saving = true; _profileMsg = null; });
    try {
      await context.read<ApiService>().patch('profile/', data: {
        'first_name': _firstCtrl.text.trim(),
        'last_name':  _lastCtrl.text.trim(),
        'email':      _emailCtrl.text.trim(),
        'phone':      _phoneCtrl.text.trim(),
      });
      setState(() {
        _profileMsg     = 'Profile updated successfully!';
        _profileSuccess = true;
        _saving         = false;
      });
    } on DioException catch (e) {
      setState(() {
        _profileMsg     = e.response?.data?['error'] ?? 'Update failed.';
        _profileSuccess = false;
        _saving         = false;
      });
    }
  }
 
  Future<void> _changePassword() async {
    if (_newPswCtrl.text != _cfmPswCtrl.text) {
      setState(() { _pswMsg = 'Passwords do not match.'; _pswSuccess = false; });
      return;
    }
    if (_newPswCtrl.text.length < 8) {
      setState(() { _pswMsg = 'Minimum 8 characters.'; _pswSuccess = false; });
      return;
    }
    setState(() { _savingPsw = true; _pswMsg = null; });
    try {
      await context.read<ApiService>().patch('profile/', data: {
        'current_password': _curPswCtrl.text,
        'new_password':     _newPswCtrl.text,
      });
      _curPswCtrl.clear(); _newPswCtrl.clear(); _cfmPswCtrl.clear();
      setState(() {
        _pswMsg     = 'Password changed. Sign in with your new password.';
        _pswSuccess = true;
        _savingPsw  = false;
      });
    } on DioException catch (e) {
      setState(() {
        _pswMsg     = e.response?.data?['error'] ?? 'Failed.';
        _pswSuccess = false;
        _savingPsw  = false;
      });
    }
  }
 
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Avatar ────────────────────────────────────
              Center(
                child: Column(children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppColors.brand,
                    child: Text(
                      (_firstCtrl.text.isNotEmpty
                        ? _firstCtrl.text[0]
                        : (auth.username ?? 'U')[0]).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.bold,
                        color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('@${auth.username ?? ''}',
                    style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 14)),
                  if (auth.isSuperuser)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.orange.withOpacity(0.4)),
                      ),
                      child: const Row(mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined,
                            color: AppColors.orange, size: 14),
                          SizedBox(width: 4),
                          Text('Superuser', style: TextStyle(
                            color: AppColors.orange, fontSize: 12,
                            fontWeight: FontWeight.w600)),
                        ]),
                    ),
                ]),
              ),
              const SizedBox(height: 24),
 
              // ── Personal info ──────────────────────────────
              _SectionTitle(title: 'Personal Information',
                icon: Icons.person_outline),
              const SizedBox(height: 12),
              if (_profileMsg != null)
                _MsgBanner(msg: _profileMsg!, success: _profileSuccess),
              Row(children: [
                Expanded(child: AuthTextField(
                  label: 'First Name', hint: 'First',
                  controller: _firstCtrl,
                  prefixIcon: Icons.person_outline,
                )),
                const SizedBox(width: 12),
                Expanded(child: AuthTextField(
                  label: 'Last Name', hint: 'Last',
                  controller: _lastCtrl,
                )),
              ]),
              const SizedBox(height: 12),
              AuthTextField(
                label: 'Email', hint: 'your@email.com',
                controller: _emailCtrl,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              AuthTextField(
                label: 'Phone', hint: '+91 98765 43210',
                controller: _phoneCtrl,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _saving ? null : _saveProfile,
                icon: _saving
                  ? const SizedBox(width:18,height:18,
                      child:CircularProgressIndicator(strokeWidth:2,color:Colors.white))
                  : const Icon(Icons.save_outlined),
                label: const Text('Save Changes'),
              ),
              const SizedBox(height: 28),
 
              // ── Change password ────────────────────────────
              _SectionTitle(title: 'Change Password',
                icon: Icons.lock_outline),
              const SizedBox(height: 12),
              if (_pswMsg != null)
                _MsgBanner(msg: _pswMsg!, success: _pswSuccess),
              AuthTextField(
                label: 'Current Password',
                hint:  'Enter current password',
                controller: _curPswCtrl,
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureCur,
                suffixIcon: IconButton(
                  icon: Icon(_obscureCur
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                  onPressed: () =>
                    setState(() => _obscureCur = !_obscureCur),
                ),
              ),
              const SizedBox(height: 12),
              AuthTextField(
                label: 'New Password',
                hint:  'At least 8 characters',
                controller: _newPswCtrl,
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureNew,
                suffixIcon: IconButton(
                  icon: Icon(_obscureNew
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                  onPressed: () =>
                    setState(() => _obscureNew = !_obscureNew),
                ),
              ),
              const SizedBox(height: 12),
              AuthTextField(
                label: 'Confirm Password',
                hint:  'Repeat new password',
                controller: _cfmPswCtrl,
                prefixIcon: Icons.lock_outline,
                obscureText: _obscureCfm,
                suffixIcon: IconButton(
                  icon: Icon(_obscureCfm
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                  onPressed: () =>
                    setState(() => _obscureCfm = !_obscureCfm),
                ),
              ),
              const SizedBox(height: 14),
              ElevatedButton.icon(
                onPressed: _savingPsw ? null : _changePassword,
                icon: _savingPsw
                  ? const SizedBox(width:18,height:18,
                      child:CircularProgressIndicator(strokeWidth:2,color:Colors.white))
                  : const Icon(Icons.key_outlined),
                label: const Text('Change Password'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                ),
              ),
              const SizedBox(height: 28),
 
              // ── Sign out ───────────────────────────────────
              OutlinedButton.icon(
                onPressed: () async {
                  await context.read<AuthProvider>().logout();
                },
                icon: const Icon(Icons.logout, color: AppColors.red),
                label: const Text('Sign Out',
                  style: TextStyle(color: AppColors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.red),
                  minimumSize: const Size(double.infinity, 52),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
    );
  }
}
 
class _SectionTitle extends StatelessWidget {
  final String title; final IconData icon;
  const _SectionTitle({required this.title, required this.icon});
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 18, color: AppColors.brand),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(
        fontWeight: FontWeight.bold, fontSize: 16,
        color: AppColors.textPrimary)),
    ]);
  }
}
 
class _MsgBanner extends StatelessWidget {
  final String msg; final bool success;
  const _MsgBanner({required this.msg, required this.success});
  @override
  Widget build(BuildContext context) {
    final color = success ? AppColors.green : AppColors.red;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(msg, style: TextStyle(color: color, fontSize: 13)),
    );
  }
}
