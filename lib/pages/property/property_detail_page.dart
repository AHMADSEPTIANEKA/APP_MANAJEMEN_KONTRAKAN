// ignore_for_file: unrelated_type_equality_checks, unnecessary_underscores

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:intl/intl.dart';

import '../../providers/property_provider.dart';
import '../../providers/user_provider.dart';
import '../../utils/appwrite_client.dart';

class PropertyDetailPage extends ConsumerWidget {
  final Document property;

  const PropertyDetailPage({super.key, required this.property});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = property.data;
    final role = ref.watch(userProvider);
    final nama = data['nama'] ?? 'Tanpa Nama';
    final lokasi = data['lokasi'] ?? '-';
    final harga = data['harga_per_bulan']?.toString() ?? '0';
    final status = data['status'] ?? 'Tersedia';
    final jumlahKamar = data['jumlah_kamar']?.toString() ?? '-';
    final jumlahKamarMandi = data['jumlah_kamar_mandi']?.toString() ?? '-';
    final luasBangunan = data['luas_bangunan']?.toString() ?? '-';
    final luasTanah = data['luas_tanah']?.toString() ?? '-';
    final fasilitas = data['fasilitas'] ?? '-';
    final deskripsi = data['deskripsi'] ?? '-';
    final tanggalDibuat = data['tanggal_dibuat'] != null
        ? DateFormat('dd MMM yyyy, HH:mm').format(DateTime.parse(data['tanggal_dibuat']))
        : '-';

    final gambarId = data['gambar_url'];
    const bucketId = '684d44ab0032f0e00584'; // ganti dengan bucket ID kamu
    const projectId = '684bd5b80002c683fadf'; // ganti dengan project ID kamu

    final gambarUrl = (gambarId != null && gambarId.toString().trim().isNotEmpty)
        ? 'https://cloud.appwrite.io/v1/storage/buckets/$bucketId/files/$gambarId/view?project=$projectId'
        : null;

    final isAvailable = status == 'Tersedia';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Properti'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gambar properti
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: gambarUrl != null
                  ? Image.network(
                      gambarUrl,
                      height: 220,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(child: Text('Gagal memuat gambar')),
                    )
                  : Container(
                      height: 220,
                      color: Colors.grey[300],
                      child: const Center(child: Icon(Icons.image_not_supported_outlined, size: 40)),
                    ),
            ),
            const SizedBox(height: 16),
            Text(
              nama,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.grey),
                const SizedBox(width: 4),
                Text(lokasi, style: const TextStyle(fontSize: 14, color: Colors.black87)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Rp ${NumberFormat('#,###').format(int.tryParse(harga.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0)}/bulan',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.blue),
            ),

            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _infoTile(Icons.check_circle, 'Status', status),
                    _infoTile(Icons.bed, 'Kamar Tidur', jumlahKamar),
                    _infoTile(Icons.bathtub, 'Kamar Mandi', jumlahKamarMandi),
                    _infoTile(Icons.square_foot, 'Luas Bangunan', '$luasBangunan m²'),
                    _infoTile(Icons.park, 'Luas Tanah', '$luasTanah m²'),
                    _infoTile(Icons.event, 'Tanggal Dibuat', tanggalDibuat),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            if (fasilitas != '-')
              _sectionText('Fasilitas', fasilitas),
            if (deskripsi != '-')
              _sectionText('Deskripsi', deskripsi),

            const SizedBox(height: 24),

            // Tombol Aksi
            if (role == 'owner')
              ElevatedButton.icon(
                onPressed: () => _showDeleteDialog(context, ref),
                icon: const Icon(Icons.delete),
                label: const Text('Hapus Properti'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

            if (role == 'renter' && isAvailable)
              ElevatedButton.icon(
                onPressed: () async {
                  await _sewaProperti(context, ref);
                },
                icon: const Icon(Icons.shopping_cart_checkout),
                label: const Text('Sewa Sekarang'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.indigo),
          const SizedBox(width: 10),
          Text('$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }

  Widget _sectionText(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(content),
        const SizedBox(height: 16),
      ],
    );
  }

  Future<void> _sewaProperti(BuildContext context, WidgetRef ref) async {
    final client = ref.read(appwriteClientProvider);
    final databases = Databases(client);
    final account = Account(client);

    try {
      final user = await account.get();
      final userId = user.$id;

      await databases.updateDocument(
        databaseId: '684d0e3c0039eb16c09d',
        collectionId: 'properti',
        documentId: property.$id,
        data: {
          'status': 'Disewa',
          'penyewa_id': userId,
          'tanggal_disewa': DateTime.now().toUtc().toIso8601String(),
        },
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Properti berhasil disewa!')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyewa properti: $e')),
        );
      }
    }
  }

  Future<void> _showDeleteDialog(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: const Text('Yakin ingin menghapus properti ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ref.read(propertyListProvider.notifier).deleteProperty(
        property.$id,
        property.data['gambar_url'],
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Properti berhasil dihapus')),
        );
        Navigator.pop(context);
      }
    }
  }
}
