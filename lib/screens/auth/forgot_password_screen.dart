import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/otp_input_field.dart';
import '../../widgets/step_indicator.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  // 0 = enter email, 1 = enter OTP, 2 = enter new password
  int _step = 0;

  final _emailCtrl = TextEditingController();
  final _newPswCtrl = TextEditingController();
  final _cfmPswCtrl = TextEditingController();

  bool _loading = false;
  bool _obscure1 = true;
  bool _obscure2 = true;
  String _otp = '';
  String? _errorMsg;
  String? _infoMsg;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _newPswCtrl.dispose();
    _cfmPswCtrl.dispose();
    super.dispose();
  }

  // ── Step 1: Send OTP to email ─────────────────────────────────
  Future<void> _sendOtp() async {
    final email = _emailCtrl.text.trim().toLowerCase();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMsg = 'Enter a valid email address.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      await context.read<ApiService>().post(
        'otp/send/',
        data: {'email': email, 'purpose': 'forgot_password'},
      );
      // Django returns success even if email does not exist
      // (security: do not reveal which emails are registered)
      setState(() {
        _step = 1;
        _loading = false;
        _infoMsg = 'If that email is registered, an OTP has been sent.';
      });
    } on DioException catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = e.response?.data?['error'] ?? 'Failed to send OTP.';
      });
    }
  }

  // ── Step 2: Verify OTP ────────────────────────────────────────
  Future<void> _verifyOtp() async {
    if (_otp.length != 6) {
      setState(() => _errorMsg = 'Enter the complete 6-digit OTP.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      await context.read<ApiService>().post(
        'otp/verify/',
        data: {
          'email': _emailCtrl.text.trim().toLowerCase(),
          'code': _otp,
          'purpose': 'forgot_password',
        },
      );
      setState(() {
        _step = 2;
        _loading = false;
        _infoMsg = 'OTP verified. Set your new password.';
      });
    } on DioException catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = e.response?.data?['error'] ?? 'Invalid OTP.';
      });
    }
  }

  // ── Step 3: Reset password ────────────────────────────────────
  Future<void> _resetPassword() async {
    if (_newPswCtrl.text.length < 8) {
      setState(() => _errorMsg = 'Password must be at least 8 characters.');
      return;
    }
    if (_newPswCtrl.text != _cfmPswCtrl.text) {
      setState(() => _errorMsg = 'Passwords do not match.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      await context.read<ApiService>().post(
        'password/reset/',
        data: {
          'email': _emailCtrl.text.trim().toLowerCase(),
          'otp_code': _otp,
          'new_password': _newPswCtrl.text,
        },
      );

      if (!mounted) return;

      // Show success → navigate to login
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
              const Icon(
                Icons.lock_open_outlined,
                color: AppColors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Password Reset!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your password has been updated. Sign in with your new password.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textMuted, fontSize: 14),
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
      if (mounted)
        setState(() {
          _loading = false;
          _errorMsg = e.response?.data?['error'] ?? 'Reset failed.';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Step titles and subtitles
    const titles = ['Forgot Password', 'Enter OTP', 'New Password'];
    const subtitles = [
      'Enter your registered email address',
      'Enter the 6-digit code from your email',
      'Choose a strong new password',
    ];

    return Scaffold(
      appBar: AppBar(title: Text(titles[_step])),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Step indicator ──────────────────────────
                  StepIndicator(
                    currentStep: _step,
                    totalSteps: 3,
                    labels: const ['Email', 'Verify', 'Password'],
                  ),
                  const SizedBox(height: 24),

                  Text(
                    subtitles[_step],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Messages ─────────────────────────────────
                  if (_errorMsg != null) ...[
                    _Banner(message: _errorMsg!, isError: true),
                    const SizedBox(height: 16),
                  ],
                  if (_infoMsg != null) ...[
                    _Banner(message: _infoMsg!, isError: false),
                    const SizedBox(height: 16),
                  ],

                  // ── STEP 0: Email input ───────────────────────
                  if (_step == 0) ...[
                    AuthTextField(
                      label: 'Email',
                      hint: 'your@email.com',
                      controller: _emailCtrl,
                      prefixIcon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _sendOtp,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Send OTP'),
                    ),
                  ],

                  // ── STEP 1: OTP input ─────────────────────────
                  if (_step == 1) ...[
                    OtpInputField(
                      onCompleted: (v) => setState(() => _otp = v),
                      onChanged: (v) => setState(() => _otp = v),
                    ),
                    const SizedBox(height: 28),
                    ElevatedButton(
                      onPressed: (_loading || _otp.length != 6)
                          ? null
                          : _verifyOtp,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Verify OTP'),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _step = 0;
                        _errorMsg = null;
                        _infoMsg = null;
                      }),
                      child: const Text('← Back'),
                    ),
                  ],

                  // ── STEP 2: New password ───────────────────────
                  if (_step == 2) ...[
                    AuthTextField(
                      label: 'New Password',
                      hint: 'At least 8 characters',
                      controller: _newPswCtrl,
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscure1,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure1
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(() => _obscure1 = !_obscure1),
                      ),
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      label: 'Confirm Password',
                      hint: 'Repeat new password',
                      controller: _cfmPswCtrl,
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscure2,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure2
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () => setState(() => _obscure2 = !_obscure2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _loading ? null : _resetPassword,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Reset Password'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Private banner widget for this file
class _Banner extends StatelessWidget {
  final String message;
  final bool isError;
  const _Banner({required this.message, required this.isError});
  @override
  Widget build(BuildContext context) {
    final color = isError ? AppColors.red : AppColors.green;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}
