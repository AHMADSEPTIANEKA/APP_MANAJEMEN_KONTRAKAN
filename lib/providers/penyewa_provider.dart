import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../utils/appwrite_client.dart';

final penyewaListProvider = StateNotifierProvider<PenyewaNotifier, AsyncValue<List<Document>>>(
  (ref) => PenyewaNotifier(ref.read(appwriteClientProvider)),
);

class PenyewaNotifier extends StateNotifier<AsyncValue<List<Document>>> {
  PenyewaNotifier(this.client) : super(const AsyncLoading()) {
    fetchPenyewa();
  }

  final Client client;
  final databaseId = '684d0e3c0039eb16c09d'; // ✅ Ganti sesuai ID Appwrite kamu
  final collectionId = 'penyewa'; // ✅ Ganti sesuai ID Appwrite kamu

  late final Databases db = Databases(client);

  Future<void> fetchPenyewa() async {
    try {
      final result = await db.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
      );
      state = AsyncData(result.documents);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> addPenyewa(Map<String, dynamic> data) async {
  try {
    final account = Account(client);
    final user = await account.get(); // Ambil data user login
    final userId = user.$id;

    await db.createDocument(
      databaseId: databaseId,
      collectionId: collectionId,
      documentId: ID.unique(),
      data: data,
      permissions: [
  Permission.read(Role.any()),
  Permission.update(Role.user(userId)),
  Permission.delete(Role.user(userId)),
],
    );

    await fetchPenyewa();
  } catch (e, st) {
    state = AsyncError(e, st);
  }
}


  Future<void> updatePenyewa(String id, Map<String, dynamic> data) async {
    try {
      await db.updateDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: id,
        data: data,
      );
      await fetchPenyewa();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> deletePenyewa(String id) async {
    try {
      await db.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: id,
      );
      await fetchPenyewa();
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}
