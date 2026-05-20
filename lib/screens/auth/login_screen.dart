import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/auth_text_field.dart';
import '../../core/theme.dart';

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

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    await Future.delayed(const Duration(seconds: 1));

    setState(() {
      _loading = false;
      _errorMsg =
          'Sprint 2 will connect to Django. For now this is a test error.';
    });
    debugPrint('Login Attempt: ${_usernameController.text}');
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
                    const SizedBox(height: 4,),
                    const Text(
                      'Your personal trading journal',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                    ),
                    const SizedBox(height: 36,),

                    if(_errorMsg != null) ...[
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
                            const Icon(Icons.error_outline,
                            color: AppColors.red, size: 18),
                            const SizedBox(width: 10,),
                            Expanded(
                              child: Text(
                                _errorMsg!, 
                                style: const TextStyle(
                                  color:AppColors.red, fontSize: 13
                            ),
                            ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20,)
                    ],

                    AuthTextField(label: 'Username', 
                    hint: 'Enter your username', 
                    controller: _usernameController, 
                    prefixIcon: Icons.person_outline,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Username is required' : null,
                    ),
                    const SizedBox(height: 16,),

                    AuthTextField(
                      label:        'Password',
                      hint:         'Enter your password',
                      controller:   _passwordController,
                      prefixIcon:   Icons.lock_outline,
                      obscureText:  _obscurePsw,
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
                    child: TextButton(onPressed: () => context.push('/forgot-password'), 
                    child: const Text('Forgot password?'),
                    ),
                  ),
                  const SizedBox(height: 8,),
                  // Sign in button
                  ElevatedButton(
                    onPressed: _loading ? null : _handleLogin , 
                  child: _loading
                  ? const SizedBox(
                    height: 22, width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                  : const Text('Sign In'),
                  ),
                  const SizedBox(height: 24,),
                  // Divider
                  const Row(children: [
                    Expanded(child: Divider()),
                    Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                    child: Text('or', style: TextStyle(color: AppColors.textMuted),),
                    ),
                    Expanded(child: Divider()),
                  ],),
                  const SizedBox(height: 24,),
                  // Register link
                  OutlinedButton(onPressed: () => context.push('/register'),
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
                   const SizedBox(height: 32,),

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
        )),
    );
  }
}
