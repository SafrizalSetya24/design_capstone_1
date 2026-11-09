import 'package:sipintar/data/models/inventory_models.dart';
import 'package:sipintar/data/models/user_model.dart';

enum ItemKind {
  perUnit('Barang Per Unit'),
  habisPakai('Barang Habis Pakai');

  final String label;
  const ItemKind(this.label);
}

enum LoanStatus {
  menungguVerifikasiWajah('Menunggu verifikasi wajah'),
  verifikasiBerhasil('Verifikasi berhasil'),
  menungguPersetujuan('Menunggu persetujuan Sapras'),
  disetujui('Disetujui'),
  ditolak('Ditolak'),
  kedaluwarsa('Booking expired (2 jam)'),
  sedangDipinjam('Sedang dipinjam'),
  menungguPengembalian('Menunggu pengembalian'),
  selesai('Selesai / Dikembalikan');

  final String label;
  const LoanStatus(this.label);

  /// Urutan status yang dilalui hingga status ini (untuk riwayat dummy).
  List<LoanStatus> get path {
    const base = [
      LoanStatus.menungguVerifikasiWajah,
      LoanStatus.verifikasiBerhasil,
      LoanStatus.menungguPersetujuan,
    ];
    return switch (this) {
      LoanStatus.menungguVerifikasiWajah => [
          LoanStatus.menungguVerifikasiWajah
        ],
      LoanStatus.verifikasiBerhasil => base.sublist(0, 2),
      LoanStatus.menungguPersetujuan => base,
      LoanStatus.disetujui => [...base, LoanStatus.disetujui],
      LoanStatus.ditolak => [...base, LoanStatus.ditolak],
      LoanStatus.kedaluwarsa => [...base, LoanStatus.kedaluwarsa],
      LoanStatus.sedangDipinjam => [
          ...base,
          LoanStatus.disetujui,
          LoanStatus.sedangDipinjam
        ],
      LoanStatus.menungguPengembalian => [
          ...base,
          LoanStatus.disetujui,
          LoanStatus.sedangDipinjam,
          LoanStatus.menungguPengembalian
        ],
      LoanStatus.selesai => [
          ...base,
          LoanStatus.disetujui,
          LoanStatus.sedangDipinjam,
          LoanStatus.selesai
        ],
    };
  }
}

class Borrower {
  final String id, name, identityLabel, identityValue;
  final UserRole role;
  final String? extraLabel, extraValue;
  const Borrower({
    required this.id,
    required this.name,
    required this.role,
    required this.identityLabel,
    required this.identityValue,
    this.extraLabel,
    this.extraValue,
  });
  factory Borrower.fromUser(AppUser u) => Borrower(
        id: u.id,
        name: u.name,
        role: u.role,
        identityLabel: u.identityLabel,
        identityValue: u.identityValue,
        extraLabel: u.extraLabel,
        extraValue: u.extraValue,
      );
}

class LoanLine {
  final String itemId, itemName, iconKey;
  final ItemKind kind;
  final String satuan;
  int qty;
  int handedOverQty;
  List<String> assignedUnits;
  Map<String, ItemCondition> returnConditions;

  LoanLine({
    required this.itemId,
    required this.itemName,
    required this.iconKey,
    this.kind = ItemKind.perUnit,
    this.satuan = 'unit',
    required this.qty,
    this.handedOverQty = 0,
    List<String>? assignedUnits,
    Map<String, ItemCondition>? returnConditions,
  })  : assignedUnits = assignedUnits ?? [],
        returnConditions = returnConditions ?? {};

  bool get isPerUnit => kind == ItemKind.perUnit;
  bool get isHabisPakai => kind == ItemKind.habisPakai;
}

class LoanEvent {
  final LoanStatus status;
  final DateTime time;
  final String? note;
  LoanEvent(this.status, this.time, [this.note]);
}

class LoanRequest {
  final String id;
  final Borrower borrower;
  final List<LoanLine> lines;
  DateTime start, end;
  String purpose;
  LoanStatus status;
  DateTime submittedAt;
  bool? faceVerified;
  double? faceScore;
  String? rejectReason;
  List<String> unitCodes;
  String? receiver;
  DateTime? handoverAt;
  DateTime? returnedAt;
  Map<String, ItemCondition> returnConditions;
  String? damageNote;
  final List<LoanEvent> events;

  LoanRequest({
    required this.id,
    required this.borrower,
    required this.lines,
    required this.start,
    required this.end,
    required this.purpose,
    required this.status,
    required this.submittedAt,
    this.faceVerified,
    this.faceScore,
    this.rejectReason,
    List<String>? unitCodes,
    this.receiver,
    this.handoverAt,
    this.returnedAt,
    Map<String, ItemCondition>? returnConditions,
    this.damageNote,
    List<LoanEvent>? events,
  })  : unitCodes = unitCodes ?? [],
        returnConditions = returnConditions ?? {},
        events = events ?? [];

  int get totalQty => lines.fold(0, (a, l) => a + l.qty);
  String get summary => lines.map((l) => '${l.qty} ${l.satuan} ${l.itemName}').join(', ');

  DateTime get expiresAt => submittedAt.add(const Duration(hours: 2));
  Duration get remainingTime => expiresAt.difference(DateTime.now());
  bool get isExpired =>
      status == LoanStatus.menungguPersetujuan && remainingTime.isNegative;

  List<LoanLine> get perUnitLines =>
      lines.where((l) => l.kind == ItemKind.perUnit).toList();
  List<LoanLine> get consumableLines =>
      lines.where((l) => l.kind == ItemKind.habisPakai).toList();
  bool get hasPerUnit => perUnitLines.isNotEmpty;
  bool get hasConsumables => consumableLines.isNotEmpty;
  bool get isMixed => hasPerUnit && hasConsumables;
}

enum ConsumableStatus {
  menunggu('Menunggu persetujuan'),
  disetujui('Disetujui, menunggu penyerahan'),
  ditolak('Ditolak'),
  diserahkan('Sudah diserahkan');

  final String label;
  const ConsumableStatus(this.label);
}

class ConsumableLine {
  final String itemId, itemName, satuan, iconKey;
  int qty;
  int? approved;
  ConsumableLine({
    required this.itemId,
    required this.itemName,
    required this.satuan,
    required this.iconKey,
    required this.qty,
    this.approved,
  });
}

class ConsumableRequest {
  final String id;
  final Borrower requester;
  final List<ConsumableLine> lines;
  String purpose;
  ConsumableStatus status;
  final DateTime createdAt;
  String? reason;
  DateTime? handedAt;
  ConsumableRequest({
    required this.id,
    required this.requester,
    required this.lines,
    required this.purpose,
    required this.status,
    required this.createdAt,
    this.reason,
    this.handedAt,
  });
  String get summary =>
      lines.map((l) => '${l.qty} ${l.satuan} ${l.itemName}').join(', ');
}
