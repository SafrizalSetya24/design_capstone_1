import 'package:sipintar/data/models/inventory_models.dart';
import 'package:sipintar/data/models/loan_models.dart';
import 'package:sipintar/data/models/misc_models.dart';
import 'package:sipintar/data/models/user_model.dart';

/// Seluruh data dummy lokal. Waktu dibuat relatif terhadap saat aplikasi dibuka.
class DummyData {
  DummyData._();
  static const password = 'sipintar123';

  static const List<AppUser> users = [
    Siswa(id: 'sw1', name: 'Rizky Pratama', email: 'siswa@sipintar.id', nis: '2024001234', kelas: 'XI RPL 1'),
    Siswa(id: 'sw2', name: 'Aulia Rahma', email: 'aulia@sipintar.id', nis: '2024001301', kelas: 'X TKJ 2'),
    Siswa(id: 'sw3', name: 'Dimas Saputra', email: 'dimas@sipintar.id', nis: '2023000987', kelas: 'XII MM 1'),
    Siswa(id: 'sw4', name: 'Nabila Putri', email: 'nabila@sipintar.id', nis: '2024001455', kelas: 'XI AKL 1'),
    Guru(id: 'gr1', name: 'Siti Nurhaliza, S.Pd.', email: 'guru@sipintar.id', nik: '3374012345670001', mataPelajaran: 'Informatika'),
    Guru(id: 'gr2', name: 'Ahmad Fauzi, S.Kom.', email: 'ahmad@sipintar.id', nik: '3374012345670002', mataPelajaran: 'Wali kelas XI RPL 1'),
    Guru(id: 'gr3', name: 'Rina Wulandari, M.Pd.', email: 'rina@sipintar.id', nik: '3374012345670003', mataPelajaran: 'Bahasa Indonesia'),
    SaprasUser(id: 'sp1', name: 'Budi Santoso', email: 'sapras@sipintar.id', idPegawai: 'SPR-007'),
    SaprasUser(id: 'sp2', name: 'Lina Marlina', email: 'lina@sipintar.id', idPegawai: 'SPR-008'),
    AdminUser(id: 'ad1', name: 'Dewi Lestari', email: 'admin@sipintar.id', idPegawai: 'ADM-001'),
  ];

  static AppUser user(String id) => users.firstWhere((u) => u.id == id);

  static List<Account> accounts() {
    final now = DateTime.now();
    var i = 0;
    return users.map((u) {
      i++;
      return Account(
        user: u,
        password: password,
        active: u.id != 'sw3',
        created: now.subtract(Duration(days: 200 - i * 9)),
        lastLogin: now.subtract(Duration(hours: i * 5)),
      );
    }).toList();
  }

  // ---------- Kategori ----------
  static List<Category> categories() => [
        Category(id: 'k1', name: 'Laptop', type: CategoryType.perUnit, description: 'Komputer jinjing untuk pembelajaran.'),
        Category(id: 'k2', name: 'Proyektor', type: CategoryType.perUnit, description: 'Proyektor ruang kelas dan aula.'),
        Category(id: 'k3', name: 'Kamera', type: CategoryType.perUnit, description: 'Kamera dokumentasi dan multimedia.'),
        Category(id: 'k4', name: 'Audio', type: CategoryType.perUnit, description: 'Speaker dan mikrofon kegiatan.'),
        Category(id: 'k5', name: 'Alat Tulis', type: CategoryType.habisPakai, description: 'Pulpen, spidol, dan sejenisnya.'),
        Category(id: 'k6', name: 'Kertas', type: CategoryType.habisPakai, description: 'Kertas cetak dan fotokopi.'),
        Category(id: 'k7', name: 'Tinta & Toner', type: CategoryType.habisPakai, description: 'Tinta dan toner printer.'),
        Category(id: 'k8', name: 'Kebersihan', type: CategoryType.habisPakai, description: 'Perlengkapan kebersihan kelas.'),
      ];

  // ---------- Barang per unit ----------
  static List<AssetUnit> _units(String p, int n,
      {Map<int, ItemCondition> cond = const {}, Set<int> borrowed = const {}}) {
    return List.generate(n, (i) {
      final c = cond[i + 1] ?? ItemCondition.layak;
      final st = borrowed.contains(i + 1)
          ? UnitStatus.dipinjam
          : switch (c) {
              ItemCondition.layak => UnitStatus.tersedia,
              ItemCondition.perluDiperbaiki => UnitStatus.perbaikan,
              ItemCondition.rusakTotal => UnitStatus.nonaktif,
            };
      return AssetUnit(code: '$p-2026-${(i + 1).toString().padLeft(3, '0')}', condition: c, status: st);
    });
  }

