import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stockfolio_app/core/api_service.dart';
import '../../widgets/auth_text_field.dart';
import '../../core/theme.dart';
import 'package:provider/provider.dart';
import '../../core/api_service.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _loading = false;
  bool _obscurePsw = true;
  String? _errorMsg;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Future<void> _handleLogin() async {
  //   if (!_formKey.currentState!.validate()) return;
  //   setState(() {
  //     _loading = true;
  //     _errorMsg = null;
  //   });
  //   try {
  //     final api = context.read<ApiService>();
  //     final response = await api.post(
  //       "login/",
  //       data: {
  //         "username": _usernameController.text.trim(),
  //         "password": _passwordController.text,
  //       },
  //     );
  //     // response.data is a Map<String, dynamic> from Django:
  //     // { access: "eyJ...", refresh: "eyJ...", is_superuser: bool, username: "..." }

  //     final data = response.data as Map<String, dynamic>;
  //     if (mounted) {
  //       await context.read<AuthProvider>().login(data);
  //     }
  //   } on DioException catch (e) {
  //     String msg;

  //     if (e.response != null) {
  //       final errData = e.response!.data;
  //       if (errData is Map && errData["error"] != null) {
  //         msg = errData["error"] as String;
  //       } else {
  //         msg = 'Login Failed. Please check your credentials.';
  //       }
  //     } else {
  //       msg = 'Cannot reach server. Is Django running on port 8000?';
  //     }

  //     if (mounted)
  //       setState(() {
  //         _loading = false;
  //         _errorMsg = msg;
  //       });
  //     return;
  //   } catch (e) {
  //     if (mounted)
  //       setState(() {
  //         _loading = false;
  //         _errorMsg = 'An unexpected error occurred: $e';
  //       });
  //     return;
  //   }
  //   if (mounted) setState(() => _loading = false);
  // }
Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
 
    setState(() { _loading = true; _errorMsg = null; });
 
    try {
      // context.read() gets the ApiService without watching for changes.
      // Use read() in callbacks/async functions, watch() in build().
      // current widget location in widget tree
      // read<ApiService>() : "Read provider value of type ApiService"
      final api = context.read<ApiService>();
 
      // POST /api/login/ with username and password
      final response = await api.post(
        "login/",
        data: {
          "username": _usernameController.text.trim(),
          "password": _passwordController.text,
        },
      );
 
      // response.data is a Map<String, dynamic> from Django:
      // { access: "eyJ...", refresh: "eyJ...", is_superuser: bool, username: "..." }
      final data = response.data as Map<String, dynamic>;
// login() saves to SharedPreferences and calls notifyListeners()
      // GoRouter redirect fires → isLoggedIn = true → /dashboard
      if (mounted) {
        // mounted: "Is this widget still alive in widget tree?"
        await context.read<AuthProvider>().login(data);
        // Navigation happens automatically via GoRouter redirect.
        // You do NOT need to call context.go("/dashboard") here.
      }
 
    } on DioException catch (e) {
      // DioException is thrown for any HTTP error or network problem.
      // e.response?.data contains the Django error response.
      String msg;
 
      if (e.response != null) {
        // Django returned an error response (401, 400, etc.)
        final errData = e.response!.data;
        if (errData is Map && errData["error"] != null) {
          msg = errData["error"] as String;
        } else {
          msg = 'Login failed. Please check your credentials.';
        }
      } else {
        // No response — network error, server down, wrong IP etc.
        msg = 'Cannot reach server. Is Django running on port 8000?';
      }
 
      if (mounted) setState(() { _loading = false; _errorMsg = msg; });
      return;
    } catch (e) {
      // Any other unexpected error
      if (mounted) setState(() {
        _loading  = false;
        _errorMsg = 'An unexpected error occurred: $e';
      });
      return;
    }
 
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.show_chart_rounded,
                      size: 64,
                      color: AppColors.brand,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Stockfolio',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Your personal trading journal',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 36),

                    if (_errorMsg != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.red.withOpacity(0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline,
                              color: AppColors.red,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _errorMsg!,
                                style: const TextStyle(
                                  color: AppColors.red,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    AuthTextField(
                      label: 'Username',
                      hint: 'Enter your username',
                      controller: _usernameController,
                      prefixIcon: Icons.person_outline,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Username is required'
                          : null,
                    ),
                    const SizedBox(height: 16),

                    AuthTextField(
                      label: 'Password',
                      hint: 'Enter your password',
                      controller: _passwordController,
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePsw,
                      // The show/hide toggle button
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePsw
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        // setState triggers a rebuild with the new obscureText value
                        onPressed: () =>
                            setState(() => _obscurePsw = !_obscurePsw),
                      ),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Password is required'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    // Forgot password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push('/forgot-password'),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Sign in button
                    ElevatedButton(
                      onPressed: _loading ? null : _handleLogin,
                      child: _loading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Sign In'),
                    ),
                    const SizedBox(height: 24),
                    // Divider
                    const Row(
                      children: [
                        Expanded(child: Divider()),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'or',
                            style: TextStyle(color: AppColors.textMuted),
                          ),
                        ),
                        Expanded(child: Divider()),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Register link
                    OutlinedButton(
                      onPressed: () => context.push('/register'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.brand,
                        side: const BorderSide(color: AppColors.brand),
                        minimumSize: const Size(double.infinity, 52),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Create an account'),
                    ),
                    const SizedBox(height: 32),

                    //  Version info
                    const Text(
                      'Stockfolio v1.0.0',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: AppColors.textHint),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
