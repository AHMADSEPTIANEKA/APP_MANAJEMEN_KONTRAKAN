import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/penyewa_provider.dart';

class PenyewaListPage extends ConsumerWidget {
  const PenyewaListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final penyewaAsync = ref.watch(penyewaListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Penyewa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => Navigator.pushNamed(context, '/penyewa-form'),
          ),
        ],
      ),
      body: penyewaAsync.when(
        data: (list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (context, index) {
            final penyewa = list[index];
            return ListTile(
              title: Text(penyewa.data['nama'] ?? '-'),
              subtitle: Text(penyewa.data['no_telepon'] ?? '-'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/penyewa-form',
                    arguments: penyewa,
                  );
                },
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}