  static List<UnitItem> unitItems() => [
        UnitItem(
            id: 'it1', name: 'Laptop Asus Vivobook 14', category: 'Laptop', iconKey: 'laptop',
            description: 'Laptop Intel Core i5, RAM 8 GB, SSD 512 GB. Terpasang aplikasi perkantoran dan desain.',
            location: 'Lab Komputer 1',
            units: _units('LPT', 6, cond: {5: ItemCondition.perluDiperbaiki}, borrowed: {1})),
        UnitItem(
            id: 'it2', name: 'Laptop Lenovo IdeaPad 3', category: 'Laptop', iconKey: 'laptop',
            description: 'Laptop Ryzen 5, RAM 8 GB, cocok untuk pembelajaran dan presentasi.',
            location: 'Lab Komputer 2', units: _units('LNV', 4)),
        UnitItem(
            id: 'it3', name: 'Proyektor Epson EB-X06', category: 'Proyektor', iconKey: 'proyektor',
            description: 'Proyektor 3.600 lumens, resolusi XGA, dilengkapi kabel HDMI dan remote.',
            location: 'Ruang Sapras',
            units: _units('PRY', 4, cond: {4: ItemCondition.rusakTotal}, borrowed: {1, 2})),
        UnitItem(
            id: 'it4', name: 'Kamera Canon EOS 200D', category: 'Kamera', iconKey: 'kamera',
            description: 'Kamera DSLR 24 MP dengan lensa kit 18-55 mm, tas, dan memori 64 GB.',
            location: 'Ruang Multimedia', units: _units('KMR', 2)),
        UnitItem(
            id: 'it5', name: 'Speaker Portable JBL', category: 'Audio', iconKey: 'speaker',
            description: 'Speaker bluetooth portabel untuk kegiatan kelas dan lapangan.',
            location: 'Ruang Sapras', units: _units('SPK', 3, cond: {3: ItemCondition.perluDiperbaiki})),
        UnitItem(
            id: 'it6', name: 'Mikrofon Wireless Shure', category: 'Audio', iconKey: 'mikrofon',
            description: 'Mikrofon nirkabel dengan receiver, baterai cadangan, dan tas penyimpanan.',
            location: 'Ruang Multimedia', units: _units('MIK', 4)),
      ];

  static List<ConsumableItem> consumables() => [
        ConsumableItem(id: 'cs1', name: 'Kertas HVS A4 80 gr', category: 'Kertas', satuan: 'rim', stock: 42, minStock: 20,
            location: 'Gudang ATK', description: 'Kertas cetak dan fotokopi, 1 rim berisi 500 lembar.', iconKey: 'kertas'),
        ConsumableItem(id: 'cs2', name: 'Pulpen Standard Hitam', category: 'Alat Tulis', satuan: 'pcs', stock: 120, minStock: 50,
            location: 'Gudang ATK', description: 'Pulpen tinta hitam 0,5 mm.', iconKey: 'pulpen'),
        ConsumableItem(id: 'cs3', name: 'Spidol Whiteboard Hitam', category: 'Alat Tulis', satuan: 'pcs', stock: 18, minStock: 24,
            location: 'Gudang ATK', description: 'Spidol papan tulis mudah dihapus.', iconKey: 'spidol'),
        ConsumableItem(id: 'cs4', name: 'Tinta Printer Epson 003 Hitam', category: 'Tinta & Toner', satuan: 'botol', stock: 6, minStock: 5,
            location: 'Ruang Sapras', description: 'Tinta botol 65 ml untuk printer Epson L-series.', iconKey: 'tinta'),
        ConsumableItem(id: 'cs5', name: 'Penghapus Papan Tulis', category: 'Kebersihan', satuan: 'pcs', stock: 9, minStock: 10,
            location: 'Gudang ATK', description: 'Penghapus papan tulis berbahan busa.', iconKey: 'penghapus'),
      ];

