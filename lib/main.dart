import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/app/routes.dart';
import 'package:sipintar/core/theme/app_theme.dart';
import 'package:sipintar/data/data.dart';

void main() {
  // Inisialisasi state management dan data store aplikasi
  final settingsStore = SettingsStore();
  final auditStore = AuditStore();
  final authStore = AuthStore(auditStore);
  final notificationStore = NotificationStore();
  final inventoryStore = InventoryStore(authStore, auditStore);
  final consumableStore = ConsumableStore(authStore, auditStore, notificationStore);
  final loanStore = LoanStore(authStore, auditStore, notificationStore, inventoryStore, settingsStore);
  final chatStore = ChatStore(authStore, inventoryStore, consumableStore, loanStore);
  final cartStore = CartStore();
  final reviewStore = ReviewStore();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: settingsStore),
        ChangeNotifierProvider.value(value: auditStore),
        ChangeNotifierProvider.value(value: authStore),
        ChangeNotifierProvider.value(value: notificationStore),
        ChangeNotifierProvider.value(value: inventoryStore),
        ChangeNotifierProvider.value(value: consumableStore),
        ChangeNotifierProvider.value(value: loanStore),
        ChangeNotifierProvider.value(value: chatStore),
        ChangeNotifierProvider.value(value: cartStore),
        ChangeNotifierProvider.value(value: reviewStore),
      ],
      child: const SipintarApp(),
    ),
  );
}

/// Konfigurasi perilaku scroll agar mendukung multi-input: Touchscreen, Mouse, dan Trackpad.
/// Sangat penting saat dijalankan di Flutter Web (desktop browser) maupun perangkat Mobile.
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad,
      };
}

/// Root Widget Aplikasi InventarisMuhamka
class SipintarApp extends StatelessWidget {
  const SipintarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Judul pada tab browser / window desktop
      title: 'InventarisMuhamka | Sistem Inventaris dan Peminjaman Sekolah',
      debugShowCheckedModeBanner: false,
      scrollBehavior: _AppScrollBehavior(),
      
      // Tema Resmi Desain Sekolah (Material 3: Navy Blue #0B2A5B & Gold #F59E0B)
      theme: AppTheme.light,
      
      // Lokalisasi Bahasa Indonesia (Format tanggal, waktu, dan kalender)
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('id', 'ID'), 
        Locale('en', 'US'),
      ],
      locale: const Locale('id', 'ID'),
      
      // Pengaturan Routing Dinamis (Deep Linking & Session Handling)
      onGenerateInitialRoutes: (initialRoute) {
        return [
          AppRoutes.generate(RouteSettings(name: initialRoute)),
        ];
      },
      onGenerateRoute: AppRoutes.generate,
    );
  }
}
