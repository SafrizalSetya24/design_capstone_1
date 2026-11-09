import 'package:flutter/foundation.dart';
import 'package:sipintar/data/dummy/dummy_data.dart';
import 'package:sipintar/data/models/inventory_models.dart';
import 'package:sipintar/data/models/loan_models.dart';
import 'package:sipintar/data/models/misc_models.dart';
import 'package:sipintar/data/stores/audit_store.dart';
import 'package:sipintar/data/stores/auth_store.dart';
import 'package:sipintar/data/stores/inventory_store.dart';
import 'package:sipintar/data/stores/notification_store.dart';
import 'package:sipintar/data/stores/settings_store.dart';

class LoanStore extends ChangeNotifier {
  LoanStore(this._auth, this._audit, this._notif, this._inv, this._settings);
  final AuthStore _auth;
  final AuditStore _audit;
  final NotificationStore _notif;
  final InventoryStore _inv;
  final SettingsStore _settings;

  final List<LoanRequest> loans = DummyData.loans();
  int _n = 0;

  void _log(String type, String detail) {
    final u = _auth.currentUser;
    _audit.log(u?.name ?? 'Sistem', u?.role.label ?? 'Sistem', type, detail);
  }

  void _event(LoanRequest l, LoanStatus s, [String? note]) {
    l.status = s;
    l.events.add(LoanEvent(s, DateTime.now(), note));
  }

  LoanRequest? byId(String id) {
    for (final l in loans) {
      if (l.id == id) return l;
    }
    return null;
  }