  static List<StockMovement> movements() {
    final n = DateTime.now();
    StockMovement m(String id, String item, String name, bool inn, int q, int days, String note) => StockMovement(
        id: id, itemId: item, itemName: name, isIn: inn, qty: q, date: n.subtract(Duration(days: days)),
        note: note, actor: 'Budi Santoso');
    return [
      m('m1', 'cs1', 'Kertas HVS A4 80 gr', true, 30, 14, 'Pembelian bulanan'),
      m('m2', 'cs1', 'Kertas HVS A4 80 gr', false, 2, 6, 'Permintaan Rizky Pratama'),
      m('m3', 'cs2', 'Pulpen Standard Hitam', true, 100, 20, 'Pengadaan semester'),
      m('m4', 'cs3', 'Spidol Whiteboard Hitam', false, 6, 9, 'Permintaan guru'),
      m('m5', 'cs4', 'Tinta Printer Epson 003 Hitam', true, 4, 12, 'Pembelian bulanan'),
      m('m6', 'cs5', 'Penghapus Papan Tulis', false, 3, 4, 'Permintaan kelas XII'),
    ];
  }

  static List<RepairRecord> repairs() {
    final n = DateTime.now();
    return [
      RepairRecord(id: 'r1', unitCode: 'LPT-2026-005', itemName: 'Laptop Asus Vivobook 14',
          issue: 'Layar berkedip dan engsel longgar', severity: ItemCondition.perluDiperbaiki,
          status: RepairStatus.diperbaiki, reportedAt: n.subtract(const Duration(days: 4)),
          updatedAt: n.subtract(const Duration(days: 1)), technician: 'Servis Karya Teknik', notes: 'Penggantian panel layar.'),
      RepairRecord(id: 'r2', unitCode: 'SPK-2026-003', itemName: 'Speaker Portable JBL',
          issue: 'Suara pecah pada volume tinggi', severity: ItemCondition.perluDiperbaiki,
          status: RepairStatus.menunggu, reportedAt: n.subtract(const Duration(days: 2)),
          updatedAt: n.subtract(const Duration(days: 2))),
      RepairRecord(id: 'r3', unitCode: 'PRY-2026-004', itemName: 'Proyektor Epson EB-X06',
          issue: 'Lampu dan board utama rusak', severity: ItemCondition.rusakTotal,
          status: RepairStatus.tidakDapatDiperbaiki, reportedAt: n.subtract(const Duration(days: 30)),
          updatedAt: n.subtract(const Duration(days: 25)), technician: 'Servis Karya Teknik',
          notes: 'Biaya perbaikan melebihi nilai barang.', confirmed: true, finalCondition: ItemCondition.rusakTotal),
      RepairRecord(id: 'r4', unitCode: 'KMR-2026-002', itemName: 'Kamera Canon EOS 200D',
          issue: 'Lensa berjamur', severity: ItemCondition.perluDiperbaiki, status: RepairStatus.selesai,
          reportedAt: n.subtract(const Duration(days: 45)), updatedAt: n.subtract(const Duration(days: 38)),
          technician: 'Foto Servis Nusantara', notes: 'Lensa dibersihkan.', confirmed: true,
          finalCondition: ItemCondition.layak),
    ];
  }

  static List<ConditionLog> conditionLogs() {
    final n = DateTime.now();
    ConditionLog l(String code, String item, ItemCondition a, ItemCondition b, String note, int d) =>
        ConditionLog(unitCode: code, itemName: item, from: a, to: b, note: note,
            date: n.subtract(Duration(days: d)), actor: 'Budi Santoso');
    return [
      l('KMR-2026-002', 'Kamera Canon EOS 200D', ItemCondition.layak, ItemCondition.perluDiperbaiki, 'Lensa berjamur', 45),
      l('KMR-2026-002', 'Kamera Canon EOS 200D', ItemCondition.perluDiperbaiki, ItemCondition.layak, 'Pemeriksaan setelah perbaikan', 38),
      l('PRY-2026-004', 'Proyektor Epson EB-X06', ItemCondition.layak, ItemCondition.rusakTotal, 'Lampu dan board utama rusak', 30),
      l('LPT-2026-005', 'Laptop Asus Vivobook 14', ItemCondition.layak, ItemCondition.perluDiperbaiki, 'Layar berkedip', 4),
      l('SPK-2026-003', 'Speaker Portable JBL', ItemCondition.layak, ItemCondition.perluDiperbaiki, 'Suara pecah', 2),
    ];
  }

  // ---------- Peminjaman ----------
  static Borrower _b(String id) => Borrower.fromUser(user(id));

