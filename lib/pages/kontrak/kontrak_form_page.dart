// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/models.dart';
import 'package:intl/intl.dart';

import '../../providers/property_provider.dart';
import '../../providers/kontrak_provider.dart';

class KontrakFormPage extends ConsumerStatefulWidget {
  final Document permintaan;

  const KontrakFormPage({super.key, required this.permintaan});

  @override
  ConsumerState<KontrakFormPage> createState() => _KontrakFormPageState();
}

class _KontrakFormPageState extends ConsumerState<KontrakFormPage> {
  final _formKey = GlobalKey<FormState>();

  late Document selectedProperty;

  DateTime? mulai;
  DateTime? akhir;
  int? harga;
  String? catatan;
  bool isLoading = false;

  bool _isInitialized = false;

  String formatTanggal(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final allProperties = ref.read(propertyListProvider).asData?.value ?? [];
      final propertiId = widget.permintaan.data['properti_id'];

      try {
        selectedProperty = allProperties.firstWhere(
          (p) => p.$id == propertiId,
          orElse: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Properti tidak ditemukan')),
            );
            Navigator.pop(context);
            throw Exception('Properti tidak ditemukan');
          },
        );

        setState(() {
          _isInitialized = true;
        });
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final permintaan = widget.permintaan;

    return Scaffold(
      appBar: AppBar(title: const Text('Buat Kontrak')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _isInitialized
            ? Form(
                key: _formKey,
                child: ListView(
                  children: [
                    ListTile(
                      title: const Text('Properti'),
                      subtitle: Text(selectedProperty.data['nama'] ?? ''),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: const Text('Penyewa'),
                      subtitle:
                          Text(permintaan.data['penyewa_nama'] ?? 'Tidak ditemukan'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Harga'),
                      keyboardType: TextInputType.number,
                      onChanged: (val) => harga = int.tryParse(val),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'Wajib isi harga';
                        if (int.tryParse(val) == null) return 'Harus berupa angka';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      title: Text(
                        mulai == null
                            ? 'Pilih Tanggal Mulai'
                            : 'Mulai: ${formatTanggal(mulai)}',
                      ),
                      trailing: const Icon(Icons.date_range),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2030),
                        );
                        if (date != null) setState(() => mulai = date);
                      },
                    ),
                    ListTile(
                      title: Text(
                        akhir == null
                            ? 'Pilih Tanggal Akhir'
                            : 'Akhir: ${formatTanggal(akhir)}',
                      ),
                      trailing: const Icon(Icons.date_range),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate:
                              mulai?.add(const Duration(days: 30)) ?? DateTime.now(),
                          firstDate: DateTime(2024),
                          lastDate: DateTime(2035),
                        );
                        if (date != null) setState(() => akhir = date);
                      },
                    ),
                    TextFormField(
                      decoration:
                          const InputDecoration(labelText: 'Catatan (opsional)'),
                      onChanged: (val) => catatan = val,
                    ),
                    const SizedBox(height: 24),
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    if (!_formKey.currentState!.validate()) return;
                                    if (mulai == null || akhir == null) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text('Tanggal belum lengkap')),
                                      );
                                      return;
                                    }
                                    if (mulai!.isAfter(akhir!)) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                            content: Text(
                                                'Tanggal mulai harus sebelum tanggal akhir')),
                                      );
                                      return;
                                    }

                                    setState(() => isLoading = true);

                                    final kontrakId = await ref
                                        .read(kontrakProvider.notifier)
                                        .tambahKontrak({
                                      'properti_id': selectedProperty.$id,
                                      'properti_nama':
                                          selectedProperty.data['nama'],
                                      'penyewa_id': permintaan.data['penyewa_id'],
                                      'penyewa_nama':
                                          permintaan.data['penyewa_nama'],
                                      'mulai': mulai!.toIso8601String(),
                                      'akhir': akhir!.toIso8601String(),
                                      'harga': harga,
                                      'catatan': catatan ?? '',
                                      'status': 'Aktif',
                                    });

                                    await ref
                                        .read(propertyListProvider.notifier)
                                        .toggleStatus(
                                            selectedProperty.$id, 'Disewa');

                                    if (kontrakId != null && mounted) {
  // ignore: avoid_print
  print('✅ KONTRAK ID: $kontrakId');
  // ignore: avoid_print
  print('✅ ARGS: ${{
    'kontrakId': kontrakId,
    'jumlah': harga!,
    'penyewaId': permintaan.data['penyewa_id'],
  }}');

  Navigator.pushReplacementNamed(
    context,
    '/pembayaran-saya',
    arguments: {
      'kontrakId': kontrakId,
      'jumlah': harga!,
      'penyewaId': permintaan.data['penyewa_id'],
    },
  );
} else {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('❌ Gagal membuat kontrak. Silakan coba lagi.')),
  );
}

                                  },
                                  icon: const Icon(Icons.save),
                                  label: const Text('Simpan Kontrak'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.cancel),
                                label: const Text('Batal'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              )
            : const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}
