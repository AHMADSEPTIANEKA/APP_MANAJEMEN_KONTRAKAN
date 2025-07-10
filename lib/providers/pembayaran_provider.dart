import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart' as models;
import 'package:app_kontrakan/providers/user_provider.dart';
import '../services/appwrite_service.dart';
// ignore: unused_import
import 'auth_provider.dart';

final pembayaranProvider = FutureProvider<List<models.Document>>((ref) async {
  final userAsync = ref.watch(userProvider);

  final user = userAsync.value;
  if (user == null) {
    throw Exception('User belum login');
  }

  final userId = user.id; // ✅ pakai 'id' dari UserModel

  final database = AppwriteService.database;
  final databaseId = AppwriteService.databaseId;
  final collectionId = AppwriteService.pembayaranCollectionId;

  final result = await database.listDocuments(
    databaseId: databaseId,
    collectionId: collectionId,
    queries: [
      Query.equal('penyewa_id', userId),
      Query.orderDesc('\$createdAt'),
    ],
  );

  return result.documents;
});
