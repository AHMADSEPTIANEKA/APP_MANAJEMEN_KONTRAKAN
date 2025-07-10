import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/pembayaran_owner_provider.dart';
import '../../services/appwrite_service.dart'; // ⬅️ Pastikan ini diimport

class PembayaranOwnerPage extends ConsumerWidget {
  const PembayaranOwnerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(pembayaranOwnerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pembayaran Penyewa')),
      body: asyncData.when(
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Belum ada pembayaran.'));
          }

          return ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final p = list[index];
              final jumlah = p.data['jumlah'] ?? 0;
              final bulan = p.data['bulan_tagihan'] ?? '-';
              final tanggal = p.data['tanggal'] != null
                  ? DateFormat.yMMMMd('id_ID').format(DateTime.parse(p.data['tanggal']))
                  : '-';
              final penyewaId = p.data['penyewa_id'];

              return FutureBuilder<String>(
                future: AppwriteService.getPenyewaNameByUserId(penyewaId),
                builder: (context, snapshot) {
                  final namaPenyewa = snapshot.data ?? penyewaId;

                  return ListTile(
                    title: Text('Rp $jumlah - $bulan'),
                    subtitle: Text('Tanggal Bayar: $tanggal\nPenyewa: $namaPenyewa'),
                    trailing: Chip(
                      label: Text(p.data['status'] ?? 'Belum'),
                      backgroundColor: (p.data['status'] == 'Lunas')
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
