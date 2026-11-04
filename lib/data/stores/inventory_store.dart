import 'package:flutter/foundation.dart' hide Category;
import 'package:sipintar/data/dummy/dummy_data.dart';
import 'package:sipintar/data/models/inventory_models.dart';
import 'package:sipintar/data/models/user_model.dart';
import 'package:sipintar/data/stores/audit_store.dart';
import 'package:sipintar/data/stores/auth_store.dart';

class UnitRef {
  final UnitItem item;
  final AssetUnit unit;
  UnitRef(this.item, this.unit);
}

class InventoryStore extends ChangeNotifier {
  InventoryStore(this._auth, this._audit);
  final AuthStore _auth;
  final AuditStore _audit;

  final List<Category> categories = DummyData.categories();
  final List<UnitItem> items = DummyData.unitItems();
  final List<RepairRecord> repairs = DummyData.repairs();
  final List<ConditionLog> logs = DummyData.conditionLogs();
  int _n = 100;

  String get _actor => _auth.currentUser?.name ?? 'Sistem';
  void _log(String type, String detail) =>
      _audit.log(_actor, _auth.currentUser?.role.label ?? 'Sistem', type, detail);

  UnitItem? itemById(String id) {
    for (final i in items) {
      if (i.id == id) return i;
    }
    return null;
  }

  UnitRef? findByCode(String code) {
    final c = code.trim().toUpperCase();
    for (final i in items) {
      for (final u in i.units) {
        if (u.code == c) return UnitRef(i, u);
      }
    }
    return null;
  }

  List<UnitRef> allUnits() => [for (final i in items) for (final u in i.units) UnitRef(i, u)];
  int get totalUnits => items.fold(0, (a, i) => a + i.total);
  int countCond(ItemCondition c) => items.fold(0, (a, i) => a + i.countCond(c));
  List<String> categoryNames(CategoryType t) => categories.where((c) => c.type == t).map((c) => c.name).toList();

  // ---------- CRUD barang per unit ----------
  String _prefix(String name) {
    final letters = name.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    return letters.length >= 3 ? letters.substring(0, 3) : letters.padRight(3, 'X');
  }

  AssetUnit _newUnit(String prefix, ItemCondition c) {
    var seq = 1;
    String code() => '$prefix-${DateTime.now().year}-${seq.toString().padLeft(3, '0')}';
    while (findByCode(code()) != null) {
      seq++;
    }
    return AssetUnit(
      code: code(),
      condition: c,
      status: switch (c) {
        ItemCondition.layak => UnitStatus.tersedia,
        ItemCondition.perluDiperbaiki => UnitStatus.perbaikan,
        ItemCondition.rusakTotal => UnitStatus.nonaktif,
      },
    );
  }

  UnitItem addItem({
    required String name,
    required String category,
    required String description,
    required String location,
    required int count,
    required ItemCondition condition,
    required String iconKey,
  }) {
    final item = UnitItem(
        id: 'it${_n++}', name: name.trim(), category: category, description: description.trim(),
        location: location.trim(), iconKey: iconKey, units: []);
    final p = _prefix(name);
    for (var i = 0; i < count; i++) {
      item.units.add(_newUnit(p, condition));
    }
    items.add(item);
    _log('Inventaris', 'Menambah barang ${item.name} ($count unit)');
    notifyListeners();
    return item;
  }

  void addUnits(UnitItem item, int count, ItemCondition c) {
    final p = item.units.isNotEmpty ? item.units.first.code.split('-').first : _prefix(item.name);
    for (var i = 0; i < count; i++) {
      item.units.add(_newUnit(p, c));
    }
    _log('Inventaris', 'Menambah $count unit ${item.name}');
    notifyListeners();
  }

  void updateItem(UnitItem item,
      {required String name, required String category, required String description, required String location, required String iconKey}) {
    item.name = name.trim();
    item.category = category;
    item.description = description.trim();
    item.location = location.trim();
    item.iconKey = iconKey;
    _log('Inventaris', 'Mengubah data barang ${item.name}');
    notifyListeners();
  }

  String? deleteItem(UnitItem item) {
    if (item.units.any((u) => u.status == UnitStatus.dipinjam)) {
      return 'Barang masih dipinjam, tidak dapat dihapus.';
    }
    items.remove(item);
    _log('Inventaris', 'Menghapus barang ${item.name}');
    notifyListeners();
    return null;
  }

