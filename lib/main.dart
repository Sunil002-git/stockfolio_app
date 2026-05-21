import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'core/api_service.dart';
import 'providers/auth_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

// ── Entry point ─────────────────────────────────────────────────
// WidgetsFlutterBinding.ensureInitialized() is required when you do
// async work before runApp() — like reading SharedPreferences.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const StockfolioApp());
}

class StockfolioApp extends StatefulWidget {
  const StockfolioApp({super.key});
  @override
  State<StockfolioApp> createState() => _StockfolioAppState();
}

class _StockfolioAppState extends State<StockfolioApp> {
  // Create AuthProvider once — lives for the entire app lifetime
  final _auth = AuthProvider();

  @override
  void initState() {
    super.initState();
    // Restore session from SharedPreferences on app start.
    // When complete it calls notifyListeners() which triggers
    // GoRouter to re-evaluate the redirect function.
    _auth.restoreSession();
  }

  @override
  void dispose() {
    // Clean up when the app is closed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // ChangeNotifierProvider wraps the existing _auth instance.
        // Use .value when the provider is created outside the tree.
        ChangeNotifierProvider<AuthProvider>.value(value: _auth),

        // ProxyProvider creates ApiService and injects AuthProvider.
        // It recreates ApiService whenever AuthProvider changes.
        ProxyProvider<AuthProvider, ApiService>(
          update: (_, auth, __) => ApiService(auth),
        ),
      ],
      child: Builder(
        builder: (context) {
          final auth = context.watch<AuthProvider>();

          // ── Router ─────────────────────────────────────────────
          final router = GoRouter(
            initialLocation: '/login',

            // redirect() is the route guard — runs before every navigation.
            // Equivalent to PrivateRoute and AdminRoute in App.js.
            redirect: (ctx, state) {
              // Wait until session restore is complete.
              // Without this, the guard would redirect to /login
              // even for users who are already logged in.
              if (!auth.isInitialized) return null;

              final loggedIn = auth.isLoggedIn;
              final path = state.matchedLocation;
              final authPaths = ["/login", "/register", "/forgot-password"];

              // Not logged in → trying a private page → send to login
              if (!loggedIn && !authPaths.contains(path)) {
                return '/login';
              }

              // Already logged in → trying login/register → send to dashboard
              if (loggedIn && authPaths.contains(path)) {
                return '/dashboard';
              }

              return null; // null = allow navigation, no redirect
            },

            // refreshListenable tells GoRouter to re-run redirect()
            // every time AuthProvider calls notifyListeners().
            // This is what makes logout → /login and login → /dashboard work.
            refreshListenable: auth,

            routes: [
              GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
              GoRoute(
                path: '/register',
                builder: (_, __) => const RegisterScreen(),
              ),
              GoRoute(
                path: '/forgot-password',
                builder: (_, __) => const ForgotPasswordScreen(),
              ),
              GoRoute(
                path: '/dashboard',
                builder: (_, __) => const DashboardScreen(),
              ),
              // TODO Sprint 3+: add /positions, /trades, /history etc.
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
