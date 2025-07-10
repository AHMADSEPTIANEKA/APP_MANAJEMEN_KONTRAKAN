// ignore_for_file: use_build_context_synchronously

import 'dart:io' show File;
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:file_picker/file_picker.dart';
// ignore: unused_import
import 'package:intl/intl.dart';

import '../../../utils/appwrite_client.dart';
import '../../providers/property_provider.dart';
import '../../providers/user_provider.dart';

class AddPropertyPage extends ConsumerStatefulWidget {
  final Future<void> Function()? onPropertyAdded;

  const AddPropertyPage({super.key, this.onPropertyAdded});

  @override
  ConsumerState<AddPropertyPage> createState() => _AddPropertyPageState();
}

class _AddPropertyPageState extends ConsumerState<AddPropertyPage> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();

  final namaController = TextEditingController();
  final lokasiController = TextEditingController();
  final hargaController = TextEditingController();
  final deskripsiController = TextEditingController();
  final kamarController = TextEditingController();
  final kamarMandiController = TextEditingController();
  final luasBangunanController = TextEditingController();
  final luasTanahController = TextEditingController();
  final fasilitasController = TextEditingController();

  File? selectedImage;
  Uint8List? webImageBytes;
  String? webImageName;

  bool isLoading = false;

  @override
  void dispose() {
    _scrollController.dispose();
    namaController.dispose();
    lokasiController.dispose();
    hargaController.dispose();
    deskripsiController.dispose();
    kamarController.dispose();
    kamarMandiController.dispose();
    luasBangunanController.dispose();
    luasTanahController.dispose();
    fasilitasController.dispose();
    super.dispose();
  }

  Future<void> pilihGambar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: kIsWeb,
    );

    if (result != null) {
      if (kIsWeb) {
        setState(() {
          webImageBytes = result.files.first.bytes;
          webImageName = result.files.first.name;
        });
      } else {
        final filePath = result.files.first.path;
        if (filePath != null) {
          setState(() => selectedImage = File(filePath));
        }
      }
    }
  }

  Future<String?> uploadGambar() async {
    final client = ref.read(appwriteClientProvider);
    final storage = Storage(client);
    final fileId = ID.unique();

    try {
      if (kIsWeb && webImageBytes != null) {
        final result = await storage.createFile(
          bucketId: '684d44ab0032f0e00584',
          fileId: fileId,
          file: InputFile.fromBytes(
            bytes: webImageBytes!,
            filename: webImageName ?? 'gambar_web.jpg',
          ),
        );
        return result.$id;
      } else if (selectedImage != null) {
        final result = await storage.createFile(
          bucketId: '684d44ab0032f0e00584',
          fileId: fileId,
          file: InputFile.fromPath(path: selectedImage!.path),
        );
        return result.$id;
      }
    } catch (e) {
      debugPrint('Upload gambar gagal: $e');
      return null;
    }

    return null;
  }

  Future<void> tambahProperti() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final imageFileId = await uploadGambar();

      final user = ref.read(userProvider).maybeWhen(
        data: (u) => u,
        orElse: () => null,
      );

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal: data pengguna tidak ditemukan.')),
          );
        }
        return;
      }

      final newProperty = {
        'nama': namaController.text,
        'lokasi': lokasiController.text,
        'harga_per_bulan': int.tryParse(hargaController.text) ?? 0,
        'status': 'Tersedia',
        'deskripsi': deskripsiController.text,
        'jumlah_kamar': int.tryParse(kamarController.text) ?? 0,
        'jumlah_kamar_mandi': int.tryParse(kamarMandiController.text) ?? 0,
        'luas_bangunan': int.tryParse(luasBangunanController.text) ?? 0,
        'luas_tanah': int.tryParse(luasTanahController.text) ?? 0,
        'fasilitas': fasilitasController.text,
        'gambar_url': imageFileId ?? '',
        'tanggal_dibuat': DateTime.now().toUtc().toIso8601String(),
        'pemilik_id': user.id,
        'pemilik_nama': user.name,
      };

      await ref.read(propertyListProvider.notifier).addProperty(newProperty);

      if (mounted) {
        if (widget.onPropertyAdded != null) {
          await widget.onPropertyAdded!();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Properti berhasil ditambahkan!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint('Error tambahProperti: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambah properti: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, [
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  ]) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        validator: (value) => (value == null || value.trim().isEmpty) ? 'Wajib diisi' : null,
      ),
    );
  }

  Widget _buildImagePreview() {
    if (kIsWeb && webImageBytes != null) {
      return Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey.shade100,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.memory(
                webImageBytes!,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: pilihGambar,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Ganti Gambar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => webImageBytes = null),
                  icon: const Icon(Icons.delete_rounded, color: Colors.red),
                  label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    } else if (!kIsWeb && selectedImage != null) {
      return Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey.shade100,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.file(
                selectedImage!,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: pilihGambar,
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text('Ganti Gambar'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => selectedImage = null),
                  icon: const Icon(Icons.delete_rounded, color: Colors.red),
                  label: const Text('Hapus', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.grey.shade100,
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: pilihGambar,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image_rounded,
              size: 48,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan Gambar Properti',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Format: JPG, PNG (Max 5MB)',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Tambah Properti Baru'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      body: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Informasi Dasar',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(namaController, 'Nama Properti'),
                _buildTextField(lokasiController, 'Lokasi'),
                _buildTextField(
                  hargaController,
                  'Harga per Bulan',
                  TextInputType.number,
                ),
                _buildTextField(
                  deskripsiController,
                  'Deskripsi',
                  TextInputType.multiline,
                  3,
                ),
                const SizedBox(height: 24),
                Text(
                  'Detail Properti',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        kamarController,
                        'Jumlah Kamar',
                        TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        kamarMandiController,
                        'Jumlah Kamar Mandi',
                        TextInputType.number,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: _buildTextField(
                        luasBangunanController,
                        'Luas Bangunan (m²)',
                        TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTextField(
                        luasTanahController,
                        'Luas Tanah (m²)',
                        TextInputType.number,
                      ),
                    ),
                  ],
                ),
                _buildTextField(fasilitasController, 'Fasilitas', TextInputType.multiline, 2),
                const SizedBox(height: 24),
                Text(
                  'Foto Properti',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                _buildImagePreview(),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : tambahProperti,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF667EEA),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            'Simpan Properti',
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
    );
  }
}