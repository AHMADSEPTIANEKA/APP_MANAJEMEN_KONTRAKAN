// ignore_for_file: unused_local_variable, avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import '../utils/appwrite_client.dart';

final permintaanSewaProvider =
    StateNotifierProvider<PermintaanSewaNotifier, AsyncValue<List<Document>>>(
  (ref) => PermintaanSewaNotifier(ref),
);

class PermintaanSewaNotifier extends StateNotifier<AsyncValue<List<Document>>> {
  final Ref ref;
  late final Databases db;
  final String databaseId = '684d0e3c0039eb16c09d'; // Ganti sesuai Appwrite-mu
  final String collectionId = '686a7cc0000f4fcbba1f'; // Ganti sesuai Appwrite-mu

  PermintaanSewaNotifier(this.ref) : super(const AsyncLoading()) {
    final client = ref.read(appwriteClientProvider);
    db = Databases(client);
    fetchPermintaanSewaMasuk(); // Ambil data saat init
  }

  Future<void> fetchPermintaanSewaMasuk() async {
    state = const AsyncLoading();
    try {
      final account = Account(ref.read(appwriteClientProvider));
      final user = await account.get();

      final response = await db.listDocuments(
        databaseId: databaseId,
        collectionId: collectionId,
        queries: [
          Query.equal('pemilik_id', user.$id),
          Query.orderDesc('\$createdAt'),
        ],
      );

      state = AsyncValue.data(response.documents);
    } catch (e, st) {
      print("--- GAGAL MENGAMBIL DATA PERMINTAAN ---");
      print("PESAN ERROR: $e");
      print("STACK TRACE: $st");
      state = AsyncValue.error('Gagal mengambil permintaan: $e', st);
    }
  }

  Future<void> tambahPermintaan(Map<String, dynamic> data) async {
    try {
      final account = Account(ref.read(appwriteClientProvider));
      final user = await account.get();

      final penyewaId = data['penyewa_id']?.toString();
      final pemilikId = data['pemilik_id']?.toString();

      if (penyewaId == null || pemilikId == null) {
        throw Exception('ID penyewa atau pemilik tidak boleh kosong!');
      }

      print("🧑 Login sebagai: ${user.$id}");
      print("📦 Membuat permintaan sewa:");
      print("    Penyewa ID: $penyewaId");
      print("    Pemilik ID: $pemilikId");

      final newDocument = await db.createDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: ID.unique(),
        data: data,
        permissions: [
  Permission.read(Role.any()),
  Permission.update(Role.any()),
  Permission.delete(Role.any()),
],



      );

      print("✅ Dokumen berhasil dibuat: ${newDocument.$id}");
    } catch (e) {
      print("⛔ Gagal membuat dokumen: $e");
      rethrow;
    }
  }

  Future<void> updateStatus(String documentId, String statusBaru) async {
    final previousState = state.value ?? [];
    state = AsyncValue.data([
      for (final doc in previousState)
        if (doc.$id == documentId)
          Document(
            $id: doc.$id,
            $collectionId: doc.$collectionId,
            $databaseId: doc.$databaseId,
            $createdAt: doc.$createdAt,
            $updatedAt: DateTime.now().toIso8601String(),
            $permissions: doc.$permissions,
            data: {...doc.data, 'status': statusBaru},
          )
        else
          doc,
    ]);

    try {
      await db.updateDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId,
        data: {'status': statusBaru},
      );
    } catch (e) {
      state = AsyncValue.data(previousState);
      print("❌ Gagal update status: $e");
      rethrow;
    }
  }

  Future<void> hapusPermintaan(String documentId) async {
    final previousState = state.value ?? [];
    state = AsyncValue.data(
        previousState.where((doc) => doc.$id != documentId).toList());

    try {
      await db.deleteDocument(
        databaseId: databaseId,
        collectionId: collectionId,
        documentId: documentId,
      );
    } catch (e) {
      state = AsyncValue.data(previousState);
      print("❌ Gagal hapus permintaan: $e");
      rethrow;
    }
  }
}
