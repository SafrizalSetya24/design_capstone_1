import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/app/adaptive_shell.dart';
import 'package:sipintar/app/routes.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/main.dart';
import 'package:sipintar/pages/auth/login_page.dart';
import 'package:sipintar/pages/catalog/item_category_page.dart';
import 'package:sipintar/pages/catalog/item_detail_page.dart';
import 'package:sipintar/pages/history/borrowing_history_page.dart';
import 'package:sipintar/pages/home/home_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

void main() {
  testWidgets('SipintarApp smoke test', (WidgetTester tester) async {
    final settings = SettingsStore();
    final audit = AuditStore();
    final auth = AuthStore(audit);
    final notif = NotificationStore();
    final inventory = InventoryStore(auth, audit);
    final consumables = ConsumableStore(auth, audit, notif);
    final loans = LoanStore(auth, audit, notif, inventory, settings);
    final chat = ChatStore(auth, inventory, consumables, loans);
    final cart = CartStore();

    await tester.pumpWidget(MultiProvider(
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

    expect(find.byType(SipintarApp), findsOneWidget);
  });

  test('AuthStore face registration tracking test', () {
    final audit = AuditStore();
    final auth = AuthStore(audit);

    // Akun dengan wajah sudah terdaftar (contoh: sw1 / siswa@sipintar.id)
    auth.login('siswa@sipintar.id', 'sipintar123');
    expect(auth.isFaceRegistered(), isTrue);

    auth.logout();

    // Akun dengan wajah belum terdaftar (contoh: sw4 / nabila@sipintar.id)
    auth.login('nabila@sipintar.id', 'sipintar123');
    expect(auth.isFaceRegistered(), isFalse);

    // Daftarkan wajah
    auth.setFaceRegistered(true);
    expect(auth.isFaceRegistered(), isTrue);
  });

  test('inventarisMuhamka requirements: 2-hour approval & mixed cart', () {
    final settings = SettingsStore();
    expect(settings.approvalHours, 2, reason: 'Batas approval Sapras adalah 2 jam');

    final cart = CartStore();
    // Tambahkan barang per unit
    cart.addItem(
      itemId: 'it1',
      itemName: 'Laptop ThinkPad',
      kind: ItemKind.perUnit,
      satuan: 'unit',
      iconKey: 'laptop',
      qty: 2,
      maxAvailable: 5,
    );

    // Tambahkan barang habis pakai (Mixed Request)
    cart.addItem(
      itemId: 'hp1',
      itemName: 'Spidol Boardmarker',
      kind: ItemKind.habisPakai,
      satuan: 'pcs',
      iconKey: 'spidol',
      qty: 10,
      maxAvailable: 50,
    );

    expect(cart.itemCount, 2);
    expect(cart.totalQty, 12);
  });

  testWidgets('StatusBadge.status renders all enum types safely without NoSuchMethodError', (tester) async {
    for (final status in LoanStatus.values) {
      expect(status.label, isNotEmpty);
      dynamic dynamicStatus = status;
      expect((dynamicStatus as dynamic).label, equals(status.label));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBadge.status(dynamicStatus),
          ),
        ),
      );
      expect(find.text(status.label), findsOneWidget);
    }

    for (final cond in ItemCondition.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatusBadge.status(cond),
          ),
        ),
      );
      expect(find.text(cond.label), findsOneWidget);
    }
  });

  testWidgets('AdaptiveShell redirects to LoginPage when user logs out', (tester) async {
    final settings = SettingsStore();
    final audit = AuditStore();
    final auth = AuthStore(audit);
    final notif = NotificationStore();
    final inventory = InventoryStore(auth, audit);
    final consumables = ConsumableStore(auth, audit, notif);
    final loans = LoanStore(auth, audit, notif, inventory, settings);
    final chat = ChatStore(auth, inventory, consumables, loans);
    final cart = CartStore();

    // Login siswa sw1
    auth.demoLogin('sw1');

    await tester.pumpWidget(
      MultiProvider(
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
        child: const MaterialApp(
          onGenerateRoute: AppRoutes.generate,
          home: AdaptiveShell(),
        ),
      ),
    );

    // Initial pump
    await tester.pump();

    // Sekarang simulasikan logout
    auth.logout();
    await tester.pumpAndSettle();

    // Memastikan LoginPage tampil dan tidak stuck di blank Scaffold
    expect(find.byType(LoginPage), findsOneWidget);
  });

  test('AuthStore supports login via NIS (Siswa) and NIK (Guru)', () {
    final audit = AuditStore();
    final auth = AuthStore(audit);

    // Login via NIS Siswa
    final errSiswa = auth.login('2024001234', 'sipintar123');
    expect(errSiswa, isNull);
    expect(auth.currentUser?.role, equals(UserRole.siswa));
    expect(auth.currentUser?.name, equals('Rizky Pratama'));

    auth.logout();

    // Login via NIK Guru
    final errGuru = auth.login('3374012345670001', 'sipintar123');
    expect(errGuru, isNull);
    expect(auth.currentUser?.role, equals(UserRole.guru));
    expect(auth.currentUser?.name, equals('Siti Nurhaliza, S.Pd.'));
  });

  testWidgets('LoginPage auto-detects NIS (Siswa) and NIK (Guru) as user types', (tester) async {
    final audit = AuditStore();
    final auth = AuthStore(audit);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
        ],
        child: const MaterialApp(
          home: LoginPage(),
        ),
      ),
    );

    final inputFinder = find.byType(TextFormField).first;

    // Ketik NIS siswa
    await tester.enterText(inputFinder, '2024001234');
    await tester.pump();
    expect(find.textContaining('Siswa: Rizky Pratama'), findsOneWidget);

    // Ketik NIK guru
    await tester.enterText(inputFinder, '3374012345670001');
    await tester.pump();
    expect(find.textContaining('Guru: Siti Nurhaliza'), findsOneWidget);
  });

  testWidgets('LoginPage renders split-screen hero showcase on desktop viewport', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final audit = AuditStore();
    final auth = AuthStore(audit);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
        ],
        child: const MaterialApp(
          home: LoginPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verifikasi Hero Showcase di sebelah kiri
    expect(find.text('SMK MUHAMMADIYAH 1 SUKOHARJO'), findsOneWidget);
    expect(find.text('Biometrik Face Recognition'), findsOneWidget);
    expect(find.text('Dual-Katalog & Mixed Cart'), findsOneWidget);
    expect(find.text('Approval SLA 2 Jam Sarpras'), findsOneWidget);

    // Verifikasi Form di sebelah kanan
    expect(find.text('Masuk Aplikasi'), findsNWidgets(2)); // Header form & PrimaryButton label
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('Test back button on ItemCategoryPage when pushed from HomePage', (tester) async {
    final settings = SettingsStore();
    final audit = AuditStore();
    final auth = AuthStore(audit);
    final notif = NotificationStore();
    final inventory = InventoryStore(auth, audit);
    final consumables = ConsumableStore(auth, audit, notif);
    final loans = LoanStore(auth, audit, notif, inventory, settings);
    final chat = ChatStore(auth, inventory, consumables, loans);
    final cart = CartStore();

    auth.demoLogin('sw1');

    await tester.pumpWidget(
      MultiProvider(
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
        child: const MaterialApp(
          onGenerateRoute: AppRoutes.generate,
          home: AdaptiveShell(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Pastikan HomePage tampil
    expect(find.byType(HomePage), findsOneWidget);

    // Tap "Pinjam Barang"
    final pinjamBarang = find.text('Pinjam Barang');
    expect(pinjamBarang, findsOneWidget);
    await tester.ensureVisible(pinjamBarang);
    await tester.pumpAndSettle();
    await tester.tap(pinjamBarang);
    await tester.pumpAndSettle();

    // Sekarang harus berada di ItemCategoryPage (Katalog Barang)
    expect(find.text('Katalog Barang'), findsOneWidget);

    // Cari back button (IconButton tooltip 'Kembali')
    final backBtn = find.byTooltip('Kembali');
    expect(backBtn, findsOneWidget);

    // Tap back button
    await tester.tap(backBtn);
    await tester.pumpAndSettle();

    // Verifikasi kembali ke HomePage
    expect(find.byType(HomePage), findsOneWidget);
    expect(find.byType(ItemCategoryPage), findsNothing);
  });

  testWidgets('Test ItemCategoryPage on desktop viewport', (tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final settings = SettingsStore();
    final audit = AuditStore();
    final auth = AuthStore(audit);
    final notif = NotificationStore();
    final inventory = InventoryStore(auth, audit);
    final consumables = ConsumableStore(auth, audit, notif);
    final loans = LoanStore(auth, audit, notif, inventory, settings);
    final chat = ChatStore(auth, inventory, consumables, loans);
    final cart = CartStore();

    auth.demoLogin('sw1');

    await tester.pumpWidget(
      MultiProvider(
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
        child: const MaterialApp(
          home: AdaptiveShell(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Pastikan di HomePage
    expect(find.byType(HomePage), findsOneWidget);

    // Tap "Pinjam Barang"
    final pinjamBarang = find.text('Pinjam Barang');
    await tester.ensureVisible(pinjamBarang);
    await tester.tap(pinjamBarang);
    await tester.pumpAndSettle();

    expect(find.byType(ItemCategoryPage), findsOneWidget);
    expect(find.text('Laptop Asus Vivobook 14'), findsOneWidget);
    expect(find.text('Proyektor Epson EB-X06'), findsOneWidget);

    // Switch ke tab Barang Habis Pakai
    await tester.tap(find.text('Barang Habis Pakai'));
    await tester.pumpAndSettle();
    expect(find.text('Kertas HVS A4 80 gr'), findsOneWidget);
    expect(find.text('Spidol Whiteboard Hitam'), findsOneWidget);
  });

  testWidgets('Test ItemCategoryPage on mobile viewport (width 360)', (tester) async {
    tester.view.physicalSize = const Size(360, 740);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final settings = SettingsStore();
    final audit = AuditStore();
    final auth = AuthStore(audit);
    final notif = NotificationStore();
    final inventory = InventoryStore(auth, audit);
    final consumables = ConsumableStore(auth, audit, notif);
    final loans = LoanStore(auth, audit, notif, inventory, settings);
    final chat = ChatStore(auth, inventory, consumables, loans);
    final cart = CartStore();

    auth.demoLogin('sw1');

    await tester.pumpWidget(
      MultiProvider(
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
        child: const MaterialApp(
          home: AdaptiveShell(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap "Pinjam Barang"
    final pinjamBarang = find.text('Pinjam Barang');
    await tester.ensureVisible(pinjamBarang);
    await tester.tap(pinjamBarang);
    await tester.pumpAndSettle();

    expect(find.byType(ItemCategoryPage), findsOneWidget);
    expect(find.text('Laptop Asus Vivobook 14'), findsOneWidget);

    // Switch ke tab Barang Habis Pakai
    await tester.tap(find.text('Barang Habis Pakai'));
    await tester.pumpAndSettle();
    expect(find.text('Kertas HVS A4 80 gr'), findsOneWidget);
  });

  testWidgets('BorrowingHistoryPage renders loans and switches tabs without NoSuchMethodError',
      (WidgetTester tester) async {
    final settings = SettingsStore();
    final audit = AuditStore();
    final auth = AuthStore(audit);
    final notif = NotificationStore();
    final inventory = InventoryStore(auth, audit);
    final consumables = ConsumableStore(auth, audit, notif);
    final loans = LoanStore(auth, audit, notif, inventory, settings);
    final cart = CartStore();

    auth.login('2024001234', 'sipintar123');

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: audit),
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: notif),
          ChangeNotifierProvider.value(value: inventory),
          ChangeNotifierProvider.value(value: consumables),
          ChangeNotifierProvider.value(value: loans),
          ChangeNotifierProvider.value(value: cart),
        ],
        child: const MaterialApp(
          home: BorrowingHistoryPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.byType(BorrowingHistoryPage), findsOneWidget);

    // Switch ke tab Selesai
    await tester.tap(find.textContaining('Selesai'));
    await tester.pumpAndSettle();
    expect(find.byType(BorrowingHistoryPage), findsOneWidget);

    // Switch ke tab Ditolak/Expired
    await tester.tap(find.textContaining('Ditolak/Expired'));
    await tester.pumpAndSettle();
    expect(find.byType(BorrowingHistoryPage), findsOneWidget);
  });

  testWidgets('Test HomePage layout on 1024x575 desktop viewport', (tester) async {
    tester.view.physicalSize = const Size(1024, 575);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final settings = SettingsStore();
    final audit = AuditStore();
    final auth = AuthStore(audit);
    final notif = NotificationStore();
    final inventory = InventoryStore(auth, audit);
    final consumables = ConsumableStore(auth, audit, notif);
    final loans = LoanStore(auth, audit, notif, inventory, settings);
    final chat = ChatStore(auth, inventory, consumables, loans);
    final cart = CartStore();

    auth.demoLogin('sw1');

    await tester.pumpWidget(
      MultiProvider(
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
        child: const MaterialApp(
          home: AdaptiveShell(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byType(HomePage), findsOneWidget);
    expect(find.text('Selamat datang,'), findsOneWidget);
    expect(find.text('Alur Peminjaman Barang (SOP 6 Langkah)'), findsOneWidget);
    expect(find.text('Pinjam Barang'), findsOneWidget);
  });

  testWidgets('ItemDetailPage add to cart shows bottom sheet and updates cart', (tester) async {
    final settings = SettingsStore();
    final audit = AuditStore();
    final auth = AuthStore(audit);
    final notif = NotificationStore();
    final inventory = InventoryStore(auth, audit);
    final consumables = ConsumableStore(auth, audit, notif);
    final loans = LoanStore(auth, audit, notif, inventory, settings);
    final chat = ChatStore(auth, inventory, consumables, loans);
    final cart = CartStore();

    auth.demoLogin('sw1');

    await tester.pumpWidget(
      MultiProvider(
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
        child: MaterialApp(
          theme: AppTheme.light,
          home: const ItemDetailPage(
            id: 'it1',
            name: 'Laptop Asus Vivobook 14',
            category: 'Laptop',
            description: 'Laptop Core i5 untuk lab dan presentasi',
            iconKey: 'laptop',
            maxAvailable: 5,
            kind: ItemKind.perUnit,
            satuan: 'unit',
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Pastikan tombol Tambahkan ke Keranjang ada
    final addBtn = find.text('Tambahkan ke Keranjang');
    expect(addBtn, findsOneWidget);
    await tester.ensureVisible(addBtn);
    await tester.pumpAndSettle();
    await tester.tap(addBtn);
    await tester.pumpAndSettle();

    // Verifikasi Bottom Sheet berhasil muncul
    expect(find.text('Berhasil Masuk Keranjang'), findsOneWidget);
    expect(find.text('Pilih Barang Lain'), findsOneWidget);
    expect(find.text('Buka Keranjang'), findsOneWidget);
    expect(cart.itemCount, equals(1));
    expect(cart.getById('it1')?.qty, equals(1));
  });
}
