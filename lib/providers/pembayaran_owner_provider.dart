import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/models.dart' as models;
import 'package:app_kontrakan/providers/user_provider.dart';
import 'package:app_kontrakan/services/appwrite_service.dart';
import 'package:appwrite/appwrite.dart';

final pembayaranOwnerProvider = FutureProvider<List<models.Document>>((ref) async {
  final userAsync = ref.watch(userProvider);
  final user = userAsync.value;

  if (user == null) {
    throw Exception('User belum login');
  }

  final database = AppwriteService.database;
  final databaseId = AppwriteService.databaseId;

  // ✅ Step 1: Ambil semua properti milik user (pemilik_id)
  final propertiResult = await database.listDocuments(
    databaseId: databaseId,
    collectionId: AppwriteService.propertiCollectionId,
    queries: [Query.equal('pemilik_id', user.id)],
  );
  final propertiIds = propertiResult.documents.map((e) => e.$id).toList();

  if (propertiIds.isEmpty) return [];

  // ✅ Step 2: Ambil semua kontrak berdasarkan properti_id
  final kontrakResult = await database.listDocuments(
  databaseId: databaseId,
  collectionId: AppwriteService.kontrakCollectionId,
  queries: [
    // ignore: unnecessary_to_list_in_spreads
    ...propertiIds.map((id) => Query.equal('properti_id', id)).toList(),
  ],
);

  final kontrakIds = kontrakResult.documents.map((e) => e.$id).toList();

  if (kontrakIds.isEmpty) return [];

  // ✅ Step 3: Ambil pembayaran berdasarkan kontrak_id
  final pembayaranResult = await database.listDocuments(
  databaseId: databaseId,
  collectionId: AppwriteService.pembayaranCollectionId,
  queries: [
    // ignore: unnecessary_to_list_in_spreads
    ...kontrakIds.map((id) => Query.equal('kontrak_id', id)).toList(),
    Query.orderDesc('\$createdAt'),
  ],
);

  return pembayaranResult.documents;
});
