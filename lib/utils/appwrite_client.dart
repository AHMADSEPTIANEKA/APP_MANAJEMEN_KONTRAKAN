import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';

// Base Client Provider - akan di-override di main.dart
final appwriteClientProvider = Provider<Client>((ref) {
  throw UnimplementedError('appwriteClientProvider must be overridden in main.dart');
});

// Service Providers yang bergantung pada client
final accountServiceProvider = Provider<Account>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return Account(client);
});

final databaseServiceProvider = Provider<Databases>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return Databases(client);
});

final storageServiceProvider = Provider<Storage>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return Storage(client);
});

final functionsServiceProvider = Provider<Functions>((ref) {
  final client = ref.watch(appwriteClientProvider);
  return Functions(client);
});

// Konstanta untuk konfigurasi
class AppwriteConstants {
  static const String databaseId = '684d0e3c0039eb16c09d';
  static const String userCollectionId = 'your_user_collection_id';
  static const String propertyCollectionId = 'your_property_collection_id';
  static const String bucketId = 'your_bucket_id';
  
  // Tambahkan konstanta lain sesuai kebutuhan
}