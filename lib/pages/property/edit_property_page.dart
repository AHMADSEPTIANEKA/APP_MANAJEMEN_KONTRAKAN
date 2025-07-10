import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import '../../providers/property_provider.dart';
import '../../utils/appwrite_client.dart';

class EditPropertyPage extends ConsumerStatefulWidget {
  final Document property;

  const EditPropertyPage({super.key, required this.property});

  @override
  ConsumerState<EditPropertyPage> createState() => _EditPropertyPageState();
}

class _EditPropertyPageState extends ConsumerState<EditPropertyPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController namaController;
  late TextEditingController lokasiController;
  late TextEditingController hargaController;
  late TextEditingController deskripsiController;
  late TextEditingController kamarController;
  late TextEditingController kamarMandiController;
  late TextEditingController luasBangunanController;
  late TextEditingController luasTanahController;
  late TextEditingController fasilitasController;

  PlatformFile? selectedImageFile;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    final data = widget.property.data;

    namaController = TextEditingController(text: data['nama'] ?? '');
    lokasiController = TextEditingController(text: data['lokasi'] ?? '');
    hargaController = TextEditingController(text: data['harga_per_bulan']?.toString() ?? '');
    deskripsiController = TextEditingController(text: data['deskripsi'] ?? '');
    kamarController = TextEditingController(text: data['jumlah_kamar']?.toString() ?? '');
    kamarMandiController = TextEditingController(text: data['jumlah_kamar_mandi']?.toString() ?? '');
    luasBangunanController = TextEditingController(text: data['luas_bangunan']?.toString() ?? '');
    luasTanahController = TextEditingController(text: data['luas_tanah']?.toString() ?? '');
    fasilitasController = TextEditingController(text: data['fasilitas'] ?? '');
  }

  Future<void> pilihGambar() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
      withData: kIsWeb,
    );

    if (result?.files.single.bytes != null || result?.files.single.path != null) {
      setState(() {
        selectedImageFile = result!.files.single;
      });
    }
  }

  Future<String?> uploadGambar(PlatformFile file) async {
    final client = ref.read(appwriteClientProvider);
    final storage = Storage(client);
    final account = Account(client);
    final user = await account.get();

    final fileId = ID.unique();
    final fileName = p.basename(file.name);

    final permissions = [
      Permission.read(Role.user(user.$id)),
      Permission.update(Role.user(user.$id)),
      Permission.delete(Role.user(user.$id)),
    ];

    if (kIsWeb) {
      return (await storage.createFile(
        bucketId: '684d44ab0032f0e00584',
        fileId: fileId,
        file: InputFile.fromBytes(
          bytes: file.bytes!,
          filename: fileName,
        ),
        permissions: permissions,
      )).$id;
    } else {
      return (await storage.createFile(
        bucketId: '684d44ab0032f0e00584',
        fileId: fileId,
        file: InputFile.fromPath(
          path: file.path!,
          filename: fileName,
        ),
        permissions: permissions,
      )).$id;
    }
  }

  Future<void> simpanPerubahan() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final updatedData = {
        'nama': namaController.text,
        'lokasi': lokasiController.text,
        'harga_per_bulan': int.tryParse(hargaController.text) ?? 0,
        'deskripsi': deskripsiController.text,
        'jumlah_kamar': int.tryParse(kamarController.text) ?? 0,
        'jumlah_kamar_mandi': int.tryParse(kamarMandiController.text) ?? 0,
        'luas_bangunan': int.tryParse(luasBangunanController.text) ?? 0,
        'luas_tanah': int.tryParse(luasTanahController.text) ?? 0,
        'fasilitas': fasilitasController.text,
      };

      if (selectedImageFile != null) {
        final fileId = await uploadGambar(selectedImageFile!);
        if (fileId != null) {
          updatedData['gambar_url'] = fileId;
        }
      }

      await ref.read(propertyListProvider.notifier).updateProperty(
            widget.property.$id,
            updatedData,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Data properti berhasil diperbarui')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menyimpan perubahan: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gambarSekarang = widget.property.data['gambar_url'];

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Properti')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _buildTextField(namaController, 'Nama Properti', true),
              _buildTextField(lokasiController, 'Lokasi', true),
              _buildTextField(hargaController, 'Harga per Bulan', true, TextInputType.number),
              _buildTextField(deskripsiController, 'Deskripsi', false, TextInputType.multiline, 3),
              _buildTextField(kamarController, 'Jumlah Kamar Tidur', false, TextInputType.number),
              _buildTextField(kamarMandiController, 'Jumlah Kamar Mandi', false, TextInputType.number),
              _buildTextField(luasBangunanController, 'Luas Bangunan (m²)', false, TextInputType.number),
              _buildTextField(luasTanahController, 'Luas Tanah (m²)', false, TextInputType.number),
              _buildTextField(fasilitasController, 'Fasilitas (pisahkan dengan koma)', false),

              const SizedBox(height: 16),
              if (gambarSekarang != null && gambarSekarang.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Gambar Saat Ini:'),
                    const SizedBox(height: 8),
                    Image.network(
                      'https://cloud.appwrite.io/v1/storage/buckets/684d44ab0032f0e00584/files/$gambarSekarang/view?project=684bd5b80002c683fadf',
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Text('Gagal memuat gambar'),
                    ),
                  ],
                ),

              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: pilihGambar,
                icon: const Icon(Icons.image),
                label: const Text('Pilih Gambar Baru'),
              ),

              if (selectedImageFile != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Gambar baru dipilih: ${selectedImageFile!.name}'),
                ),

              const SizedBox(height: 24),
              isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: simpanPerubahan,
                      icon: const Icon(Icons.save),
                      label: const Text('Simpan Perubahan'),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    bool required, [
    TextInputType type = TextInputType.text,
    int maxLines = 1,
  ]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: TextFormField(
        controller: controller,
        keyboardType: type,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (value) => value == null || value.trim().isEmpty ? 'Wajib diisi' : null
            : null,
      ),
    );
  }
}