  // ---------- Status & kondisi ----------
  void releaseUnit(String code) {
    final r = findByCode(code);
    if (r != null) r.unit.status = UnitStatus.tersedia;
    notifyListeners();
  }

  void markBorrowed(List<String> codes) {
    for (final c in codes) {
      final r = findByCode(c);
      if (r != null) r.unit.status = UnitStatus.dipinjam;
    }
    notifyListeners();
  }

  void _apply(AssetUnit u, ItemCondition c) {
    u.condition = c;
    if (u.status == UnitStatus.dipinjam) return;
    u.status = switch (c) {
      ItemCondition.layak => UnitStatus.tersedia,
      ItemCondition.perluDiperbaiki => UnitStatus.perbaikan,
      ItemCondition.rusakTotal => UnitStatus.nonaktif,
    };
  }

  void _addLog(UnitRef r, ItemCondition to, String note) {
    logs.insert(0, ConditionLog(unitCode: r.unit.code, itemName: r.item.name, from: r.unit.condition, to: to,
        note: note, date: DateTime.now(), actor: _actor));
  }

  RepairRecord? reportDamage(String code,
      {required String issue, required ItemCondition severity, String note = ''}) {
    final r = findByCode(code);
    if (r == null) return null;
    _addLog(r, severity, issue);
    _apply(r.unit, severity);
    final rec = RepairRecord(
      id: 'r${_n++}', unitCode: code, itemName: r.item.name, issue: issue, severity: severity,
      status: severity == ItemCondition.rusakTotal ? RepairStatus.tidakDapatDiperbaiki : RepairStatus.menunggu,
      reportedAt: DateTime.now(), updatedAt: DateTime.now(), notes: note,
      confirmed: severity == ItemCondition.rusakTotal,
      finalCondition: severity == ItemCondition.rusakTotal ? ItemCondition.rusakTotal : null,
    );
    repairs.insert(0, rec);
    _log('Inventaris', 'Mencatat kerusakan unit $code');
    notifyListeners();
    return rec;
  }

  void updateRepair(RepairRecord rec, {required RepairStatus status, required String technician, required String notes}) {
    rec.status = status;
    rec.technician = technician.trim().isEmpty ? '-' : technician.trim();
    rec.notes = notes.trim();
    rec.updatedAt = DateTime.now();
    final r = findByCode(rec.unitCode);
    if (status == RepairStatus.tidakDapatDiperbaiki && r != null) {
      _addLog(r, ItemCondition.rusakTotal, 'Tidak dapat diperbaiki');
      _apply(r.unit, ItemCondition.rusakTotal);
      rec.confirmed = true;
      rec.finalCondition = ItemCondition.rusakTotal;
    }
    _log('Perbaikan', 'Status perbaikan ${rec.unitCode}: ${status.label}');
    notifyListeners();
  }

  void confirmRepair(RepairRecord rec, ItemCondition finalCond, String note) {
    final r = findByCode(rec.unitCode);
    if (r != null) {
      _addLog(r, finalCond, note.isEmpty ? 'Pemeriksaan setelah perbaikan' : note);
      _apply(r.unit, finalCond);
    }
    rec.confirmed = true;
    rec.finalCondition = finalCond;
    rec.updatedAt = DateTime.now();
    _log('Perbaikan', 'Konfirmasi pemeriksaan ${rec.unitCode}: ${finalCond.label}');
    notifyListeners();
  }

  // ---------- Kategori ----------
  void addCategory(String name, CategoryType t, String desc) {
    categories.add(Category(id: 'k${_n++}', name: name.trim(), type: t, description: desc.trim()));
    _log('Kategori', 'Menambah kategori ${name.trim()}');
    notifyListeners();
  }

  void updateCategory(Category c, String name, CategoryType t, String desc, void Function(String old, String neu) onRename) {
    final old = c.name;
    c.name = name.trim();
    c.type = t;
    c.description = desc.trim();
    if (old != c.name) {
      for (final i in items) {
        if (i.category == old) i.category = c.name;
      }
      onRename(old, c.name);
    }
    _log('Kategori', 'Mengubah kategori ${c.name}');
    notifyListeners();
  }

  void deleteCategory(Category c) {
    categories.remove(c);
    _log('Kategori', 'Menghapus kategori ${c.name}');
    notifyListeners();
  }

  int usageOf(Category c) => items.where((i) => i.category == c.name).length;
}
