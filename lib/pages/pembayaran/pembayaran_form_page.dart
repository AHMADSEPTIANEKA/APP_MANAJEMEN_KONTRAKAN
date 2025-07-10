// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:intl/intl.dart';
import '../../services/appwrite_service.dart';

class PembayaranFormPage extends ConsumerStatefulWidget {
  final String kontrakId;
  final int jumlah;
  final String penyewaId;

  const PembayaranFormPage({
    super.key,
    required this.kontrakId,
    required this.jumlah,
    required this.penyewaId,
  });

  @override
  ConsumerState<PembayaranFormPage> createState() => _PembayaranFormPageState();
}

class _PembayaranFormPageState extends ConsumerState<PembayaranFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _jumlahController = TextEditingController();
  String? _selectedMonth;
  List<String> bulanTagihanList = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _jumlahController.text = widget.jumlah.toString();
    _generateBulanTagihan();
    _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
  }

  void _generateBulanTagihan() {
    final now = DateTime.now();
    bulanTagihanList = List.generate(12, (i) {
      final date = DateTime(now.year, i + 1, 1);
      return DateFormat('yyyy-MM').format(date);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Tambah Pembayaran'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Form Pembayaran',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Bulan Tagihan Dropdown
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bulan Tagihan',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: DropdownButtonFormField<String>(
                                value: _selectedMonth,
                                items: bulanTagihanList
                                    .map((month) => DropdownMenuItem(
                                          value: month,
                                          child: Text(month),
                                        ))
                                    .toList(),
                                onChanged: (val) => setState(() => _selectedMonth = val),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                ),
                                validator: (val) =>
                                    val == null ? 'Pilih bulan tagihan' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        
                        // Jumlah Pembayaran
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Jumlah Pembayaran (Rp)',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _jumlahController,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'Masukkan jumlah',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade300),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Masukkan jumlah';
                                if (int.tryParse(val) == null) return 'Harus berupa angka';
                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // Tombol Simpan
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF4F46E5),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Simpan Pembayaran',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Tombol Riwayat Pembayaran
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final database = AppwriteService.database;

      // Cek pembayaran duplikat
      final check = await database.listDocuments(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.pembayaranCollectionId,
        queries: [
          Query.equal('penyewa_id', widget.penyewaId),
          Query.equal('kontrak_id', widget.kontrakId),
          Query.equal('bulan_tagihan', _selectedMonth),
        ],
      );

      if (check.documents.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Pembayaran bulan $_selectedMonth sudah dilakukan.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _loading = false);
        return;
      }

      // Simpan pembayaran baru
      await database.createDocument(
        databaseId: AppwriteService.databaseId,
        collectionId: AppwriteService.pembayaranCollectionId,
        documentId: ID.unique(),
        data: {
          'penyewa_id': widget.penyewaId,
          'kontrak_id': widget.kontrakId,
          'jumlah': int.parse(_jumlahController.text),
          'bulan_tagihan': _selectedMonth!,
          'tanggal': DateTime.now().toIso8601String(),
          'status': 'lunas',
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pembayaran berhasil disimpan'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menyimpan pembayaran: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }
}