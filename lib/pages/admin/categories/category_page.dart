import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class AdminCategoryPage extends StatelessWidget {
  const AdminCategoryPage({super.key});

  void _showAddCategoryDialog(BuildContext context, InventoryStore inv) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    CategoryType type = CategoryType.perUnit;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Tambah Kategori Master Data'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Nama Kategori (contoh: Elektronik, ATK)'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CategoryType>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'Jenis Kategori'),
                items: CategoryType.values.map((t) {
                  return DropdownMenuItem(value: t, child: Text(t.label));
                }).toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => type = v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Deskripsi Kategori'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            FilledButton(
              onPressed: () {
                if (nameCtrl.text.isNotEmpty) {
                  inv.addCategory(nameCtrl.text.trim(), type, descCtrl.text.trim());
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Kategori berhasil ditambahkan.')),
                  );
                }
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryStore>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Master Data Kategori'),
      ),
      body: SafeArea(
        child: inv.categories.isEmpty
            ? const Center(child: Text('Belum ada kategori yang terdaftar.'))
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 960),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: inv.categories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, idx) {
                      final cat = inv.categories[idx];
                      final isPerUnit = cat.type == CategoryType.perUnit;

                      return AppCard(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (isPerUnit ? AppColors.primary : Colors.teal).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isPerUnit ? Icons.devices_other : Icons.draw_outlined,
                                color: isPerUnit ? AppColors.primary : Colors.teal,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                                  Text(cat.type.label, style: TextStyle(fontSize: 11, color: isPerUnit ? AppColors.primary : Colors.teal)),
                                  if (cat.description.isNotEmpty)
                                    Text(cat.description, style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Tambah Kategori'),
        onPressed: () => _showAddCategoryDialog(context, inv),
      ),
    );
  }
}
