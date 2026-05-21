import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme.dart';

// DashboardScreen — shown after successful login.
// This is a SKELETON. Full implementation comes in Sprint 4.
// Right now it just confirms login worked and has a logout button.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // context.watch() rebuilds this widget when AuthProvider changes.
    // context.read() would not — use read() for one-time reads in callbacks.
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        // No back button — this is the main screen after login.
        // automaticallyImplyLeading: false removes the back arrow.
        automaticallyImplyLeading: false,
        actions: [
          // Logout button in top-right corner
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: "Sign out",
            onPressed: () async {
              // logout() clears tokens and calls notifyListeners()
              // GoRouter redirect fires → sees isLoggedIn = false → /login
              await context.read<AuthProvider>().logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 80,
                color: AppColors.green,
              ),
              const SizedBox(height: 20),
              const Text(
                'Login Successful!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              // Show the username from AuthProvider
              Text(
                'Welcome, ${auth.username ?? "trader"}',
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 8),
              // Show superuser badge if applicable
              if (auth.isSuperuser)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.orange.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.orange.withOpacity(0.4),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: AppColors.orange,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Superuser',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 40),
              const Text(
                'Full Dashboard coming in Sprint 4',
                style: TextStyle(fontSize: 14, color: AppColors.textHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
