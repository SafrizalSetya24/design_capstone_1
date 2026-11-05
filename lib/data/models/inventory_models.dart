enum ItemCondition { layak, perluDiperbaiki, rusakTotal }

extension ItemConditionX on ItemCondition {
  String get label => switch (this) {
        ItemCondition.layak => 'Layak pakai',
        ItemCondition.perluDiperbaiki => 'Perlu diperbaiki',
        ItemCondition.rusakTotal => 'Rusak total',
      };
}

enum UnitStatus { tersedia, dipinjam, perbaikan, nonaktif }

extension UnitStatusX on UnitStatus {
  String get label => switch (this) {
        UnitStatus.tersedia => 'Tersedia',
        UnitStatus.dipinjam => 'Sedang dipinjam',
        UnitStatus.perbaikan => 'Dalam perbaikan',
        UnitStatus.nonaktif => 'Tidak aktif',
      };
}

class AssetUnit {
  final String code;
  ItemCondition condition;
  UnitStatus status;
  AssetUnit(
      {required this.code,
      this.condition = ItemCondition.layak,
      this.status = UnitStatus.tersedia});
  bool get borrowable =>
      condition == ItemCondition.layak && status == UnitStatus.tersedia;
}

class UnitItem {
  final String id;
  String name;
  String category;
  String description;
  String location;
  String iconKey;
  final List<AssetUnit> units;
  UnitItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.location,
    required this.iconKey,
    required this.units,
  });
  int get total => units.length;
  int get available => units.where((u) => u.borrowable).length;
  int countCond(ItemCondition c) => units.where((u) => u.condition == c).length;
  bool hasCond(ItemCondition c) => units.any((u) => u.condition == c);
  String get conditionSummary {
    final l = countCond(ItemCondition.layak);
    if (l == total) return 'Layak pakai';
    return '$l dari $total layak pakai';
  }
}

class ConsumableItem {
  final String id;
  String name;
  String category;
  String satuan;
  int stock;
  int minStock;
  String location;
  String description;
  String iconKey;
  ConsumableItem({
    required this.id,
    required this.name,
    required this.category,
    required this.satuan,
    required this.stock,
    required this.minStock,
    required this.location,
    required this.description,
    required this.iconKey,
  });
  bool get low => stock <= minStock;
}

class StockMovement {
  final String id, itemId, itemName, note, actor;
  final bool isIn;
  final int qty;
  final DateTime date;
  StockMovement({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.isIn,
    required this.qty,
    required this.date,
    required this.note,
    required this.actor,
  });
}

enum RepairStatus { menunggu, diperbaiki, selesai, tidakDapatDiperbaiki }

extension RepairStatusX on RepairStatus {
  String get label => switch (this) {
        RepairStatus.menunggu => 'Menunggu perbaikan',
        RepairStatus.diperbaiki => 'Sedang diperbaiki',
        RepairStatus.selesai => 'Selesai diperbaiki',
        RepairStatus.tidakDapatDiperbaiki => 'Tidak dapat diperbaiki',
      };
}

class RepairRecord {
  final String id, unitCode, itemName, issue;
  final ItemCondition severity;
  RepairStatus status;
  final DateTime reportedAt;
  DateTime updatedAt;
  String technician;
  String notes;
  bool confirmed;
  ItemCondition? finalCondition;
  RepairRecord({
    required this.id,
    required this.unitCode,
    required this.itemName,
    required this.issue,
    required this.severity,
    required this.status,
    required this.reportedAt,
    required this.updatedAt,
    this.technician = '-',
    this.notes = '',
    this.confirmed = false,
    this.finalCondition,
  });
}

class ConditionLog {
  final String unitCode, itemName, note, actor;
  final ItemCondition from, to;
  final DateTime date;
  ConditionLog({
    required this.unitCode,
    required this.itemName,
    required this.from,
    required this.to,
    required this.note,
    required this.date,
    required this.actor,
  });
}

enum CategoryType { perUnit, habisPakai }

extension CategoryTypeX on CategoryType {
  String get label => this == CategoryType.perUnit ? 'Per unit' : 'Habis pakai';
}

class Category {
  final String id;
  String name;
  CategoryType type;
  String description;
  Category(
      {required this.id,
      required this.name,
      required this.type,
      required this.description});
}