  List<LoanRequest> forUser(String id) =>
      loans.where((l) => l.borrower.id == id).toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  List<LoanRequest> withStatus(Set<LoanStatus> s) =>
      loans.where((l) => s.contains(l.status)).toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));
  int count(Set<LoanStatus> s) =>
      loans.where((l) => s.contains(l.status)).length;

  DateTime deadlineOf(LoanRequest l) =>
      l.submittedAt.add(Duration(hours: _settings.approvalHours));
  Duration remaining(LoanRequest l) => deadlineOf(l).difference(DateTime.now());

  void checkExpiry() {
    var changed = false;
    for (final l in loans) {
      if (l.status == LoanStatus.menungguPersetujuan &&
          remaining(l).isNegative) {
        _expire(l);
        changed = true;
      }
    }
    if (changed) notifyListeners();
  }

  void _expire(LoanRequest l) {
    _event(l, LoanStatus.kedaluwarsa,
        'Batas persetujuan ${_settings.approvalHours} jam terlewati');
    _notif.add(l.borrower.id, NotifType.kedaluwarsa, 'Booking kedaluwarsa',
        'Pengajuan ${l.id} tidak diproses dalam ${_settings.approvalHours} jam sehingga kedaluwarsa. Silakan ajukan ulang.',
        refId: l.id);
    _log('Kedaluwarsa', 'Booking ${l.id} kedaluwarsa');
  }

  // ---------- Pengajuan ----------
  LoanRequest createDraft({
    required Borrower borrower,
    required List<LoanLine> lines,
    required DateTime start,
    required DateTime end,
    required String purpose,
  }) {
    final l = LoanRequest(
      id: 'PJM-${(27 + _n++).toString().padLeft(4, '0')}',
      borrower: borrower,
      lines: lines,
      start: start,
      end: end,
      purpose: purpose.trim(),
      status: LoanStatus.menungguVerifikasiWajah,
      submittedAt: DateTime.now(),
    );
    l.events.add(LoanEvent(LoanStatus.menungguVerifikasiWajah, DateTime.now()));
    loans.add(l);
    notifyListeners();
    return l;
  }

  void submitFace(LoanRequest l, {required bool ok, required double score}) {
    l.faceScore = score;
    l.faceVerified = ok;
    if (ok) {
      _event(l, LoanStatus.verifikasiBerhasil,
          'Wajah cocok (${(score * 100).round()}%)');
      l.submittedAt = DateTime.now();
      _event(l, LoanStatus.menungguPersetujuan);
      _notif.add(
          l.borrower.id,
          NotifType.pengajuan,
          'Pengajuan berhasil dikirim',
          'Pengajuan ${l.id} menunggu persetujuan Sapras maksimal ${_settings.approvalHours} jam.',
          refId: l.id);
      _log('Pengajuan', 'Mengajukan peminjaman ${l.id}');
    }
    notifyListeners();
  }

  // ---------- Persetujuan ----------
  String? availabilityIssue(LoanRequest l) {
    for (final line in l.lines) {
      final it = _inv.itemById(line.itemId);
      if (it == null || it.available < line.qty) {
        return 'Unit ${line.itemName} tersedia ${it?.available ?? 0}, dibutuhkan ${line.qty}.';
      }
    }
    return null;
  }

  String? approve(LoanRequest l) {
    if (remaining(l).isNegative) {
      checkExpiry();
      return 'Batas waktu persetujuan sudah terlewati. Booking kedaluwarsa.';
    }
    final issue = availabilityIssue(l);
    if (issue != null) return issue;
    _event(l, LoanStatus.disetujui,
        'Disetujui oleh ${_auth.currentUser?.name ?? 'Sapras'}');
    _notif.add(l.borrower.id, NotifType.persetujuan, 'Peminjaman disetujui',
        'Pengajuan ${l.id} disetujui. Ambil barang di Ruang Sapras sesuai jadwal.',
        refId: l.id);
    _log('Persetujuan', 'Menyetujui peminjaman ${l.id}');
    notifyListeners();
    return null;
  }

  void reject(LoanRequest l, String reason) {
    l.rejectReason = reason.trim();
    _event(l, LoanStatus.ditolak, l.rejectReason);
    _notif.add(l.borrower.id, NotifType.penolakan, 'Peminjaman ditolak',
        'Pengajuan ${l.id} ditolak. Alasan: ${l.rejectReason}',
        refId: l.id);
    _log('Penolakan', 'Menolak peminjaman ${l.id}');
    notifyListeners();
  }

  // ---------- Penyerahan ----------
  List<String> suggestUnits(LoanRequest l, String itemId, int skip) {
    final it = _inv.itemById(itemId);
    if (it == null) return [];
    return it.units
        .where((u) => u.borrowable && !l.unitCodes.contains(u.code))
        .map((u) => u.code)
        .toList();
  }

  String? handover(LoanRequest l, String receiver, List<String> codes) {
    if (codes.length != l.totalQty) {
      return 'Scan seluruh unit barang terlebih dahulu.';
    }
    _inv.markBorrowed(codes);
    l.unitCodes = List.of(codes);
    l.receiver = receiver.trim();
    l.handoverAt = DateTime.now();
    _event(l, LoanStatus.sedangDipinjam, 'Diserahkan kepada ${l.receiver}');
    _notif.add(l.borrower.id, NotifType.pengingat, 'Barang telah diserahkan',
        'Kembalikan barang pengajuan ${l.id} sebelum ${l.end.hour.toString().padLeft(2, '0')}.${l.end.minute.toString().padLeft(2, '0')}.',
        refId: l.id);
    _log('Penyerahan', 'Menyerahkan barang ${l.id}');
    notifyListeners();
    return null;
  }

  void markDue(LoanRequest l) {
    _event(l, LoanStatus.menungguPengembalian, 'Jadwal pengembalian tiba');
    _notif.add(l.borrower.id, NotifType.pengingat, 'Pengingat pengembalian',
        'Waktu peminjaman ${l.id} telah berakhir. Segera kembalikan barang.',
        refId: l.id);
    notifyListeners();
  }

  // ---------- Pengembalian ----------
  void completeReturn(
      LoanRequest l, Map<String, ItemCondition> conds, String note) {
    l.returnConditions = Map.of(conds);
    l.damageNote = note.trim().isEmpty ? null : note.trim();
    l.returnedAt = DateTime.now();
    for (final e in conds.entries) {
      _inv.releaseUnit(e.key);
      if (e.value != ItemCondition.layak) {
        _inv.reportDamage(e.key,
            issue: l.damageNote ?? 'Ditemukan saat pengembalian ${l.id}',
            severity: e.value,
            note: 'Pengembalian ${l.id}');
      }
    }
    _event(l, LoanStatus.selesai, 'Dikembalikan');
    _notif.add(
        l.borrower.id,
        NotifType.persetujuan,
        'Pengembalian dikonfirmasi',
        'Barang pengajuan ${l.id} telah diterima kembali. Terima kasih.',
        refId: l.id);
    _log('Pengembalian', 'Mengonfirmasi pengembalian ${l.id}');
    notifyListeners();
  }

  // ---------- Simulasi status (demo) ----------
  String? simulate(LoanRequest l, String action) {
    switch (action) {
      case 'approve':
        return approve(l);
      case 'reject':
        reject(l,
            'Barang dibutuhkan untuk kegiatan sekolah pada jadwal tersebut.');
      case 'expire':
        l.submittedAt = DateTime.now()
            .subtract(Duration(hours: _settings.approvalHours, minutes: 1));
        _expire(l);
        notifyListeners();
      case 'handover':
        final codes = <String>[];
        for (final line in l.lines) {
          final c = suggestUnits(l, line.itemId, 0).take(line.qty).toList();
          if (c.length < line.qty) {
            return 'Unit ${line.itemName} belum cukup tersedia.';
          }
          codes.addAll(c);
        }
        return handover(l, l.borrower.name, codes);
      case 'due':
        markDue(l);
      case 'return':
        completeReturn(
            l, {for (final c in l.unitCodes) c: ItemCondition.layak}, '');
    }
    return null;
  }
}
