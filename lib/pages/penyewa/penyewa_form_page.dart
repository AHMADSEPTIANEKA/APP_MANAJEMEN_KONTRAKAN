import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/models.dart';
import '../../providers/penyewa_provider.dart';

class PenyewaFormPage extends ConsumerStatefulWidget {
  const PenyewaFormPage({super.key});

  @override
  ConsumerState<PenyewaFormPage> createState() => _PenyewaFormPageState();
}

class _PenyewaFormPageState extends ConsumerState<PenyewaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _noTelpController = TextEditingController();
  final _emailController = TextEditingController();
  final _alamatController = TextEditingController();
  final _scrollController = ScrollController();

  Document? penyewa;
  bool isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final arg = ModalRoute.of(context)?.settings.arguments;
    if (arg is Document) {
      penyewa = arg;
      _namaController.text = penyewa!.data['nama'] ?? '';
      _noTelpController.text = penyewa!.data['no_telepon'] ?? '';
      _emailController.text = penyewa!.data['email'] ?? '';
      _alamatController.text = penyewa!.data['alamat'] ?? '';
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _namaController.dispose();
    _noTelpController.dispose();
    _emailController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isLoading = true);

    try {
      final data = {
        'nama': _namaController.text,
        'no_telepon': _noTelpController.text,
        'email': _emailController.text,
        'alamat': _alamatController.text,
      };

      final isEdit = penyewa != null;
      if (isEdit) {
        await ref.read(penyewaListProvider.notifier).updatePenyewa(penyewa!.$id, data);
      } else {
        await ref.read(penyewaListProvider.notifier).addPenyewa(data);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Penyewa berhasil diperbarui' : 'Penyewa berhasil ditambahkan'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal: ${e.toString()}'),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    bool required = false,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: '$label${required ? ' *' : ''}',
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
        validator: validator ?? (required ? (value) => value!.isEmpty ? '$label wajib diisi' : null : null),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = penyewa != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Penyewa' : 'Tambah Penyewa Baru'),
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
                  'Informasi Penyewa',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _namaController,
                  label: 'Nama Lengkap',
                  required: true,
                ),
                _buildTextField(
                  controller: _noTelpController,
                  label: 'Nomor Telepon',
                  keyboardType: TextInputType.phone,
                  required: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Wajib diisi';
                    final regex = RegExp(r'^\d{10,15}$');
                    if (!regex.hasMatch(value)) return 'Format tidak valid (10-15 digit)';
                    return null;
                  },
                ),
                _buildTextField(
                  controller: _emailController,
                  label: 'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                _buildTextField(
                  controller: _alamatController,
                  label: 'Alamat',
                  maxLines: 3,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submitForm,
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
                        : Text(
                            isEdit ? 'Simpan Perubahan' : 'Tambah Penyewa',
                            style: const TextStyle(
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