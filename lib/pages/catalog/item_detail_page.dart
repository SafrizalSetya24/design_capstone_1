import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/pages/cart/cart_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class ItemDetailPage extends StatefulWidget {
  final String id;
  final String name;
  final String category;
  final String description;
  final String iconKey;
  final int maxAvailable;
  final ItemKind kind;
  final String satuan;

  const ItemDetailPage({
    super.key,
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.iconKey,
    required this.maxAvailable,
    required this.kind,
    required this.satuan,
  });

  @override
  State<ItemDetailPage> createState() => _ItemDetailPageState();
}

class _ItemDetailPageState extends State<ItemDetailPage> {
  int _qty = 1;

  @override
  void initState() {
    super.initState();
    final cart = context.read<CartStore>();
    final existing = cart.getById(widget.id);
    if (existing != null) {
      _qty = existing.qty;
    }
  }

  void _increment() {
    if (_qty < widget.maxAvailable) {
      setState(() => _qty++);
    }
  }

  void _decrement() {
    if (_qty > 1) {
      setState(() => _qty--);
    }
  }

  void _addToCart() {
    final cart = context.read<CartStore>();
    cart.addItem(
      itemId: widget.id,
      itemName: widget.name,
      kind: widget.kind,
      satuan: widget.satuan,
      iconKey: widget.iconKey,
      qty: _qty,
      maxAvailable: widget.maxAvailable,
      category: widget.category,
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.check_circle,
                    color: Colors.green.shade600, size: 34),
              ),
              const SizedBox(height: 14),
              const Text(
                'Berhasil Masuk Keranjang',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$_qty ${widget.satuan} ${widget.name} telah ditambahkan ke keranjang peminjaman.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(sheetCtx).pop();
                        Navigator.of(context).pop();
                      },
                      child: const Text('Pilih Barang Lain'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.shopping_cart_checkout, size: 18),
                      label: const Text('Buka Keranjang'),
                      onPressed: () {
                        Navigator.of(sheetCtx).pop();
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const CartPage()),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPerUnit = widget.kind == ItemKind.perUnit;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              ShellScope.maybeOf(context)?.go('katalog');
            }
          },
        ),
        title: Text(widget.name),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Alur SOP Langkah 2
                  const BorrowingFlowStepper(
                    currentStep: 2,
                    showRuleNotice: true,
                  ),
                  const SizedBox(height: 16),

                  // Icon Header
                  Center(
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: (isPerUnit ? AppColors.primary : Colors.teal)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: ItemIcon(
                          name: widget.iconKey,
                          size: 52,
                          color: isPerUnit ? AppColors.primary : Colors.teal,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Model Name & Category
                  Text(
                    widget.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${widget.category} • ${widget.kind.label}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Ketersediaan Badge
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Kapasitas Ketersediaan',
                                style: TextStyle(fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(
                              isPerUnit
                                  ? '${widget.maxAvailable} unit tersedia'
                                  : 'Stok: ${widget.maxAvailable} ${widget.satuan}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: widget.maxAvailable > 0
                                    ? Colors.green.shade700
                                    : Colors.red,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.check_circle,
                                  size: 14, color: Colors.green),
                              SizedBox(width: 4),
                              Text('Siap Dipinjam',
                                  style: TextStyle(
                                      color: Colors.green, fontSize: 11)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Deskripsi
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Keterangan Barang',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.description.isNotEmpty
                              ? widget.description
                              : 'Barang inventaris standar sekolah untuk keperluan belajar mengajar.',
                          style: const TextStyle(fontSize: 12.5, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Pemilihan Jumlah (Counter [-] qty [+])
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Jumlah yang Dibutuhkan',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton.filledTonal(
                              onPressed: _qty > 1 ? _decrement : null,
                              icon: const Icon(Icons.remove),
                            ),
                            const SizedBox(width: 20),
                            Text(
                              '$_qty ${widget.satuan}',
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 20),
                            IconButton.filledTonal(
                              onPressed: _qty < widget.maxAvailable
                                  ? _increment
                                  : null,
                              icon: const Icon(Icons.add),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  PrimaryButton(
                    label: 'Tambahkan ke Keranjang',
                    icon: Icons.add_shopping_cart,
                    onPressed: widget.maxAvailable > 0 ? _addToCart : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
