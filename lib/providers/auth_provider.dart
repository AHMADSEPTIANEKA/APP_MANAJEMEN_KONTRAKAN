import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;

import '../utils/appwrite_client.dart';
import 'user_provider.dart';
import 'property_provider.dart';

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<bool>>((ref) {
  return AuthNotifier(ref);
});

final authErrorProvider = StateProvider<String?>((ref) => null);
final authLoadingProvider = StateProvider<bool>((ref) => false);

class AuthNotifier extends StateNotifier<AsyncValue<bool>> {
  final Ref ref;
  late final Account account;
  late final Databases databases;

  AuthNotifier(this.ref) : super(const AsyncValue.loading()) {
    final client = ref.read(appwriteClientProvider);
    account = Account(client);
    databases = Databases(client);
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final user = await account.get();
      ref.read(userProvider.notifier).setUser(user);
      state = const AsyncValue.data(true);

      final role = _getUserRole(user);
      if (role == null) {
        state = AsyncValue.error('Role pengguna tidak ditemukan', StackTrace.current);
        return;
      }

      await _fetchPropertiesBasedOnRole(role);
    } catch (e) {
      if (e is AppwriteException && e.code == 401) {
        state = const AsyncValue.data(false);
      } else {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  String? _getUserRole(models.User user) {
    try {
      final prefs = user.prefs.data;
      final role = prefs['role'] as String?;
      final allowedRoles = ['owner', 'renter'];
      if (role != null && allowedRoles.contains(role)) {
        return role;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return null;
    }
  }

  Future<void> _fetchPropertiesBasedOnRole(String role) async {
    try {
      final mode = role == 'owner'
          ? PropertyFetchMode.ownerOnly
          : PropertyFetchMode.availableOnly;

      await ref.read(propertyListProvider.notifier).fetchProperties(mode: mode);
    } catch (e) {
      debugPrint('Error fetching properties: $e');
      rethrow;
    }
  }

  Future<String> login({
    required String email,
    required String password,
  }) async {
    ref.read(authLoadingProvider.notifier).state = true;
    ref.read(authErrorProvider.notifier).state = null;

    try {
      await account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      final user = await account.get();
      ref.read(userProvider.notifier).setUser(user);
      state = const AsyncValue.data(true);

      final role = _getUserRole(user);
      if (role == null) {
        await logout();
        throw Exception('Akun Anda belum memiliki role yang valid. Silakan hubungi admin.');
      }

      await _fetchPropertiesBasedOnRole(role);
      return role;
    } on AppwriteException catch (e) {
      final errorMessage = _getErrorMessage(e);
      ref.read(authErrorProvider.notifier).state = errorMessage;
      state = AsyncValue.error(e, StackTrace.current);
      throw Exception(errorMessage);
    } catch (e) {
      ref.read(authErrorProvider.notifier).state = 'Terjadi kesalahan saat login';
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    ref.read(authLoadingProvider.notifier).state = true;
    ref.read(authErrorProvider.notifier).state = null;

    try {
      if (!['owner', 'renter'].contains(role)) {
        throw Exception('Role tidak valid');
      }

      await account.create(
        userId: ID.unique(),
        email: email,
        password: password,
        name: name,
      );

      // Login dulu agar updatePrefs berhasil
      await account.createEmailPasswordSession(
        email: email,
        password: password,
      );

      // Baru update role setelah sesi aktif
      await account.updatePrefs(prefs: {'role': role});

      // Ambil ulang user info
      final updatedUser = await account.get();
      ref.read(userProvider.notifier).setUser(updatedUser);

      // Logout agar user bisa login manual setelah register
      await account.deleteSession(sessionId: 'current');

      return true;
    } on AppwriteException catch (e) {
      ref.read(authErrorProvider.notifier).state = _getErrorMessage(e);
      return false;
    } catch (e) {
      ref.read(authErrorProvider.notifier).state = e.toString();
      return false;
    } finally {
      ref.read(authLoadingProvider.notifier).state = false;
    }
  }

  Future<void> logout() async {
    try {
      await account.deleteSessions();
      ref.read(userProvider.notifier).clearUser();
      ref.read(propertyListProvider.notifier).state = const AsyncValue.data([]);
      state = const AsyncValue.data(false);
      ref.read(authErrorProvider.notifier).state = null;
    } catch (e) {
      debugPrint('Error during logout: $e');
      rethrow;
    }
  }

  Future<void> refreshAuth() async {
    state = const AsyncValue.loading();
    await _checkAuth();
  }

  Future<bool> updateUserRole(String role) async {
    try {
      if (!['owner', 'renter'].contains(role)) {
        throw Exception('Role tidak valid');
      }

      await account.updatePrefs(prefs: {'role': role});
      final user = await account.get();
      ref.read(userProvider.notifier).setUser(user);
      await _fetchPropertiesBasedOnRole(role);

      return true;
    } on AppwriteException catch (e) {
      ref.read(authErrorProvider.notifier).state = _getErrorMessage(e);
      return false;
    } catch (e) {
      ref.read(authErrorProvider.notifier).state = e.toString();
      return false;
    }
  }

  String _getErrorMessage(AppwriteException error) {
    switch (error.code) {
      case 401:
        if (error.message?.contains('user_session_already_exists') ?? false) {
          return 'Anda sudah login di perangkat lain. Silakan logout terlebih dahulu.';
        }
        return 'Email atau password tidak valid';
      case 400:
        return 'Permintaan tidak valid: ${error.message}';
      case 404:
        return 'Akun tidak ditemukan';
      case 409:
        return 'Email sudah terdaftar';
      case 429:
        return 'Terlalu banyak percobaan, coba lagi nanti';
      default:
        return error.message ?? 'Terjadi kesalahan yang tidak diketahui';
    }
  }
}