  static LoanRequest _loan(String id, String uid, List<LoanLine> lines, DateTime start, DateTime end, String purpose,
      LoanStatus st, DateTime submitted,
      {String? reject, List<String>? codes, DateTime? returned, String? receiver}) {
    final path = st.path;
    final events = <LoanEvent>[
      for (var i = 0; i < path.length; i++)
        LoanEvent(path[i], submitted.add(Duration(minutes: i * 6)), path[i] == LoanStatus.ditolak ? reject : null),
    ];
    return LoanRequest(
      id: id, borrower: _b(uid), lines: lines, start: start, end: end, purpose: purpose, status: st,
      submittedAt: submitted,
      faceVerified: st == LoanStatus.menungguVerifikasiWajah ? null : true,
      faceScore: st == LoanStatus.menungguVerifikasiWajah ? null : 0.96,
      rejectReason: reject, unitCodes: codes, returnedAt: returned, receiver: receiver,
      handoverAt: codes == null ? null : start, events: events,
      returnConditions: st == LoanStatus.selesai ? {for (final c in codes ?? <String>[]) c: ItemCondition.layak} : null,
    );
  }

  static LoanLine _l(String id, String name, String icon, int q) =>
      LoanLine(itemId: id, itemName: name, iconKey: icon, qty: q);

  static List<LoanRequest> loans() {
    final n = DateTime.now();
    DateTime t(int dayOffset, int h, [int m = 0]) => DateTime(n.year, n.month, n.day + dayOffset, h, m);
    return [
      _loan('PJM-0021', 'sw1', [_l('it1', 'Laptop Asus Vivobook 14', 'laptop', 1), _l('it3', 'Proyektor Epson EB-X06', 'proyektor', 1)],
          t(0, 7, 30), t(0, 14), 'Praktik presentasi proyek akhir RPL', LoanStatus.sedangDipinjam,
          n.subtract(const Duration(days: 1, hours: 3)),
          codes: ['LPT-2026-001', 'PRY-2026-001'], receiver: 'Rizky Pratama'),
      _loan('PJM-0024', 'sw1', [_l('it4', 'Kamera Canon EOS 200D', 'kamera', 1)], t(2, 8), t(2, 12),
          'Dokumentasi kegiatan class meeting', LoanStatus.menungguPersetujuan,
          n.subtract(const Duration(hours: 2, minutes: 20))),
      _loan('PJM-0015', 'sw1', [_l('it5', 'Speaker Portable JBL', 'speaker', 1)], t(-5, 10), t(-5, 12),
          'Lomba cerdas cermat antar kelas', LoanStatus.selesai, n.subtract(const Duration(days: 6)),
          codes: ['SPK-2026-001'], returned: t(-5, 12, 10), receiver: 'Rizky Pratama'),
      _loan('PJM-0023', 'gr1', [_l('it2', 'Laptop Lenovo IdeaPad 3', 'laptop', 2), _l('it3', 'Proyektor Epson EB-X06', 'proyektor', 1)],
          t(1, 7), t(1, 15), 'Ujian praktik Informatika kelas XI', LoanStatus.disetujui,
          n.subtract(const Duration(hours: 5))),
      _loan('PJM-0025', 'gr1', [_l('it5', 'Speaker Portable JBL', 'speaker', 1)], t(3, 9), t(3, 11),
          'Kegiatan upacara bendera', LoanStatus.menungguVerifikasiWajah, n.subtract(const Duration(minutes: 10))),
      _loan('PJM-0026', 'sw2', [_l('it6', 'Mikrofon Wireless Shure', 'mikrofon', 2)], t(1, 9), t(1, 12),
          'Latihan pembawa acara perpisahan', LoanStatus.menungguPersetujuan,
          n.subtract(const Duration(hours: 11, minutes: 58, seconds: 30))),
      _loan('PJM-0019', 'gr2', [_l('it3', 'Proyektor Epson EB-X06', 'proyektor', 1)], t(-1, 8), t(-1, 15),
          'Rapat orang tua wali kelas XI RPL 1', LoanStatus.menungguPengembalian,
          n.subtract(const Duration(days: 3)), codes: ['PRY-2026-002'], receiver: 'Ahmad Fauzi, S.Kom.'),
      _loan('PJM-0018', 'sw4', [_l('it4', 'Kamera Canon EOS 200D', 'kamera', 1)], t(0, 13), t(0, 16),
          'Pembuatan video profil ekstrakurikuler', LoanStatus.ditolak, n.subtract(const Duration(days: 2)),
          reject: 'Kamera dijadwalkan untuk kegiatan OSIS pada waktu yang sama.'),
      _loan('PJM-0012', 'sw3', [_l('it1', 'Laptop Asus Vivobook 14', 'laptop', 1)], t(-8, 8), t(-8, 12),
          'Mengerjakan tugas desain grafis', LoanStatus.kedaluwarsa, n.subtract(const Duration(days: 9))),
    ];
  }

