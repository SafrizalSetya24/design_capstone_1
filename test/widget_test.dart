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
import 'package:sipintar/pages/profile/profile_page.dart';
import 'package:sipintar/pages/review/app_review_page.dart';
import 'package:sipintar/pages/review/user_feedback_page.dart';
import 'package:sipintar/pages/admin/reviews/admin_review_management_page.dart';
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
    final errSiswa = auth.login('22090044', 'sipintar123');
    expect(errSiswa, isNull);
    expect(auth.currentUser?.role, equals(UserRole.siswa));
    expect(auth.currentUser?.name, equals('Safrizal Setya Wira Budiman'));

    auth.logout();

    // Login via NIK Guru
    final errGuru = auth.login('24090106', 'sipintar123');
    expect(errGuru, isNull);
    expect(auth.currentUser?.role, equals(UserRole.guru));
    expect(auth.currentUser?.name, equals('Ade Anang Kurniawan'));
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
    await tester.enterText(inputFinder, '22090044');
    await tester.pump();
    expect(find.textContaining('Siswa: Safrizal Setya Wira Budiman'), findsOneWidget);

    // Ketik NIK guru
    await tester.enterText(inputFinder, '24090106');
    await tester.pump();
    expect(find.textContaining('Guru: Ade Anang Kurniawan'), findsOneWidget);
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

  testWidgets('LoginPage renders cleanly on Full HD 1920x1080 desktop without overflow', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
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
    expect(find.text('SMK MUHAMMADIYAH 1 SUKOHARJO'), findsOneWidget);
    expect(find.text('Masuk Aplikasi'), findsNWidgets(2));
  });

  testWidgets('LoginPage renders cleanly on mobile viewport (width 360) without overflow', (tester) async {
    tester.view.physicalSize = const Size(360, 780);
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
    expect(find.text('Masuk Aplikasi'), findsOneWidget); // PrimaryButton label on mobile
    expect(find.text('InventarisMuhamka'), findsOneWidget);
    expect(find.text('Safrizal'), findsOneWidget);
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

    auth.login('22090044', 'sipintar123');

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

  testWidgets('Sarpras top right profile menu opens ProfilePage', (tester) async {
    final settings = SettingsStore();
    final audit = AuditStore();
    final auth = AuthStore(audit);
    final notif = NotificationStore();
    final inventory = InventoryStore(auth, audit);
    final consumables = ConsumableStore(auth, audit, notif);
    final loans = LoanStore(auth, audit, notif, inventory, settings);
    final chat = ChatStore(auth, inventory, consumables, loans);
    final cart = CartStore();

    auth.demoLogin('sp1'); // Petugas Sarpras

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
          home: const AdaptiveShell(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Pastikan dashboard sarpras muncul
    expect(find.text('Ringkasan Operasional Hari Ini'), findsOneWidget);

    // Buka menu akun di pojok kanan atas
    final accountMenu = find.byTooltip('Akun');
    expect(accountMenu, findsOneWidget);
    await tester.tap(accountMenu);
    await tester.pumpAndSettle();

    // Verifikasi popup menu muncul
    final profileItem = find.text('Profil');
    expect(profileItem, findsOneWidget);

    // Tap Profil
    await tester.tap(profileItem);
    await tester.pumpAndSettle();

    // Verifikasi ProfilePage berhasil terbuka
    expect(find.byType(ProfilePage), findsOneWidget);
    expect(find.text('Data Identitas Sekolah'), findsOneWidget);
    expect(find.text('Sapras'), findsWidgets);
  });

  testWidgets('AdminReviewSummaryPage displays recap and allows adding evaluation note', (tester) async {
    final audit = AuditStore();
    final auth = AuthStore(audit);
    final reviews = ReviewStore();

    auth.demoLogin('ad1'); // Admin: Hendra Gunawan

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: reviews),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AppReviewPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Pastikan header ulasan muncul pada tampilan admin
    expect(find.text('Ulasan & Penilaian Aplikasi'), findsOneWidget);
    expect(find.text('Berdasarkan 5 ulasan pengguna'), findsOneWidget);

    // Tekan tombol Tulis Ulasan
    final writeReviewBtn = find.text('Beri Ulasan');
    expect(writeReviewBtn, findsOneWidget);
    await tester.ensureVisible(writeReviewBtn);
    await tester.pumpAndSettle();
    await tester.tap(writeReviewBtn);
    await tester.pumpAndSettle();

    // Modal bottom sheet muncul
    expect(find.text('Tulis Ulasan / Catatan Evaluasi'), findsOneWidget);
    expect(find.text('Beri Penilaian Bintang'), findsOneWidget);

    // Isi komentar ulasan
    final inputComment = find.byType(TextFormField).first;
    await tester.enterText(inputComment, 'Aplikasi ini sangat bagus dan mempermudah siswa meminjam alat!');
    await tester.pumpAndSettle();

    // Kirim Ulasan
    final submitBtn = find.text('Kirim Ulasan');
    expect(submitBtn, findsOneWidget);
    await tester.ensureVisible(submitBtn);
    await tester.pumpAndSettle();
    await tester.tap(submitBtn);
    await tester.pumpAndSettle();

    // Verifikasi ulasan bertambah menjadi 6
    expect(reviews.totalReviews, equals(6));
    expect(find.text('Berdasarkan 6 ulasan pengguna'), findsOneWidget);
    expect(find.text('Aplikasi ini sangat bagus dan mempermudah siswa meminjam alat!'), findsOneWidget);
  });

  testWidgets('UserFeedbackPage allows students to submit suggestions directly and see personal history', (tester) async {
    final audit = AuditStore();
    final auth = AuthStore(audit);
    final reviews = ReviewStore();

    auth.demoLogin('sw1'); // Siswa: Rizky Pratama

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: reviews),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const UserFeedbackPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Pastikan form kritik & saran siswa muncul langsung di halaman
    expect(find.text('Kritik & Saran Layanan Sarpras'), findsOneWidget);
    expect(find.text('Formulir Ulasan & Saran Pengguna'), findsOneWidget);
    expect(find.text('Bagaimana Kepuasan Anda Terhadap Layanan Sarpras?'), findsOneWidget);

    // Isi kritik dan saran pada textfield langsung
    final inputSaran = find.byType(TextFormField).first;
    await tester.enterText(inputSaran, 'Mohon untuk stop kontak charger laptop di lab RPL ditambah.');
    await tester.pumpAndSettle();

    // Tekan tombol Kirim Saran & Masukan
    final submitSaranBtn = find.text('Kirim Saran & Masukan');
    expect(submitSaranBtn, findsOneWidget);
    await tester.ensureVisible(submitSaranBtn);
    await tester.pumpAndSettle();
    await tester.tap(submitSaranBtn);
    await tester.pumpAndSettle();

    // Verifikasi ulasan bertambah dan tampil di riwayat pribadi siswa
    expect(reviews.totalReviews, equals(6));
    expect(reviews.reviewsForUser('sw1').length, equals(2)); // 1 bawaan dummy + 1 baru
    expect(find.text('Mohon untuk stop kontak charger laptop di lab RPL ditambah.'), findsOneWidget);
  });

  testWidgets('AdminReviewManagementPage allows moderating and replying to user suggestions', (tester) async {
    final audit = AuditStore();
    final auth = AuthStore(audit);
    final reviews = ReviewStore();

    auth.demoLogin('ad1'); // Admin: Hendra Gunawan

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: auth),
          ChangeNotifierProvider.value(value: reviews),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const AdminReviewManagementPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Pastikan halaman moderasi ulasan admin terbuka
    expect(find.text('Pengelolaan & Moderasi Ulasan'), findsOneWidget);
    expect(find.text('Total Masukan'), findsOneWidget);

    // Cari tombol Beri Tanggapan untuk ulasan pertama
    final replyBtn = find.text('Beri Tanggapan').first;
    expect(replyBtn, findsOneWidget);
    await tester.ensureVisible(replyBtn);
    await tester.pumpAndSettle();
    await tester.tap(replyBtn);
    await tester.pumpAndSettle();

    // Dialog tanggapan resmi muncul
    expect(find.text('Tanggapan Resmi Admin'), findsOneWidget);
    final replyInput = find.byType(TextFormField).first;
    await tester.enterText(replyInput, 'Terima kasih atas masukannya, akan segera kami tindaklanjuti.');
    await tester.pumpAndSettle();

    // Tekan simpan tanggapan
    final saveReplyBtn = find.text('Simpan Tanggapan');
    await tester.tap(saveReplyBtn);
    await tester.pumpAndSettle();

    // Verifikasi ulasan telah dibalas
    expect(find.text('Terima kasih atas masukannya, akan segera kami tindaklanjuti.'), findsOneWidget);
  });
}
