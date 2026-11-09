import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/app/routes.dart';
import 'package:sipintar/core/theme/app_theme.dart';
import 'package:sipintar/data/data.dart';

void main() {
  final settings = SettingsStore();
  final audit = AuditStore();
  final auth = AuthStore(audit);
  final notif = NotificationStore();
  final inventory = InventoryStore(auth, audit);
  final consumables = ConsumableStore(auth, audit, notif);
  final loans = LoanStore(auth, audit, notif, inventory, settings);
  final chat = ChatStore(auth, inventory, consumables, loans);
  final cart = CartStore();
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider.value(value: settings),
      ChangeNotifierProvider.value(value: audit),
      ChangeNotifierProvider.value(value: auth),
      ChangeNotifierProvider.value(value: notif),
      ChangeNotifierProvider.value(value: inventory),
      ChangeNotifierProvider.value(value: consumables),
      ChangeNotifierProvider.value(value: loans),
      ChangeNotifierProvider.value(value: chat),
      ChangeNotifierProvider.value(value: cart),
    ],
    child: const SipintarApp(),
  ));
}

class _AppScroll extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.stylus,
        PointerDeviceKind.trackpad
      };
}

class SipintarApp extends StatelessWidget {
  const SipintarApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InventarisMuhamka | Sistem Inventaris dan Peminjaman Sekolah',
      debugShowCheckedModeBanner: false,
      scrollBehavior: _AppScroll(),
      theme: AppTheme.light,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('id', 'ID'), Locale('en', 'US')],
      locale: const Locale('id', 'ID'),
      onGenerateInitialRoutes: (initialRoute) {
        return [
          AppRoutes.generate(RouteSettings(name: initialRoute)),
        ];
      },
      onGenerateRoute: AppRoutes.generate,
    );
  }
}
