import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../utils/appwrite_client.dart';

final kontrakProvider =
    StateNotifierProvider<KontrakListNotifier, AsyncValue<List<Document>>>(
  (ref) => KontrakListNotifier(ref),
);

class KontrakListNotifier extends StateNotifier<AsyncValue<List<Document>>> {
  final Ref ref;
  late final Databases databases;

  static const String databaseId = '684d0e3c0039eb16c09d'; // ✅ Ganti sesuai Appwrite
  static const String collectionId = 'kontrak'; // ✅ Ganti sesuai koleksi

  KontrakListNotifier(this.ref) : super(const AsyncLoading()) {
    databases = Databases(ref.read(appwriteClientProvider));
    fetchKontrak();
  }

  /// ✅ Ambil semua kontrak
  Future<void> fetchKontrak() async {
    try {
      final res = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
      );
      state = AsyncData(res.documents);
    } catch (e, st) {
      state = AsyncError(e.toString(), st);
    }
  }

  /// ✅ Ambil kontrak milik user (penyewa atau pemilik)
  Future<void> getKontrakByUserId(String userId) async {
    try {
      final res = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
        queries: [
          Query.or([
            Query.equal('penyewa_id', userId),
            Query.equal('pemilik_id', userId),
          ])
        ],
      );
      state = AsyncData(res.documents);
    } catch (e, st) {
      state = AsyncError(e.toString(), st);
    }
  }

  /// ✅ Ambil kontrak berdasarkan properti
  Future<void> getKontrakByPropertiId(String propertiId) async {
    try {
      final res = await databases.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
        queries: [Query.equal('properti_id', propertiId)],
      );
      state = AsyncData(res.documents);
    } catch (e, st) {
      state = AsyncError(e.toString(), st);
    }
  }

  /// ✅ Tambah kontrak baru dan kembalikan ID-nya
  Future<String?> tambahKontrak(Map<String, dynamic> data) async {
    try {
      final response = await databases.createDocument(
  databaseId: databaseId,
  collectionId: collectionId,
  documentId: ID.unique(),
  data: data,
  permissions: [
  Permission.read(Role.any()),
  Permission.write(Role.any()),
  Permission.update(Role.any()),
],

);


      await fetchKontrak();
      return response.$id;
    } catch (e, st) {
      state = AsyncError(e.toString(), st);
      return null;
    }
  }

  /// ✅ Hapus kontrak
  Future<void> deleteKontrak(String id) async {
    try {
      await databases.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: id,
      );
      await fetchKontrak();
    } catch (e, st) {
      state = AsyncError(e.toString(), st);
    }
  }

  /// ✅ Ubah status kontrak
  Future<void> updateStatusKontrak(String id, String statusBaru) async {
    try {
      await databases.updateDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: id,
        data: {'status': statusBaru},
      );
      await fetchKontrak();
    } catch (e, st) {
      state = AsyncError(e.toString(), st);
    }
  }
}
