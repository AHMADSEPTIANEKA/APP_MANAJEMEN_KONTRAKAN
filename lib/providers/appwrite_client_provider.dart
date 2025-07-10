import 'package:appwrite/appwrite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Ganti nilai di bawah ini dengan kredensial dari project Appwrite Anda
const String appwriteEndpoint = 'https://cloud.appwrite.io/v1'; // Biarkan jika pakai Appwrite Cloud
const String appwriteProjectId = '684bd5b80002c683fadf'; // <-- GANTI DENGAN PROJECT ID ANDA

/// Provider global untuk instance Appwrite Client.
///
/// Ini adalah koneksi utama ke server Appwrite yang akan digunakan
/// oleh semua provider lain di seluruh aplikasi.
final appwriteClientProvider = Provider<Client>((ref) {
  final client = Client();
  client
      .setEndpoint(appwriteEndpoint)
      .setProject(appwriteProjectId)
      // Baris di bawah ini penting jika Anda melakukan development
      // di localhost atau menggunakan IP address.
      .setSelfSigned(status: true); 
      
  return client;
});