import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// ignore: unused_import
import 'package:appwrite/models.dart';
import '../../providers/property_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/permintaan_sewa_provider.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');

class ExplorePropertiesPage extends ConsumerStatefulWidget {
  const ExplorePropertiesPage({super.key});

  @override
  ConsumerState<ExplorePropertiesPage> createState() =>
      _ExplorePropertiesPageState();
}

class _ExplorePropertiesPageState extends ConsumerState<ExplorePropertiesPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref
          .read(propertyListProvider.notifier)
          .fetchProperties(mode: PropertyFetchMode.availableOnly);
    });
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(propertyListProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final userAsync = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF667EEA),
                      Color(0xFF764BA2),
                      Color(0xFF667EEA),
                    ],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.3),
                      ],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.search_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Jelajahi Properti',
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.8,
                                    ),
                                  ),
                                  Text(
                                    'Temukan properti yang sesuai kebutuhan',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: TextField(
                              onChanged: (value) =>
                                  ref.read(searchQueryProvider.notifier).state = value,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Cari properti...',
                                hintStyle: TextStyle(
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                prefixIcon: Icon(
                                  Icons.search_rounded,
                                  color: Colors.white.withOpacity(0.7),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                onPressed: () {
                  ref
                      .read(propertyListProvider.notifier)
                      .fetchProperties(mode: PropertyFetchMode.availableOnly);
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: propertiesAsync.when(
              data: (properties) {
                final filteredProperties = properties.where((property) {
                  final nama = property.data['nama']?.toLowerCase() ?? '';
                  final lokasi = property.data['lokasi']?.toLowerCase() ?? '';
                  final query = searchQuery.toLowerCase();
                  return nama.contains(query) || lokasi.contains(query);
                }).toList();

                if (filteredProperties.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(40),
                    margin: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.home_work_outlined,
                          size: 64,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tidak ada properti tersedia',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          searchQuery.isEmpty
                              ? 'Tidak ada properti yang tersedia saat ini'
                              : 'Tidak ditemukan properti dengan kata kunci "$searchQuery"',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      ...filteredProperties.map((property) {
                        final status = property.data['status'] ?? 'Tersedia';
                        final isAvailable = status == 'Tersedia';
                        final pemilikNama =
                            property.data['pemilik_nama'] ?? 'Tidak diketahui';

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isAvailable
                                        ? Colors.green.shade50
                                        : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.home_work_rounded,
                                    color: isAvailable
                                        ? Colors.green.shade800
                                        : Colors.orange.shade800,
                                  ),
                                ),
                                title: Text(
                                  property.data['nama'] ?? 'Tanpa Nama',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(property.data['lokasi'] ?? 'Lokasi tidak diketahui'),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Pemilik: $pemilikNama',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/property-detail',
                                    arguments: property,
                                  );
                                },
                              ),
                              const Divider(height: 1),
                              if (isAvailable)
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      icon: const Icon(Icons.send_rounded, size: 18),
                                      label: const Text('Ajukan Sewa'),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFF667EEA),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                      ),
                                      onPressed: () async {
                                        if (userAsync is AsyncData && userAsync.value != null) {
                                          final user = userAsync.value!;
                                          final dataPermintaan = {
                                            'properti_id': property.$id,
                                            'properti_nama': property.data['nama'],
                                            'penyewa_id': user.id,
                                            'penyewa_nama': user.name,
                                            'pemilik_id': property.data['pemilik_id'],
                                            'pemilik_nama': property.data['pemilik_nama'],
                                            'status': 'Menunggu',
                                          };

                                          try {
                                            await ref
                                                .read(permintaanSewaProvider.notifier)
                                                .tambahPermintaan(dataPermintaan);

                                            // ignore: use_build_context_synchronously
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: const Text('Permintaan sewa berhasil dikirim'),
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                            );
                                          } catch (e) {
                                            // ignore: use_build_context_synchronously
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text('Gagal mengirim permintaan: $e'),
                                                behavior: SnackBarBehavior.floating,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                              ),
                                            );
                                          }
                                        } else {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text('Anda harus login terlebih dahulu'),
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF667EEA),
                  ),
                ),
              ),
              error: (e, stack) => Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Error: $e',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}