import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/otp_input_field.dart';
import '../../widgets/step_indicator.dart';
 
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}
 
class _RegisterScreenState extends State<RegisterScreen> {
  // ── Step control ───────────────────────────────────────────────
  // 0 = fill form, 1 = enter OTP
  int _step = 0;
 
  // ── Form key and controllers ───────────────────────────────────
  final _formKey       = GlobalKey<FormState>();
  final _firstCtrl     = TextEditingController();
  final _lastCtrl      = TextEditingController();
  final _usernameCtrl  = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passwordCtrl  = TextEditingController();
  final _confirmCtrl   = TextEditingController();
 
  // ── State ─────────────────────────────────────────────────────
  bool    _loading     = false;
  bool    _obscurePsw  = true;
  bool    _obscureCfm  = true;
  String  _otp         = '';
  String? _errorMsg;
  String? _infoMsg;
 
  @override
  void dispose() {
    _firstCtrl.dispose(); _lastCtrl.dispose();
    _usernameCtrl.dispose(); _emailCtrl.dispose();
    _passwordCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }
 
  // ── Step 1: Send OTP ────────────────────────────────────────
  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
 
    // Extra check: passwords match
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _errorMsg = 'Passwords do not match.');
      return;
    }
 
    setState(() { _loading = true; _errorMsg = null; });
 
    try {
      final api = context.read<ApiService>();
      await api.post('otp/send/', data: {
        'email':   _emailCtrl.text.trim().toLowerCase(),
        'purpose': 'register',
      });
 
      setState(() {
        _step    = 1; // advance to OTP step
        _loading = false;
        _infoMsg = 'OTP sent to ${_emailCtrl.text.trim()}';
      });
    } on DioException catch (e) {
      final errData = e.response?.data;
      setState(() {
        _loading  = false;
        _errorMsg = (errData is Map ? errData['error'] : null) ??
                    'Failed to send OTP. Check your email address.';
      });
    }
  }
 
  // ── Step 2: Register with OTP ────────────────────────────────
  Future<void> _register() async {
    if (_otp.length != 6) {
      setState(() => _errorMsg = 'Please enter the complete 6-digit OTP.');
      return;
    }
 
    setState(() { _loading = true; _errorMsg = null; });
 
    try {
      final api = context.read<ApiService>();
      await api.post('register/otp/', data: {
        'username':   _usernameCtrl.text.trim(),
        'email':      _emailCtrl.text.trim().toLowerCase(),
        'password':   _passwordCtrl.text,
        'first_name': _firstCtrl.text.trim(),
        'last_name':  _lastCtrl.text.trim(),
        'otp_code':   _otp,
      });
 
      if (!mounted) return;
 
      // Show success dialog then navigate to login
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          backgroundColor: AppColors.bgCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_outline,
                color: AppColors.green, size: 64),
              const SizedBox(height: 16),
              const Text('Account Created!',
                style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome, ${_firstCtrl.text.trim()}! You can now sign in.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go('/login');
                },
                child: const Text('Go to Sign In'),
              ),
            ],
          ),
        ),
      );
    } on DioException catch (e) {
      final errData = e.response?.data;
      String msg = 'Registration failed.';
      if (errData is Map) {
        // Django may return field errors like {"username": ["already taken"]}
        final errors = <String>[];
        errData.forEach((key, value) {
          if (value is List) errors.add('$key: ${value.first}');
          else if (value is String) errors.add(value);
        });
        if (errors.isNotEmpty) msg = errors.join(', ');
      }
      if (mounted) setState(() { _loading = false; _errorMsg = msg; });
    }
  }
 
  // ── Resend OTP ────────────────────────────────────────────────
  Future<void> _resendOtp() async {
    setState(() { _errorMsg = null; _infoMsg = null; });
    try {
      await context.read<ApiService>().post('otp/send/', data: {
        'email':   _emailCtrl.text.trim().toLowerCase(),
        'purpose': 'register',
      });
      if (mounted) setState(() => _infoMsg = 'New OTP sent!');
    } catch (_) {
      if (mounted) setState(() => _errorMsg = 'Failed to resend OTP.');
    }
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Account'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28, vertical: 16,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
 
                  // ── Step indicator ───────────────────────────
                  StepIndicator(
                    currentStep: _step,
                    totalSteps:  2,
                    labels: const ['Details', 'Verify Email'],
                  ),
                  const SizedBox(height: 28),
 
                  // ── Messages ─────────────────────────────────
                  if (_errorMsg != null) ...[
                    _MessageBanner(message: _errorMsg!, isError: true),
                    const SizedBox(height: 16),
                  ],
                  if (_infoMsg != null) ...[
                    _MessageBanner(message: _infoMsg!, isError: false),
                    const SizedBox(height: 16),
                  ],
 
                  // ── STEP 0: Form ──────────────────────────────
                  if (_step == 0)
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(children: [
                            Expanded(child: AuthTextField(
                              label: 'First Name',
                              hint:  'First',
                              controller: _firstCtrl,
                              prefixIcon: Icons.person_outline,
                            )),
                            const SizedBox(width: 12),
                            Expanded(child: AuthTextField(
                              label: 'Last Name',
                              hint:  'Last',
                              controller: _lastCtrl,
                            )),
                          ]),
                          const SizedBox(height: 16),
                          AuthTextField(
                            label:     'Username',
                            hint:      'Choose a username',
                            controller: _usernameCtrl,
                            prefixIcon: Icons.alternate_email,
                            validator:  (v) => (v == null || v.trim().isEmpty)
                                            ? 'Username is required' : null,
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            label:       'Email',
                            hint:        'your@email.com',
                            controller:   _emailCtrl,
                            prefixIcon:   Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Email is required';
                              if (!v.contains('@'))
                                return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            label:       'Password',
                            hint:        'At least 8 characters',
                            controller:   _passwordCtrl,
                            prefixIcon:   Icons.lock_outline,
                            obscureText:  _obscurePsw,
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePsw
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                              onPressed: () => setState(
                                () => _obscurePsw = !_obscurePsw),
                            ),
                            validator: (v) => (v == null || v.length < 8)
                                          ? 'At least 8 characters' : null,
                          ),
                          const SizedBox(height: 16),
                          AuthTextField(
                            label:      'Confirm Password',
                            hint:       'Repeat password',
                            controller:  _confirmCtrl,
                            prefixIcon:  Icons.lock_outline,
                            obscureText: _obscureCfm,
                            suffixIcon: IconButton(
                              icon: Icon(_obscureCfm
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined),
                              onPressed: () => setState(
                                () => _obscureCfm = !_obscureCfm),
                            ),
                            validator: (v) => (v == null || v.isEmpty)
                                          ? 'Please confirm password' : null,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _loading ? null : _sendOtp,
                            child: _loading
                              ? const SizedBox(height:22,width:22,
                                  child:CircularProgressIndicator(
                                    strokeWidth:2.5,color:Colors.white))
                              : const Text('Send Verification OTP'),
                          ),
                        ],
                      ),
                    ),
 
                  // ── STEP 1: OTP ───────────────────────────────
                  if (_step == 1)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Icon(Icons.mark_email_unread_outlined,
                          size: 56, color: AppColors.brand),
                        const SizedBox(height: 12),
                        const Text(
                          'Check your email',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Enter the 6-digit code sent to ${_emailCtrl.text.trim()}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 28),
                        OtpInputField(
                          onCompleted: (otp) =>
                            setState(() => _otp = otp),
                          onChanged: (otp) =>
                            setState(() => _otp = otp),
                        ),
                        const SizedBox(height: 28),
                        ElevatedButton(
                          onPressed: (_loading || _otp.length != 6)
                            ? null : _register,
                          child: _loading
                            ? const SizedBox(height:22,width:22,
                                child:CircularProgressIndicator(
                                  strokeWidth:2.5,color:Colors.white))
                            : const Text('Verify & Create Account'),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            TextButton(
                              onPressed: () => setState(() {
                                _step = 0;
                                _errorMsg = null;
                                _infoMsg  = null;
                              }),
                              child: const Text('← Back to form'),
                            ),
                            const Text('·',
                              style: TextStyle(color: AppColors.textMuted)),
                            TextButton(
                              onPressed: _loading ? null : _resendOtp,
                              child: const Text('Resend OTP'),
                            ),
                          ],
                        ),
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
 
// ── Private helper widget ────────────────────────────────────────
// Message banner — reused for errors and info messages.
// Private to this file (prefixed with _).
class _MessageBanner extends StatelessWidget {
  final String message;
  final bool   isError;
  const _MessageBanner({required this.message, required this.isError});
 
  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.red : AppColors.green;
    final icon  = isError
      ? Icons.error_outline
      : Icons.check_circle_outline;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:        color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border:       Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(message,
          style: TextStyle(color: color, fontSize: 13))),
      ]),
    );
  }
}
