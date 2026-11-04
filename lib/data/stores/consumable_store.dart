import 'package:flutter/foundation.dart';
import 'package:sipintar/data/dummy/dummy_data.dart';
import 'package:sipintar/data/models/inventory_models.dart';
import 'package:sipintar/data/models/loan_models.dart';
import 'package:sipintar/data/models/misc_models.dart';
import 'package:sipintar/data/models/user_model.dart';
import 'package:sipintar/data/stores/audit_store.dart';
import 'package:sipintar/data/stores/auth_store.dart';
import 'package:sipintar/data/stores/notification_store.dart';

class ConsumableStore extends ChangeNotifier {
  ConsumableStore(this._auth, this._audit, this._notif);
  final AuthStore _auth;
  final AuditStore _audit;
  final NotificationStore _notif;

  final List<ConsumableItem> items = DummyData.consumables();
  final List<ConsumableRequest> requests = DummyData.consumableRequests();
  final List<StockMovement> movements = DummyData.movements();
  int _n = 100;

  String get _actor => _auth.currentUser?.name ?? 'Sistem';
  void _log(String type, String detail) =>
      _audit.log(_actor, _auth.currentUser?.role.label ?? 'Sistem', type, detail);

  ConsumableItem? itemById(String id) {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  List<ConsumableItem> get lowStock => items.where((i) => i.low).toList();
  int get totalStock => items.fold(0, (a, i) => a + i.stock);
  List<ConsumableRequest> forUser(String id) =>
      requests.where((r) => r.requester.id == id).toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  int countStatus(ConsumableStatus s) => requests.where((r) => r.status == s).length;

  void _move(ConsumableItem i, bool isIn, int qty, String note) {
    movements.insert(0, StockMovement(id: 'm${_n++}', itemId: i.id, itemName: i.name, isIn: isIn, qty: qty,
        date: DateTime.now(), note: note, actor: _actor));
  }

  void renameCategory(String old, String neu) {
    for (final i in items) {
      if (i.category == old) i.category = neu;
    }
    notifyListeners();
  }

  // ---------- CRUD ----------
  ConsumableItem addItem({
    required String name,
    required String category,
    required String satuan,
    required int stock,
    required int minStock,
    required String location,
    required String description,
    required String iconKey,
  }) {
    final i = ConsumableItem(id: 'cs${_n++}', name: name.trim(), category: category, satuan: satuan.trim(), stock: 0,
        minStock: minStock, location: location.trim(), description: description.trim(), iconKey: iconKey);
    items.add(i);
    if (stock > 0) {
      i.stock = stock;
      _move(i, true, stock, 'Stok awal');
    }
    _log('Stok', 'Menambah barang habis pakai ${i.name}');
    notifyListeners();
    return i;
  }

  void updateItem(ConsumableItem i,
      {required String name, required String category, required String satuan, required int stock,
      required int minStock, required String location, required String description, required String iconKey}) {
    i.name = name.trim();
    i.category = category;
    i.satuan = satuan.trim();
    i.minStock = minStock;
    i.location = location.trim();
    i.description = description.trim();
    i.iconKey = iconKey;
    if (stock != i.stock) {
      final diff = stock - i.stock;
      _move(i, diff > 0, diff.abs(), 'Koreksi stok');
      i.stock = stock;
    }
    _log('Stok', 'Mengubah data ${i.name}');
    notifyListeners();
  }

  void deleteItem(ConsumableItem i) {
    items.remove(i);
    _log('Stok', 'Menghapus barang ${i.name}');
    notifyListeners();
  }

  void addStock(ConsumableItem i, int qty, String note) {
    i.stock += qty;
    _move(i, true, qty, note.isEmpty ? 'Barang masuk' : note);
    _log('Stok', 'Barang masuk ${i.name} (+$qty ${i.satuan})');
    notifyListeners();
  }

  String? removeStock(ConsumableItem i, int qty, String note) {
    if (qty > i.stock) return 'Jumlah melebihi stok tersedia (${i.stock} ${i.satuan}).';
    i.stock -= qty;
    _move(i, false, qty, note.isEmpty ? 'Barang keluar' : note);
    _log('Stok', 'Barang keluar ${i.name} (-$qty ${i.satuan})');
    notifyListeners();
    return null;
  }

  // ---------- Permintaan ----------
  ConsumableRequest submit(Borrower who, List<ConsumableLine> lines, String purpose) {
    final r = ConsumableRequest(
      id: 'HBP-${(12 + _n++).toString().padLeft(4, '0')}', requester: who, lines: lines, purpose: purpose.trim(),
      status: ConsumableStatus.menunggu, createdAt: DateTime.now(),
    );
    requests.add(r);
    _notif.add(who.id, NotifType.habisPakai, 'Permintaan barang terkirim',
        'Permintaan ${r.id} (${r.summary}) menunggu persetujuan Sapras.', refId: r.id, loan: false);
    _log('Permintaan', 'Mengajukan permintaan barang ${r.id}');
    notifyListeners();
    return r;
  }

  void approve(ConsumableRequest r, Map<String, int> approved) {
    for (final l in r.lines) {
      l.approved = approved[l.itemId] ?? l.qty;
    }
    r.status = ConsumableStatus.disetujui;
    _notif.add(r.requester.id, NotifType.persetujuan, 'Permintaan barang disetujui',
        'Permintaan ${r.id} disetujui. Ambil barang di Ruang Sapras.', refId: r.id, loan: false);
    _log('Persetujuan', 'Menyetujui permintaan ${r.id}');
    notifyListeners();
  }

  void reject(ConsumableRequest r, String reason) {
    r.status = ConsumableStatus.ditolak;
    r.reason = reason.trim();
    _notif.add(r.requester.id, NotifType.penolakan, 'Permintaan barang ditolak',
        'Permintaan ${r.id} ditolak. Alasan: ${r.reason}', refId: r.id, loan: false);
    _log('Penolakan', 'Menolak permintaan ${r.id}');
    notifyListeners();
  }

  /// Stok baru berkurang setelah penyerahan dikonfirmasi.
  String? confirmHandover(ConsumableRequest r) {
    for (final l in r.lines) {
      final i = itemById(l.itemId);
      if (i == null || (l.approved ?? 0) > i.stock) {
        return 'Stok ${l.itemName} tidak mencukupi untuk diserahkan.';
      }
    }
    for (final l in r.lines) {
      final i = itemById(l.itemId)!;
      final q = l.approved ?? 0;
      i.stock -= q;
      _move(i, false, q, 'Penyerahan ${r.id} ke ${r.requester.name}');
    }
    r.status = ConsumableStatus.diserahkan;
    r.handedAt = DateTime.now();
    _notif.add(r.requester.id, NotifType.habisPakai, 'Barang telah diserahkan',
        'Barang untuk permintaan ${r.id} sudah diserahkan.', refId: r.id, loan: false);
    _log('Penyerahan', 'Menyerahkan barang habis pakai ${r.id}');
    notifyListeners();
    return null;
  }
}
