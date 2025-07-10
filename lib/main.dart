import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart'; // Untuk Document
import 'package:intl/date_symbol_data_local.dart'; // 

// Appwrite Client
import 'utils/appwrite_client.dart';

// Auth Pages
import 'auth/login_page.dart';
import 'auth/register_page.dart';
import 'auth/forgot_password_page.dart';
import 'auth/reset_password_page.dart';

// Shared Pages
import 'pages/shared/splash_screen.dart';

// Home
import 'pages/home/home_owner_page.dart';
import 'pages/home/home_renter_page.dart';

// Property
import 'pages/property/add_property_page.dart';
import 'pages/property/edit_property_page.dart';
import 'pages/property/property_detail_page.dart';
import 'pages/property/explore_properties_page.dart';

// Penyewa
import 'pages/penyewa/penyewa_list_page.dart';
import 'pages/penyewa/penyewa_form_page.dart';

// Kontrak
import 'pages/kontrak/kontrak_list_page.dart';
import 'pages/kontrak/kontrak_saya_page.dart';
import 'pages/kontrak/kontrak_form_page.dart' as kontrak_form;
import 'pages/kontrak/permintaan_sewa_page.dart' as permintaan_sewa;

// Pembayaran
import 'pages/pembayaran/pembayaran_form_page.dart';
import 'pages/pembayaran/riwayat_pembayaran_page.dart';
import 'pages/pembayaran/pembayaran_owner_page.dart';
import 'pages/shared/help_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID', null); // ✅ Tambahan penting

  final client = Client()
    ..setEndpoint('https://cloud.appwrite.io/v1')
    ..setProject('684bd5b80002c683fadf')
    ..setSelfSigned(status: true);

  runApp(
    ProviderScope(
      overrides: [appwriteClientProvider.overrideWithValue(client)],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kontrakan App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: const SplashScreen(),
      onGenerateRoute: (settings) {
        final uri = Uri.parse(settings.name ?? '');

        // 🔐 Reset Password via email link
        if (uri.path == '/reset-password' &&
            uri.queryParameters.containsKey('userId') &&
            uri.queryParameters.containsKey('secret')) {
          final userId = uri.queryParameters['userId']!;
          final secret = uri.queryParameters['secret']!;
          return MaterialPageRoute(
            builder: (_) => ResetPasswordPage(userId: userId, secret: secret),
          );
        }

        // Routing berdasarkan path
        switch (uri.path) {
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginPage());

          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterPage());

          case '/forgot-password':
            return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());

          case '/home-owner':
            return MaterialPageRoute(builder: (_) => const HomeOwnerPage());

          case '/home-renter':
            return MaterialPageRoute(builder: (_) => const HomeRenterPage());

          case '/add-property':
            return MaterialPageRoute(builder: (_) => const AddPropertyPage());

            case '/help':
  return MaterialPageRoute(builder: (_) => const HelpPage());


          case '/edit-property':
            final doc = settings.arguments;
            if (doc is Document) {
              return MaterialPageRoute(
                builder: (_) => EditPropertyPage(property: doc),
              );
            }
            return _errorRoute('Data tidak valid untuk edit properti');

          case '/property-detail':
            final doc = settings.arguments;
            if (doc is Document) {
              return MaterialPageRoute(
                builder: (_) => PropertyDetailPage(property: doc),
              );
            }
            return _errorRoute('Data tidak valid untuk detail properti');

          case '/permintaan-sewa':
            return MaterialPageRoute(builder: (_) => const permintaan_sewa.PermintaanSewaPage());

          case '/kontrak-list':
            return MaterialPageRoute(builder: (_) => const KontrakListPage());

          case '/kontrak-saya':
            return MaterialPageRoute(builder: (_) => const KontrakSayaPage());

          case '/kontrak-form':
            final permintaan = settings.arguments;
            if (permintaan is Document) {
              return MaterialPageRoute(
                builder: (_) => kontrak_form.KontrakFormPage(permintaan: permintaan),
              );
            }
            return _errorRoute('Data tidak valid untuk Kontrak');

          case '/penyewa-list':
            return MaterialPageRoute(builder: (_) => const PenyewaListPage());

          case '/penyewa-form':
          case '/add-penyewa':
            return MaterialPageRoute(builder: (_) => const PenyewaFormPage());

          case '/explore-properties':
            return MaterialPageRoute(builder: (_) => const ExplorePropertiesPage());

          case '/riwayat-pembayaran':
            return MaterialPageRoute(builder: (_) => const RiwayatPembayaranPage());

          case '/pembayaran-saya':
            final args = settings.arguments;
            // ignore: avoid_print
            print('🔍 ARGS PEMBAYARAN: $args');
            if (args is Map<String, dynamic> &&
                args['kontrakId'] != null &&
                args['jumlah'] != null &&
                args['penyewaId'] != null) {
              return MaterialPageRoute(
                builder: (_) => PembayaranFormPage(
                  kontrakId: args['kontrakId'],
                  jumlah: args['jumlah'],
                  penyewaId: args['penyewaId'],
                ),
              );
            } else {
              return MaterialPageRoute(
                builder: (_) => const Scaffold(
                  body: Center(child: Text('❌ Data pembayaran tidak valid')),
                ),
              );
            }

          case '/pembayaran-owner':
            return MaterialPageRoute(builder: (_) => const PembayaranOwnerPage());

          default:
            return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
      },
    );
  }

  static MaterialPageRoute _errorRoute(String message) {
    return MaterialPageRoute(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(child: Text(message)),
      ),
    );
  }
}
