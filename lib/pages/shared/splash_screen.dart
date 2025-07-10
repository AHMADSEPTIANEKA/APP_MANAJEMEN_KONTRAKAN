// lib/views/splash/splash_screen.dart
// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart'; // Import AppwriteException
import '../../auth/login_page.dart';
import '../home/home_owner_page.dart';
// Pastikan file dan class berikut benar, atau perbaiki namanya jika berbeda
import '../home/home_renter_page.dart';
import '../../providers/user_provider.dart'; // Kita hanya butuh userProvider

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.listen adalah cara yang tepat untuk melakukan aksi (navigasi, snackbar, dll)
    // saat state sebuah provider berubah.
    ref.listen<AsyncValue>(
      userProvider, // Kita cukup dengarkan userProvider
      (previous, next) {
        // next adalah state terbaru dari userProvider
        next.when(
          loading: () {
            // Biarkan saja, UI sudah menampilkan loading
          },
          error: (err, _) {
            // Jika ada error, kita cek apakah itu karena user belum login
            if (err is AppwriteException && err.type == 'user_unauthorized') {
              // Jika ya, arahkan ke halaman login
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            } else {
              // Jika error lain, bisa tampilkan pesan error
              // (Untuk sekarang kita arahkan ke login juga)
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            }
          },
          data: (user) {
            // Jika berhasil mendapatkan data user
            if (user == null) {
              // User null, artinya tidak ada sesi, arahkan ke login
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
              return;
            }

            // Arahkan berdasarkan role
            if (user.role == 'owner') {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeOwnerPage()),
              );
            } else {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const HomeRenterPage()),
              );
            }
          },
        );
      },
    );

    // UI dari SplashScreen hanya perlu menampilkan loading indicator.
    // Logika navigasi sudah ditangani sepenuhnya oleh ref.listen di atas.
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}