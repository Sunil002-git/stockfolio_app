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
  int _step = 0;

  final _formKey = GlobalKey<FormState>();
  final _firstCtrl = TextEditingController();
  final _lastCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  // State
  bool _loading = false;
  bool _obscurePsw = true;
  bool _obscureCfm = true;
  String _otp = '';
  String? _errorMsg;
  String? _infoMsg;

  @override
  void dispose() {
    _firstCtrl.dispose();
    _lastCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // Step -1 : Send Otp
  Future<void> _sendOtp() async {
    if (!_formKey.currentState!.validate()) return;
    // Extra check password match
    if (_passwordCtrl.text != _confirmCtrl.text) {
      setState(() => _errorMsg = 'Passwords do not match.');
      return;
    }
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final api = context.read<ApiService>();
      await api.post(
        'otp/send/',
        data: {
          'email': _emailCtrl.text.trim().toLowerCase(),
          'purpose': 'register',
        },
      );

      setState(() {
        _step = 1; // advance to OTP step
        _loading = false;
        _infoMsg = 'OTP sent to ${_emailCtrl.text.trim()}';
      });
    } on DioException catch (e) {
      final errData = e.response?.data;
      setState(() {
        _loading = false;
        _errorMsg =
            (errData is Map ? errData['error'] : null) ??
            'Failed to send OTP. Check your email address.';
      });
    }
  }

  // Step 2 : Register with OTP
  Future<void> _register() async {
    if (_otp.length != 6) {
      setState(() => _errorMsg = 'Please enter the complete 6-digit OTP');
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      final api = context.read<ApiService>();
      await api.post(
        'register/otp/',
        data: {
          'username': _usernameCtrl.text.trim(),
          'email': _emailCtrl.text.trim().toLowerCase(),
          'password': _passwordCtrl.text,
          'first_name': _firstCtrl.text.trim(),
          'last_name': _lastCtrl.text.trim(),
          'otp_code': _otp,
        },
      );

      if (!mounted) return;

      // Show Suucess dialgo then navigate to login
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
                Icons.check_circle_outline,
                color: AppColors.green,
                size: 64,
              ),
              const SizedBox(height: 16),
              const Text(
                'Account Created!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome, ${_firstCtrl.text.trim()} ! You can now sign in.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
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
          if (value is List)
            errors.add('$key: ${value.first}');
          else if (value is String)
            errors.add(value);
        });
        if (errors.isNotEmpty) msg = errors.join(', ');
      }
      if (mounted)
        setState(() {
          loading = false;
          _errorMsg = msg;
        });
    }
  }

  // Resend Otp
  Future<void> _resentOtp() async {
    setState(() {
      _errorMsg = null;
      _infoMsg = null;
    });
    try {
      await context.read<ApiService>().post(
        'otp/send/',
        data: {
          'email': _emailCtrl.text.trim().toLowerCase(),
          'purpose': 'register',
        },
      );
      if (mounted) setState(() => _infoMsg = 'New OTP sent!.');
    } catch (_) {
      if (mounted) setState(() => _errorMsg = 'Failed to resend OTP. ');
    }
  }

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
            
          ),
        )),
    );
  }
}
