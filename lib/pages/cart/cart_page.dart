import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/pages/catalog/item_category_page.dart';
import 'package:sipintar/pages/borrowing/borrowing_detail_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class CartPage extends StatelessWidget {
  final bool isSubPage;
  const CartPage({super.key, this.isSubPage = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cart = context.watch<CartStore>();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: isSubPage && Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Kembali',
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        title: const Text('Keranjang Peminjaman'),
        actions: [
          if (!cart.isEmpty)
            IconButton(
              tooltip: 'Kosongkan Keranjang',
              icon: const Icon(Icons.delete_outline),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Kosongkan Keranjang?'),
                    content: const Text(
                        'Semua barang yang telah Anda pilih akan dihapus dari keranjang.'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal')),
                      FilledButton(
                        onPressed: () {
                          cart.clear();
                          Navigator.pop(ctx);
                        },
                        child: const Text('Kosongkan'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.remove_shopping_cart_outlined,
                        size: 72, color: theme.hintColor),
                    const SizedBox(height: 16),
                    Text(
                      'Keranjang Masih Kosong',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Silakan pilih barang per unit atau barang habis pakai yang ingin Anda pinjam dari katalog.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: theme.hintColor, fontSize: 13),
                    ),
                    const SizedBox(height: 24),
                    FilledButton.icon(
                      icon: const Icon(Icons.search),
                      label: const Text('Buka Katalog Barang'),
                      onPressed: () => Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                            builder: (_) => const ItemCategoryPage()),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: Column(
                    children: [
                      // Alur SOP Langkah 3
                      const BorrowingFlowStepper(
                        currentStep: 3,
                      ),

                      // Pemberitahuan penggabungan jenis barang (mixed cart)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.blue.withValues(alpha: 0.2)),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.inventory_outlined,
                                  size: 16, color: AppColors.primary),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Mixed Cart: Anda dapat meminjam beberapa barang per-unit dan ATK sekaligus dalam 1 pengajuan.',
                                  style: TextStyle(
                                      fontSize: 11.5, color: AppColors.navy),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // List Barang di Keranjang
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: cart.items.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, idx) {
                            final item = cart.items[idx];
                            final isPerUnit = item.kind == ItemKind.perUnit;

                            return AppCard(
                              padding: const EdgeInsets.all(14),
                              child: Row(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      color: (isPerUnit
                                              ? AppColors.primary
                                              : Colors.teal)
                                          .withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: ItemIcon(
                                        name: item.iconKey,
                                        size: 26,
                                        color: isPerUnit
                                            ? AppColors.primary
                                            : Colors.teal,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.itemName,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          item.kind.label,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: isPerUnit
                                                ? AppColors.primary
                                                : Colors.teal,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Counter Controls
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(
                                            Icons.remove_circle_outline,
                                            size: 20),
                                        onPressed: item.qty > 1
                                            ? () => cart.updateQty(
                                                item.itemId, item.qty - 1)
                                            : () =>
                                                cart.removeItem(item.itemId),
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${item.qty} ${item.satuan}',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12),
                                      ),
                                      const SizedBox(width: 4),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(
                                            Icons.add_circle_outline,
                                            size: 20),
                                        onPressed: item.qty < item.maxAvailable
                                            ? () => cart.updateQty(
                                                item.itemId, item.qty + 1)
                                            : null,
                                      ),
                                      const SizedBox(width: 6),
                                      IconButton(
                                        visualDensity: VisualDensity.compact,
                                        padding: const EdgeInsets.all(4),
                                        constraints: const BoxConstraints(),
                                        icon: const Icon(Icons.delete_outline,
                                            size: 19, color: Colors.red),
                                        onPressed: () =>
                                            cart.removeItem(item.itemId),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),

                      // Bottom Summary & Proceed Button
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, -3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Jenis Barang:',
                                    style: TextStyle(fontSize: 13)),
                                Text(
                                  '${cart.itemCount} jenis',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Kuantitas:',
                                    style: TextStyle(fontSize: 13)),
                                Text(
                                  '${cart.totalQty} item',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.add),
                                    label: const Text('Tambah Lagi'),
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const ItemCategoryPage()),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: PrimaryButton(
                                    label: 'Lanjutkan Detail',
                                    icon: Icons.arrow_forward,
                                    onPressed: () => Navigator.of(context).push(
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const BorrowingDetailPage()),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
