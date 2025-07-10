import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../utils/appwrite_client.dart';

enum PropertyFetchMode {
  ownerOnly,      // Untuk pemilik kontrakan
  availableOnly,  // Untuk penyewa (lihat properti tersedia)
}

class PropertyNotifier extends StateNotifier<AsyncValue<List<Document>>> {
  PropertyNotifier(this.ref)
      : _db = Databases(ref.read(appwriteClientProvider)),
        _account = Account(ref.read(appwriteClientProvider)),
        super(const AsyncLoading());

  final Ref ref;
  final Databases _db;
  final Account _account;

  final String databaseId = '684d0e3c0039eb16c09d';
  final String collectionId = 'properti';

  PropertyFetchMode fetchMode = PropertyFetchMode.ownerOnly;

  /// Ambil properti berdasarkan mode (pemilik atau penyewa)
  Future<void> fetchProperties({PropertyFetchMode? mode}) async {
    try {
      if (mode != null) fetchMode = mode;

      List<Document> documents = [];

      if (fetchMode == PropertyFetchMode.ownerOnly) {
        final user = await _account.get();
        final userId = user.$id;

        final response = await _db.listDocuments(
          databaseId: databaseId,
          collectionId: collectionId,
          queries: [Query.equal('pemilik_id', userId)],
        );

        documents = response.documents;
      } else {
        final response = await _db.listDocuments(
          databaseId: databaseId,
          collectionId: collectionId,
          queries: [Query.equal('status', 'Tersedia')],
        );

        documents = response.documents;
      }

      state = AsyncData(documents);
    } catch (e, st) {
      state = AsyncError(_handleError(e), st);
    }
  }

  /// Tambah properti baru oleh pemilik
  Future<void> addProperty(Map<String, dynamic> data) async {
    try {
      final user = await _account.get();
      final userId = user.$id;

      data['pemilik_id'] = userId;

      final newDoc = await _db.createDocument(
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

      state = state.whenData((existingDocs) => [newDoc, ...existingDocs]);
    } catch (e, st) {
      state = AsyncError(_handleError(e), st);
    }
  }

  /// Update properti
  Future<void> updateProperty(String id, Map<String, dynamic> data) async {
    try {
      await _db.updateDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: id,
        data: data,
      );

      await fetchProperties(mode: fetchMode);
    } catch (e, st) {
      state = AsyncError(_handleError(e), st);
    }
  }

  /// Hapus properti
  Future<void> deleteProperty(String id, $id) async {
    try {
      await _db.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: id,
      );

      state = state.whenData((docs) =>
          docs.where((doc) => doc.$id != id).toList());
    } catch (e, st) {
      state = AsyncError(_handleError(e), st);
    }
  }

  /// Ubah status properti antara 'Tersedia' dan 'Disewa'
  Future<void> toggleStatus(String id, String currentStatus) async {
    final newStatus = currentStatus == 'Tersedia' ? 'Disewa' : 'Tersedia';

    try {
      await _db.updateDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: id,
        data: {'status': newStatus},
      );

      await fetchProperties(mode: fetchMode);
    } catch (e, st) {
      state = AsyncError(_handleError(e), st);
    }
  }

  /// Fungsi bantuan untuk mengekstrak pesan error dari AppwriteException
  String _handleError(Object error) {
    if (error is AppwriteException) {
      return error.message ?? 'Terjadi kesalahan dari server';
    }
    return error.toString();
  }

  Future<void> updateStatus({required String docId, required String status}) async {}
}

final propertyListProvider = StateNotifierProvider<PropertyNotifier, AsyncValue<List<Document>>>(
  (ref) => PropertyNotifier(ref),
);
