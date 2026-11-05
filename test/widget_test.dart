import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/main.dart';

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
}
