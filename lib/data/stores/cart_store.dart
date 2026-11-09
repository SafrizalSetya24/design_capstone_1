import 'package:flutter/foundation.dart';
import 'package:sipintar/data/models/loan_models.dart';

class CartItem {
  final String itemId;
  final String itemName;
  final ItemKind kind;
  final String satuan;
  final String iconKey;
  int qty;
  final int maxAvailable;
  final String category;

  CartItem({
    required this.itemId,
    required this.itemName,
    required this.kind,
    required this.satuan,
    required this.iconKey,
    required this.qty,
    required this.maxAvailable,
    this.category = '',
  });

  CartItem copyWith({int? qty}) {
    return CartItem(
      itemId: itemId,
      itemName: itemName,
      kind: kind,
      satuan: satuan,
      iconKey: iconKey,
      qty: qty ?? this.qty,
      maxAvailable: maxAvailable,
      category: category,
    );
  }
}

class CartStore extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);
  int get itemCount => _items.length;
  bool get isEmpty => _items.isEmpty;

  int get totalQty => _items.fold(0, (sum, item) => sum + item.qty);

  bool contains(String itemId) => _items.any((i) => i.itemId == itemId);

  CartItem? getById(String itemId) {
    try {
      return _items.firstWhere((i) => i.itemId == itemId);
    } catch (_) {
      return null;
    }
  }

  void addItem({
    required String itemId,
    required String itemName,
    required ItemKind kind,
    required String satuan,
    required String iconKey,
    required int qty,
    required int maxAvailable,
    String category = '',
  }) {
    final idx = _items.indexWhere((i) => i.itemId == itemId);
    if (idx >= 0) {
      final cur = _items[idx];
      final newQty = (cur.qty + qty).clamp(1, maxAvailable);
      _items[idx] = cur.copyWith(qty: newQty);
    } else {
      _items.add(CartItem(
        itemId: itemId,
        itemName: itemName,
        kind: kind,
        satuan: satuan,
        iconKey: iconKey,
        qty: qty.clamp(1, maxAvailable),
        maxAvailable: maxAvailable,
        category: category,
      ));
    }
    notifyListeners();
  }

  void updateQty(String itemId, int newQty) {
    final idx = _items.indexWhere((i) => i.itemId == itemId);
    if (idx >= 0) {
      if (newQty <= 0) {
        _items.removeAt(idx);
      } else {
        final cur = _items[idx];
        _items[idx] = cur.copyWith(qty: newQty.clamp(1, cur.maxAvailable));
      }
      notifyListeners();
    }
  }

  void removeItem(String itemId) {
    _items.removeWhere((i) => i.itemId == itemId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
