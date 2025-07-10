import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';

class AppwriteService {
  static final Client _client = Client()
    ..setEndpoint('https://cloud.appwrite.io/v1') // Ganti sesuai endpoint Appwrite kamu
    ..setProject('684bd5b80002c683fadf') // Ganti sesuai Project ID Appwrite
    ..setSelfSigned(); // Hilangkan jika tidak pakai self-signed certificate

  static final Account account = Account(_client);
  static final Databases database = Databases(_client);

  // ID Database dan Koleksi
  static const String databaseId = '684d0e3c0039eb16c09d';
  static const String penyewaCollectionId = 'penyewa';
  static const String kontrakCollectionId = 'kontrak';
  static const String propertiCollectionId = 'properti';
  static const String pembayaranCollectionId = 'pembayaran';

  // ----------- Autentikasi -----------
  static Future<Session> login(String email, String password) async {
    return await account.createEmailPasswordSession(
      email: email,
      password: password,
    );
  }

  static Future<User> getCurrentUser() async {
    return await account.get();
  }

  static Future<void> logout() async {
    await account.deleteSessions();
  }

  // ----------- CRUD Umum -----------
  static Future<Document> createDocument({
    required String collectionId,
    required Map<String, dynamic> data,
    required String documentId,
  }) async {
    return await database.createDocument(
      databaseId: databaseId,
      collectionId: collectionId,
      documentId: documentId,
      data: data,
    );
  }

  static Future<Document> getDocument({
    required String collectionId,
    required String documentId,
  }) async {
    return await database.getDocument(
      databaseId: databaseId,
      collectionId: collectionId,
      documentId: documentId,
    );
  }

  static Future<List<Document>> listDocuments({
    required String collectionId,
    List<String>? queries,
  }) async {
    final response = await database.listDocuments(
      databaseId: databaseId,
      collectionId: collectionId,
      queries: queries,
    );
    return response.documents;
  }

  static Future<Document> updateDocument({
    required String collectionId,
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    return await database.updateDocument(
      databaseId: databaseId,
      collectionId: collectionId,
      documentId: documentId,
      data: data,
    );
  }

  static Future<void> deleteDocument({
    required String collectionId,
    required String documentId,
  }) async {
    await database.deleteDocument(
      databaseId: databaseId,
      collectionId: collectionId,
      documentId: documentId,
    );
  }

  // ----------- Util Tambahan -----------
  static Future<String> getPenyewaNameByUserId(String userId) async {
  try {
    final result = await database.listDocuments(
      databaseId: databaseId,
      collectionId: penyewaCollectionId,
      queries: [Query.equal('user_id', userId)],
    );

    if (result.documents.isNotEmpty) {
      final doc = result.documents.first;
      return doc.data['nama'] ?? 'Tanpa Nama';
    } else {
      return 'Tidak Diketahui';
    }
  } catch (e) {
    // ignore: avoid_print
    print('❌ Error mengambil nama penyewa dari user_id: $e');
    return 'Tidak Diketahui';
  }
}

}