  static List<ConsumableRequest> consumableRequests() {
    final n = DateTime.now();
    ConsumableLine l(String id, String name, String sat, String icon, int q, [int? a]) =>
        ConsumableLine(itemId: id, itemName: name, satuan: sat, iconKey: icon, qty: q, approved: a);
    return [
      ConsumableRequest(id: 'HBP-0008', requester: _b('sw1'), lines: [l('cs1', 'Kertas HVS A4 80 gr', 'rim', 'kertas', 2, 2)],
          purpose: 'Mencetak laporan proyek kelas', status: ConsumableStatus.diserahkan,
          createdAt: n.subtract(const Duration(days: 7)), handedAt: n.subtract(const Duration(days: 6))),
      ConsumableRequest(id: 'HBP-0011', requester: _b('sw1'), lines: [l('cs3', 'Spidol Whiteboard Hitam', 'pcs', 'spidol', 3)],
          purpose: 'Kegiatan diskusi kelompok', status: ConsumableStatus.menunggu,
          createdAt: n.subtract(const Duration(hours: 3))),
      ConsumableRequest(id: 'HBP-0010', requester: _b('gr1'),
          lines: [l('cs4', 'Tinta Printer Epson 003 Hitam', 'botol', 'tinta', 1, 1), l('cs1', 'Kertas HVS A4 80 gr', 'rim', 'kertas', 3, 2)],
          purpose: 'Kebutuhan cetak soal ujian', status: ConsumableStatus.disetujui,
          createdAt: n.subtract(const Duration(days: 1))),
      ConsumableRequest(id: 'HBP-0009', requester: _b('sw2'), lines: [l('cs2', 'Pulpen Standard Hitam', 'pcs', 'pulpen', 40)],
          purpose: 'Dibagikan ke seluruh kelas', status: ConsumableStatus.ditolak,
          createdAt: n.subtract(const Duration(days: 3)),
          reason: 'Jumlah melebihi batas permintaan per pengajuan (maksimal 20 pcs).'),
    ];
  }

  static List<AppNotification> notifications() {
    final n = DateTime.now();
    AppNotification a(String id, String uid, NotifType t, String title, String body, Duration ago,
            {bool read = false, String? ref, bool loan = true}) =>
        AppNotification(id: id, userId: uid, type: t, title: title, body: body, time: n.subtract(ago),
            read: read, refId: ref, refIsLoan: loan);
    return [
      a('n1', 'sw1', NotifType.pengajuan, 'Pengajuan berhasil dikirim',
          'Pengajuan PJM-0024 (Kamera Canon EOS 200D) menunggu persetujuan Sapras maksimal 12 jam.',
          const Duration(hours: 2, minutes: 20), ref: 'PJM-0024'),
      a('n2', 'sw1', NotifType.pengingat, 'Pengingat pengembalian',
          'Kembalikan Laptop Asus dan Proyektor Epson ke Ruang Sapras sebelum pukul 14.00 hari ini.',
          const Duration(minutes: 40), ref: 'PJM-0021'),
      a('n3', 'sw1', NotifType.habisPakai, 'Permintaan barang diproses',
          'Permintaan HBP-0011 (Spidol Whiteboard) sedang menunggu persetujuan Sapras.',
          const Duration(hours: 3), ref: 'HBP-0011', loan: false),
      a('n4', 'sw1', NotifType.persetujuan, 'Peminjaman disetujui',
          'Pengajuan PJM-0021 disetujui. Ambil barang di Ruang Sapras sesuai jadwal.',
          const Duration(days: 1, hours: 2), read: true, ref: 'PJM-0021'),
      a('n5', 'gr1', NotifType.persetujuan, 'Peminjaman disetujui',
          'Pengajuan PJM-0023 (2 Laptop Lenovo, 1 Proyektor) disetujui.', const Duration(hours: 4), ref: 'PJM-0023'),
      a('n6', 'gr1', NotifType.habisPakai, 'Permintaan barang disetujui',
          'Permintaan HBP-0010 disetujui sebagian. Ambil barang di Ruang Sapras.', const Duration(hours: 20),
          ref: 'HBP-0010', loan: false),
      a('n7', 'gr1', NotifType.pengajuan, 'Menunggu verifikasi wajah',
          'Selesaikan verifikasi wajah untuk pengajuan PJM-0025 agar dapat diproses.', const Duration(minutes: 10),
          ref: 'PJM-0025'),
      a('n8', 'sw2', NotifType.pengajuan, 'Pengajuan berhasil dikirim',
          'Pengajuan PJM-0026 (2 Mikrofon) menunggu persetujuan Sapras.', const Duration(hours: 11, minutes: 58), ref: 'PJM-0026'),
      a('n9', 'sw2', NotifType.penolakan, 'Permintaan barang ditolak',
          'Permintaan HBP-0009 ditolak. Jumlah melebihi batas permintaan.', const Duration(days: 3), read: true,
          ref: 'HBP-0009', loan: false),
    ];
  }

