// lib/pages/pembayaran/riwayat_pembayaran_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
// ignore: unused_import
import 'package:appwrite/models.dart' as models;

import '../../providers/pembayaran_provider.dart';

class RiwayatPembayaranPage extends ConsumerWidget {
  const RiwayatPembayaranPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pembayaranAsync = ref.watch(pembayaranProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Pembayaran')),
      body: pembayaranAsync.when(
        data: (pembayaranList) {
          if (pembayaranList.isEmpty) {
            return const Center(child: Text('Belum ada pembayaran.'));
          }

          return ListView.builder(
            itemCount: pembayaranList.length,
            itemBuilder: (context, index) {
              final doc = pembayaranList[index];
              final data = doc.data;
              final tanggal = DateFormat('dd MMM yyyy').format(
                DateTime.parse(data['tanggal']),
              );
              final jumlah = NumberFormat.currency(locale: 'id', symbol: 'Rp ').format(data['jumlah']);
              final bulanTagihan = data['bulan_tagihan'] ?? '-';
              final status = data['status'] ?? '-';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text('Bulan Tagihan: $bulanTagihan'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tanggal: $tanggal'),
                      Text('Jumlah: $jumlah'),
                      Text('Status: ${status.toString().toUpperCase()}'),
                    ],
                  ),
                  leading: const Icon(Icons.payment, color: Colors.green),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Gagal memuat data: $e')),
      ),
    );
  }
}
