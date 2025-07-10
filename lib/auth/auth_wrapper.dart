// lib/auth/auth_wrapper.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/user_provider.dart';
import '../pages/home/home_owner_page.dart';
import '../pages/home/home_renter_page.dart';
import '../pages/shared/splash_screen.dart';
import '../auth/login_page.dart';
import '../auth/role_selection_page.dart';

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final userAsyncValue = ref.watch(userProvider);

    return authState.when(
      loading: () => const SplashScreen(),
      error: (error, stackTrace) => _buildErrorPage(context, error),
      data: (isAuthenticated) {
        if (!isAuthenticated) {
          return const LoginPage();
        }

        // User sudah login, cek data user
        return userAsyncValue.when(
          loading: () => const SplashScreen(),
          error: (error, stackTrace) => _buildErrorPage(context, error),
          data: (user) {
            if (user == null) {
              return const LoginPage();
            }

            // Cek apakah user sudah memilih role
            final userRole = user.role;
            
            if (userRole == null || userRole.isEmpty) {
              return const RoleSelectionPage();
            }

            // Route berdasarkan role
            switch (userRole.toLowerCase()) {
              case 'owner':
                return const HomeOwnerPage();
              case 'renter':
                return const HomeRenterPage();
              default:
                return _buildUnknownRolePage(context, userRole);
            }
          },
        );
      },
    );
  }

  Widget _buildErrorPage(BuildContext context, Object error) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'Terjadi kesalahan',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Restart app atau refresh auth state
                // Bisa juga navigate ke login page
              },
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnknownRolePage(BuildContext context, String role) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.help_outline,
              size: 64,
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Text(
              'Role tidak dikenali',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Role: $role',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // Navigate ke role selection page atau logout
              },
              child: const Text('Pilih Role Ulang'),
            ),
          ],
        ),
      ),
    );
  }
}