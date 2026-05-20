import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/register_screen.dart';

void main() {
  runApp(const StockfolioApp());
}

class StockfolioApp extends StatelessWidget {
  const StockfolioApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: Builder(
        builder: (context) {
          final auth = context.watch<AuthProvider>();
          final router = GoRouter(
            initialLocation: '/login',
            routes: [
              GoRoute(
                path: '/login',
                builder: (context, state) => const LoginScreen(),
              ),
              GoRoute(path: '/register',
              builder: (context, state) => const RegisterScreen(),
              ),
              GoRoute(path: '/forgot-password',
              builder: (context, state) => const ForgotPasswordScreen(),
              ),
            ],
          );
          return MaterialApp.router(
            title: 'Stockfolio',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.dark(),
            routerConfig: router,
          );
        },
      ),
    );
  }
}
