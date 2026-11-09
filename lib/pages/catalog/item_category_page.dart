import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/pages/catalog/item_detail_page.dart';
import 'package:sipintar/pages/cart/cart_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class ItemCategoryPage extends StatefulWidget {
  final int initialTab;
  const ItemCategoryPage({super.key, this.initialTab = 0});

  @override
  State<ItemCategoryPage> createState() => _ItemCategoryPageState();
}

class _ItemCategoryPageState extends State<ItemCategoryPage> {
  String _searchQuery = '';
  final String _selectedCategory = 'Semua';
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inv = context.watch<InventoryStore>();
    final cons = context.watch<ConsumableStore>();
    final cart = context.watch<CartStore>();

    final perUnitItems = inv.items.where((it) {
      final matchSearch = it.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          it.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchCat = _selectedCategory == 'Semua' || it.category == _selectedCategory;
      return matchSearch && matchCat;
    }).toList();

    final consumableItems = cons.items.where((it) {
      final matchSearch = it.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          it.description.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchCat = _selectedCategory == 'Semua' || it.category == _selectedCategory;
      return matchSearch && matchCat;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Kembali',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              ShellScope.maybeOf(context)?.go('beranda');
            }
          },
        ),
        title: const Text('Katalog Barang'),
        actions: [
          IconButton(
            tooltip: 'Buka Keranjang',
            icon: Badge(
              isLabelVisible: !cart.isEmpty,
              label: Text('${cart.itemCount}'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartPage()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Alur SOP Langkah 1
          const BorrowingFlowStepper(
            currentStep: 1,
            showRuleNotice: true,
          ),

          // Selector Klasifikasi Barang (Slide 6 & 7 PPT)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _selectedTab = 0),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedTab == 0
                            ? AppColors.primary
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedTab == 0
                              ? AppColors.primary
                              : Colors.grey.withValues(alpha: 0.25),
                          width: _selectedTab == 0 ? 1.5 : 1,
                        ),
                        boxShadow: _selectedTab == 0
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.devices_other_rounded,
                            size: 20,
                            color: _selectedTab == 0 ? Colors.white : AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Barang Per Unit',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedTab == 0 ? Colors.white : AppColors.navy,
                                  ),
                                ),
                                Text(
                                  'Wajib Kembali (${inv.items.length})',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: _selectedTab == 0
                                        ? Colors.white.withValues(alpha: 0.85)
                                        : theme.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => _selectedTab = 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1
                            ? Colors.teal.shade700
                            : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _selectedTab == 1
                              ? Colors.teal.shade700
                              : Colors.grey.withValues(alpha: 0.25),
                          width: _selectedTab == 1 ? 1.5 : 1,
                        ),
                        boxShadow: _selectedTab == 1
                            ? [
                                BoxShadow(
                                  color: Colors.teal.withValues(alpha: 0.2),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.draw_outlined,
                            size: 20,
                            color: _selectedTab == 1 ? Colors.white : Colors.teal.shade700,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Barang Habis Pakai',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.bold,
                                    color: _selectedTab == 1 ? Colors.white : AppColors.navy,
                                  ),
                                ),
                                Text(
                                  'Tidak Kembali (${cons.items.length})',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: _selectedTab == 1
                                        ? Colors.white.withValues(alpha: 0.85)
                                        : theme.hintColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bar Pencarian
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                hintText: _selectedTab == 0
                    ? 'Cari model laptop, proyektor, kamera...'
                    : 'Cari spidol, kertas, pulpen, ATK...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),

          // Konten Katalog
          Expanded(
            child: _selectedTab == 0
                ? _buildPerUnitList(context, perUnitItems, cart)
                : _buildConsumablesList(context, consumableItems, cart),
          ),
        ],
      ),
      floatingActionButton: !cart.isEmpty
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.shopping_cart_checkout),
              label: Text('Keranjang (${cart.itemCount})'),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CartPage()),
              ),
            )
          : null,
    );
  }

  Widget _buildPerUnitList(BuildContext context, List<UnitItem> items, CartStore cart) {
    if (items.isEmpty) {
      return const Center(child: Text('Tidak ada barang per unit yang cocok.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final item = items[idx];
        final available = item.available;
        final inCart = cart.getById(item.id);

        return AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: ItemIcon(name: item.iconKey, size: 28, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.category,
                      style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: available > 0
                                ? Colors.green.withValues(alpha: 0.12)
                                : Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            available > 0 ? 'Tersedia: $available unit' : 'Tidak tersedia',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: available > 0 ? Colors.green.shade700 : Colors.red.shade700,
                            ),
                          ),
                        ),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            if (inCart != null)
                              Text(
                                'Di keranjang: ${inCart.qty}',
                                style: const TextStyle(fontSize: 11, color: AppColors.primary),
                              ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: available > 0
                                  ? () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ItemDetailPage(
                                            id: item.id,
                                            name: item.name,
                                            category: item.category,
                                            description: item.description,
                                            iconKey: item.iconKey,
                                            maxAvailable: available,
                                            kind: ItemKind.perUnit,
                                            satuan: 'unit',
                                          ),
                                        ),
                                      )
                                  : null,
                              child: const Text('Pilih', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildConsumablesList(BuildContext context, List<ConsumableItem> items, CartStore cart) {
    if (items.isEmpty) {
      return const Center(child: Text('Tidak ada barang habis pakai yang cocok.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, idx) {
        final item = items[idx];
        final stock = item.stock;
        final inCart = cart.getById(item.id);

        return AppCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: ItemIcon(name: item.iconKey, size: 28, color: Colors.teal),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.category} • Satuan: ${item.satuan}',
                      style: TextStyle(fontSize: 11.5, color: Theme.of(context).hintColor),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: stock > 0
                                ? Colors.teal.withValues(alpha: 0.12)
                                : Colors.red.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            stock > 0 ? 'Stok: $stock ${item.satuan}' : 'Stok habis',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: stock > 0 ? Colors.teal.shade800 : Colors.red.shade700,
                            ),
                          ),
                        ),
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            if (inCart != null)
                              Text(
                                'Di keranjang: ${inCart.qty}',
                                style: const TextStyle(fontSize: 11, color: Colors.teal),
                              ),
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.teal.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: stock > 0
                                  ? () => Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => ItemDetailPage(
                                            id: item.id,
                                            name: item.name,
                                            category: item.category,
                                            description: item.description,
                                            iconKey: item.iconKey,
                                            maxAvailable: stock,
                                            kind: ItemKind.habisPakai,
                                            satuan: item.satuan,
                                          ),
                                        ),
                                      )
                                  : null,
                              child: const Text('Pilih', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Colors.white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
