// State management siklus hidup peminjaman barang (pengajuan, SLA 2 jam, handover barcode, dan pengembalian)

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
  LoanStore(
    this._authStore,
    this._auditStore,
    this._notificationStore,
    this._inventoryStore,
    this._settingsStore,
  );

  final AuthStore _authStore;
  final AuditStore _auditStore;
  final NotificationStore _notificationStore;
  final InventoryStore _inventoryStore;
  final SettingsStore _settingsStore;

  /// Daftar seluruh data peminjaman di sistem (dimuat awal dari data dummy realistis)
  final List<LoanRequest> loans = DummyData.loans();
  int _requestCounter = 0;

  // Catat riwayat audit dan perubahan status
  void _recordAuditLog(String actionType, String detailMessage) {
    final currentUser = _authStore.currentUser;
    _auditStore.log(
      currentUser?.name ?? 'Sistem',
      currentUser?.role.label ?? 'Sistem',
      actionType,
      detailMessage,
    );
  }

  void _appendLoanEvent(LoanRequest loan, LoanStatus newStatus, [String? note]) {
    loan.status = newStatus;
    loan.events.add(LoanEvent(newStatus, DateTime.now(), note));
  }

  // Filter dan pencarian peminjaman
  LoanRequest? byId(String loanId) {
    for (final loan in loans) {
      if (loan.id == loanId) return loan;
    }
    return null;
  }

  /// Mengambil daftar peminjaman milik pengguna tertentu (diurutkan dari yang terbaru)
  List<LoanRequest> forUser(String userId) =>
      loans.where((loan) => loan.borrower.id == userId).toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

  /// Mengambil peminjaman dengan status-status tertentu
  List<LoanRequest> withStatus(Set<LoanStatus> targetStatuses) =>
      loans.where((loan) => targetStatuses.contains(loan.status)).toList()
        ..sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

  /// Menghitung jumlah peminjaman berdasarkan status tertentu
  int count(Set<LoanStatus> targetStatuses) =>
      loans.where((loan) => targetStatuses.contains(loan.status)).length;

  // Batas waktu SLA approval 2 jam
  DateTime deadlineOf(LoanRequest loan) =>
      loan.submittedAt.add(Duration(hours: _settingsStore.approvalHours));

  Duration remaining(LoanRequest loan) =>
      deadlineOf(loan).difference(DateTime.now());

  void checkExpiry() {
    var hasExpiredChanges = false;
    for (final loan in loans) {
      if (loan.status == LoanStatus.menungguPersetujuan &&
          remaining(loan).isNegative) {
        _expireLoan(loan);
        hasExpiredChanges = true;
      }
    }
    if (hasExpiredChanges) {
      notifyListeners();
    }
  }

  void _expireLoan(LoanRequest loan) {
    _appendLoanEvent(
      loan,
      LoanStatus.kedaluwarsa,
      'Batas persetujuan ${_settingsStore.approvalHours} jam terlewati',
    );
    _notificationStore.add(
      loan.borrower.id,
      NotifType.kedaluwarsa,
      'Booking kedaluwarsa',
      'Pengajuan ${loan.id} tidak diproses dalam ${_settingsStore.approvalHours} jam sehingga kedaluwarsa. Silakan ajukan ulang.',
      refId: loan.id,
    );
    _recordAuditLog('Kedaluwarsa', 'Booking ${loan.id} kedaluwarsa');
  }

  // Pengajuan peminjaman dan verifikasi wajah
  LoanRequest createDraft({
    required Borrower borrower,
    required List<LoanLine> lines,
    required DateTime start,
    required DateTime end,
    required String purpose,
  }) {
    final loan = LoanRequest(
      id: 'PJM-${(27 + _requestCounter++).toString().padLeft(4, '0')}',
      borrower: borrower,
      lines: lines,
      start: start,
      end: end,
      purpose: purpose.trim(),
      status: LoanStatus.menungguVerifikasiWajah,
      submittedAt: DateTime.now(),
    );
    loan.events.add(LoanEvent(LoanStatus.menungguVerifikasiWajah, DateTime.now()));
    loans.add(loan);
    notifyListeners();
    return loan;
  }

  /// Memproses hasil verifikasi wajah biometrik (Anti-Joki)
  void submitFace(LoanRequest loan, {required bool ok, required double score}) {
    loan.faceScore = score;
    loan.faceVerified = ok;
    if (ok) {
      _appendLoanEvent(
        loan,
        LoanStatus.verifikasiBerhasil,
        'Wajah cocok (${(score * 100).round()}%)',
      );
      // Reset waktu submit ke saat verifikasi berhasil untuk memulai timer SLA 2 jam
      loan.submittedAt = DateTime.now();
      _appendLoanEvent(loan, LoanStatus.menungguPersetujuan);
      _notificationStore.add(
        loan.borrower.id,
        NotifType.pengajuan,
        'Pengajuan berhasil dikirim',
        'Pengajuan ${loan.id} menunggu persetujuan Sapras maksimal ${_settingsStore.approvalHours} jam.',
        refId: loan.id,
      );
      _recordAuditLog('Pengajuan', 'Mengajukan peminjaman ${loan.id}');
    }
    notifyListeners();
  }

  // Persetujuan pengajuan oleh petugas sapras
  String? availabilityIssue(LoanRequest loan) {
    for (final line in loan.lines) {
      final item = _inventoryStore.itemById(line.itemId);
      if (item == null || item.available < line.qty) {
        return 'Unit ${line.itemName} tersedia ${item?.available ?? 0}, dibutuhkan ${line.qty}.';
      }
    }
    return null;
  }

  String? approve(LoanRequest loan) {
    if (remaining(loan).isNegative) {
      checkExpiry();
      return 'Batas waktu persetujuan sudah terlewati. Booking kedaluwarsa.';
    }

    final issue = availabilityIssue(loan);
    if (issue != null) return issue;

    _appendLoanEvent(
      loan,
      LoanStatus.disetujui,
      'Disetujui oleh ${_authStore.currentUser?.name ?? 'Sapras'}',
    );
    _notificationStore.add(
      loan.borrower.id,
      NotifType.persetujuan,
      'Peminjaman disetujui',
      'Pengajuan ${loan.id} disetujui. Ambil barang di Ruang Sapras sesuai jadwal.',
      refId: loan.id,
    );
    _recordAuditLog('Persetujuan', 'Menyetujui peminjaman ${loan.id}');
    notifyListeners();
    return null;
  }

  /// Menolak pengajuan peminjaman disertai alasan penolakan yang jelas
  void reject(LoanRequest loan, String reason) {
    loan.rejectReason = reason.trim();
    _appendLoanEvent(loan, LoanStatus.ditolak, loan.rejectReason);
    _notificationStore.add(
      loan.borrower.id,
      NotifType.penolakan,
      'Peminjaman ditolak',
      'Pengajuan ${loan.id} ditolak. Alasan: ${loan.rejectReason}',
      refId: loan.id,
    );
    _recordAuditLog('Penolakan', 'Menolak peminjaman ${loan.id}');
    notifyListeners();
  }

  // Penyerahan barang fisik
  List<String> suggestUnits(LoanRequest loan, String itemId, int skip) {
    final item = _inventoryStore.itemById(itemId);
    if (item == null) return [];
    return item.units
        .where((unit) => unit.borrowable && !loan.unitCodes.contains(unit.code))
        .map((unit) => unit.code)
        .toList();
  }

  /// Konfirmasi penyerahan barang setelah seluruh barcode unit fisik discan
  String? handover(LoanRequest loan, String receiverName, List<String> scannedUnitCodes) {
    if (scannedUnitCodes.length != loan.totalQty) {
      return 'Scan seluruh unit barang terlebih dahulu.';
    }
    _inventoryStore.markBorrowed(scannedUnitCodes);
    loan.unitCodes = List.of(scannedUnitCodes);
    loan.receiver = receiverName.trim();
    loan.handoverAt = DateTime.now();
    _appendLoanEvent(loan, LoanStatus.sedangDipinjam, 'Diserahkan kepada ${loan.receiver}');
    _notificationStore.add(
      loan.borrower.id,
      NotifType.pengingat,
      'Barang telah diserahkan',
      'Kembalikan barang pengajuan ${loan.id} sebelum ${loan.end.hour.toString().padLeft(2, '0')}.${loan.end.minute.toString().padLeft(2, '0')}.',
      refId: loan.id,
    );
    _recordAuditLog('Penyerahan', 'Menyerahkan barang ${loan.id}');
    notifyListeners();
    return null;
  }

  /// Menandai jadwal peminjaman telah habis dan masuk tahap pengembalian
  void markDue(LoanRequest loan) {
    _appendLoanEvent(loan, LoanStatus.menungguPengembalian, 'Jadwal pengembalian tiba');
    _notificationStore.add(
      loan.borrower.id,
      NotifType.pengingat,
      'Pengingat pengembalian',
      'Waktu peminjaman ${loan.id} telah berakhir. Segera kembalikan barang.',
      refId: loan.id,
    );
    notifyListeners();
  }

  // Pengembalian barang dan pencatatan kondisi fisik
  void completeReturn(
    LoanRequest loan,
    Map<String, ItemCondition> conditions,
    String damageNotes,
  ) {
    loan.returnConditions = Map.of(conditions);
    loan.damageNote = damageNotes.trim().isEmpty ? null : damageNotes.trim();
    loan.returnedAt = DateTime.now();

    for (final entry in conditions.entries) {
      _inventoryStore.releaseUnit(entry.key);
      if (entry.value != ItemCondition.layak) {
        _inventoryStore.reportDamage(
          entry.key,
          issue: loan.damageNote ?? 'Ditemukan saat pengembalian ${loan.id}',
          severity: entry.value,
          note: 'Pengembalian ${loan.id}',
        );
      }
    }

    _appendLoanEvent(loan, LoanStatus.selesai, 'Dikembalikan');
    _notificationStore.add(
      loan.borrower.id,
      NotifType.persetujuan,
      'Pengembalian dikonfirmasi',
      'Barang pengajuan ${loan.id} telah diterima kembali. Terima kasih.',
      refId: loan.id,
    );
    _recordAuditLog('Pengembalian', 'Mengonfirmasi pengembalian ${loan.id}');
    notifyListeners();
  }

  // Simulasi status peminjaman
  String? simulate(LoanRequest loan, String action) {
    switch (action) {
      case 'approve':
        return approve(loan);
      case 'reject':
        reject(
          loan,
          'Barang dibutuhkan untuk kegiatan sekolah pada jadwal tersebut.',
        );
      case 'expire':
        // Mensimulasikan waktu pengajuan mundur 2 jam 1 menit agar melewati batas SLA
        loan.submittedAt = DateTime.now()
            .subtract(Duration(hours: _settingsStore.approvalHours, minutes: 1));
        _expireLoan(loan);
        notifyListeners();
      case 'handover':
        final autoCodes = <String>[];
        for (final line in loan.lines) {
          final availableCodes = suggestUnits(loan, line.itemId, 0).take(line.qty).toList();
          if (availableCodes.length < line.qty) {
            return 'Unit ${line.itemName} belum cukup tersedia.';
          }
          autoCodes.addAll(availableCodes);
        }
        return handover(loan, loan.borrower.name, autoCodes);
      case 'due':
        markDue(loan);
      case 'return':
        completeReturn(
          loan,
          {for (final code in loan.unitCodes) code: ItemCondition.layak},
          '',
        );
    }
    return null;
  }
}
