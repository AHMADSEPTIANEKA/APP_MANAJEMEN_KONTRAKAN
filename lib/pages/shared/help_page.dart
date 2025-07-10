import 'package:flutter/material.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pusat Bantuan'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          HelpSection(
            question: 'Bagaimana cara mendaftar akun?',
            answer:
                'Buka aplikasi, klik tombol "Daftar", lalu isi data seperti email, nama lengkap, dan kata sandi.',
          ),
          HelpSection(
            question: 'Bagaimana jika saya lupa kata sandi?',
            answer:
                'Klik "Lupa Kata Sandi" di halaman login, lalu masukkan email Anda untuk menerima link reset.',
          ),
          HelpSection(
            question: 'Bagaimana cara menyewa properti?',
            answer:
                'Buka halaman properti, pilih properti yang diinginkan, lalu klik tombol "Ajukan Sewa".',
          ),
          HelpSection(
            question: 'Apakah saya bisa membatalkan sewa?',
            answer:
                'Pembatalan sewa tergantung pada status permintaan dan kebijakan pemilik properti.',
          ),
          HelpSection(
            question: 'Saya mengalami masalah, ke mana saya harus menghubungi?',
            answer:
                'Silakan hubungi admin melalui email: support@kontrakanapp.com atau gunakan tombol "Hubungi Kami" di bawah ini.',
          ),
          SizedBox(height: 24),
          ContactUsButton(),
        ],
      ),
    );
  }
}

class HelpSection extends StatelessWidget {
  final String question;
  final String answer;

  const HelpSection({super.key, required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            answer,
            style: const TextStyle(fontSize: 14),
          ),
        )
      ],
    );
  }
}

class ContactUsButton extends StatelessWidget {
  const ContactUsButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        // Tambahkan aksi seperti membuka email atau halaman kontak
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Fitur hubungi kami belum tersedia.')),
        );
      },
      icon: const Icon(Icons.mail_outline),
      label: const Text('Hubungi Kami'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
