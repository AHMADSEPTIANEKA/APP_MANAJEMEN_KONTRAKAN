// ignore_for_file: unnecessary_underscores

import 'package:app_kontrakan/providers/appwrite_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
// ignore: unused_import
import 'auth_provider.dart'; // Dibutuhkan untuk appwriteClientProvider

// 🔧 Model untuk User Data (Tidak ada perubahan)
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? role;
  final bool emailVerification;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic> prefs;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.role,
    required this.emailVerification,
    required this.createdAt,
    required this.updatedAt,
    required this.prefs,
  });

  factory UserModel.fromAppwriteUser(models.User user) {
    final prefs = user.prefs.data;
    return UserModel(
      id: user.$id,
      name: user.name,
      email: user.email,
      phone: user.phone.isNotEmpty ? user.phone : null,
      role: prefs['role'] as String?,
      emailVerification: user.emailVerification,
      createdAt: DateTime.parse(user.$createdAt),
      updatedAt: DateTime.parse(user.$updatedAt),
      prefs: prefs,
    );
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    bool? emailVerification,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? prefs,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      emailVerification: emailVerification ?? this.emailVerification,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      prefs: prefs ?? this.prefs,
    );
  }

  // ... toJson method jika Anda butuh ...
}

// ✨ PERBAIKAN 1: Ubah provider untuk bisa mengirim 'ref'
final userProvider =
    StateNotifierProvider<UserNotifier, AsyncValue<UserModel?>>((ref) {
  return UserNotifier(ref); // Kirim ref ke Notifier
});

class UserNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final Ref _ref; // Simpan ref

  // ✨ PERBAIKAN 2: Konstruktor aktif yang langsung memeriksa sesi
  UserNotifier(this._ref) : super(const AsyncValue.loading()) {
    _initializeUser(); // Panggil fungsi pengecekan
  }

  // ✨ PERBAIKAN 3: Fungsi baru untuk pengecekan sesi awal
  Future<void> _initializeUser() async {
    try {
      final account = Account(_ref.read(appwriteClientProvider));
      final appwriteUser = await account.get();
      final userModel = UserModel.fromAppwriteUser(appwriteUser);
      state = AsyncValue.data(userModel);
    } on AppwriteException catch (e, st) {
      // Jika error karena belum login, set state ke data(null)
      if (e.type == 'user_unauthorized') {
        state = const AsyncValue.data(null);
      } else {
        // Jika error lain, set state ke error
        state = AsyncValue.error(e, st);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void setUser(models.User appwriteUser) {
    final userModel = UserModel.fromAppwriteUser(appwriteUser);
    state = AsyncValue.data(userModel);
  }
  
  void clearUser() {
    state = const AsyncValue.data(null);
  }

  // ... Sisa method (updateUser, updateUserRole, dll) tidak perlu diubah ...
  
  void updateUserRole(String role) {
    state.whenData((user) {
      if (user != null) {
        final updatedUser = user.copyWith(
          role: role,
          prefs: {...user.prefs, 'role': role},
        );
        state = AsyncValue.data(updatedUser);
      }
    });
  }
}

// Sisa kode di bawah (convenience providers, extension) tidak perlu diubah
// ...