  static List<AuditEntry> audit() {
    final n = DateTime.now();
    AuditEntry e(int i, String u, String r, String t, String d, Duration ago) =>
        AuditEntry(id: 'a$i', userName: u, role: r, type: t, detail: d, time: n.subtract(ago));
    return [
      e(1, 'Rizky Pratama', 'Siswa', 'Pengajuan', 'Mengajukan peminjaman PJM-0024', const Duration(hours: 2, minutes: 20)),
      e(2, 'Budi Santoso', 'Sapras', 'Persetujuan', 'Menyetujui peminjaman PJM-0023', const Duration(hours: 4, minutes: 50)),
      e(3, 'Siti Nurhaliza, S.Pd.', 'Guru', 'Pengajuan', 'Mengajukan peminjaman PJM-0025', const Duration(minutes: 10)),
      e(4, 'Budi Santoso', 'Sapras', 'Inventaris', 'Mencatat kerusakan unit SPK-2026-003', const Duration(days: 2)),
      e(5, 'Dewi Lestari', 'Admin', 'Pengguna', 'Menonaktifkan akun Dimas Saputra', const Duration(days: 3)),
      e(6, 'Aulia Rahma', 'Siswa', 'Pengajuan', 'Mengajukan peminjaman PJM-0026', const Duration(hours: 11, minutes: 58)),
      e(7, 'Budi Santoso', 'Sapras', 'Stok', 'Barang masuk: Kertas HVS A4 80 gr (+30 rim)', const Duration(days: 14)),
      e(8, 'Nabila Putri', 'Siswa', 'Login', 'Masuk ke aplikasi', const Duration(days: 2, hours: 3)),
      e(9, 'Dewi Lestari', 'Admin', 'Pengaturan', 'Mengubah batas booking menjadi 12 jam', const Duration(days: 20)),
      e(10, 'Budi Santoso', 'Sapras', 'Penolakan', 'Menolak peminjaman PJM-0018', const Duration(days: 2)),
      e(11, 'Ahmad Fauzi, S.Kom.', 'Guru', 'Login', 'Masuk ke aplikasi', const Duration(days: 3, hours: 6)),
      e(12, 'Dewi Lestari', 'Admin', 'Kategori', 'Menambah kategori Kebersihan', const Duration(days: 30)),
    ];
  }

  // ---------- Statistik / laporan / forecasting (simulasi) ----------
  static const months = ['Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov'];
  static const monthlyLoans = [24.0, 31.0, 28.0, 40.0, 36.0, 22.0];
  static const monthlyReturns = [23.0, 30.0, 27.0, 38.0, 35.0, 18.0];
  static const monthlyConsumableOut = [56.0, 61.0, 48.0, 72.0, 66.0, 35.0];
  static const monthlyConsumableIn = [80.0, 40.0, 60.0, 90.0, 50.0, 40.0];
  static const weekdays = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
  static const weeklyActivity = [34.0, 41.0, 38.0, 52.0, 47.0, 22.0, 15.0];

  /// Riwayat permintaan per kategori (6 bulan) dan prediksi 3 bulan (SIMULASI).
  static const forecastHistory = <String, List<double>>{
    'Laptop': [10, 13, 12, 17, 15, 9],
    'Proyektor': [7, 9, 8, 12, 11, 7],
    'Kamera': [3, 4, 4, 6, 5, 3],
    'Audio': [4, 5, 4, 5, 5, 3],
  };
  static const forecastPrediction = <String, List<double>>{
    'Laptop': [16, 18, 17],
    'Proyektor': [11, 12, 12],
    'Kamera': [5, 6, 6],
    'Audio': [5, 6, 5],
  };
  static const forecastMonths = ['Des', 'Jan', 'Feb'];
}
