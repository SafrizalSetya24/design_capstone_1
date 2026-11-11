import 'package:flutter/foundation.dart';
import 'package:sipintar/data/models/loan_models.dart';

// State management keranjang peminjaman barang (Mixed Cart: unit fisik & barang habis pakai)
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

  /// Daftar item di keranjang (Unmodifiable list untuk mencegah mutasi langsung)
  List<CartItem> get items => List.unmodifiable(_items);

  /// Jumlah jenis barang di keranjang
  int get itemCount => _items.length;

  /// Status apakah keranjang sedang kosong
  bool get isEmpty => _items.isEmpty;

  /// Total unit / kuantitas barang di keranjang
  int get totalQty => _items.fold(0, (sum, item) => sum + item.qty);

  /// Memeriksa apakah suatu barang sudah ada di keranjang
  bool contains(String itemId) => _items.any((item) => item.itemId == itemId);

  /// Mengambil data item keranjang berdasarkan ID barang
  CartItem? getById(String itemId) {
    try {
      return _items.firstWhere((item) => item.itemId == itemId);
    } catch (_) {
      return null;
    }
  }

  // Kelola item keranjang
  /// Menambahkan barang ke keranjang atau menambah jumlah jika sudah ada
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
    final existingIndex = _items.indexWhere((item) => item.itemId == itemId);
    if (existingIndex >= 0) {
      final currentItem = _items[existingIndex];
      final newQty = (currentItem.qty + qty).clamp(1, maxAvailable);
      _items[existingIndex] = currentItem.copyWith(qty: newQty);
    } else {
      _items.add(
        CartItem(
          itemId: itemId,
          itemName: itemName,
          kind: kind,
          satuan: satuan,
          iconKey: iconKey,
          qty: qty.clamp(1, maxAvailable),
          maxAvailable: maxAvailable,
          category: category,
        ),
      );
    }
    notifyListeners();
  }

  /// Memperbarui kuantitas barang tertentu di keranjang
  void updateQty(String itemId, int newQty) {
    final targetIndex = _items.indexWhere((item) => item.itemId == itemId);
    if (targetIndex >= 0) {
      if (newQty <= 0) {
        _items.removeAt(targetIndex);
      } else {
        final currentItem = _items[targetIndex];
        _items[targetIndex] = currentItem.copyWith(
          qty: newQty.clamp(1, currentItem.maxAvailable),
        );
      }
      notifyListeners();
    }
  }

  /// Menghapus satu jenis barang dari keranjang
  void removeItem(String itemId) {
    _items.removeWhere((item) => item.itemId == itemId);
    notifyListeners();
  }

  /// Mengosongkan keranjang setelah berhasil checkout / submit
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
