import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

int _usage(InventoryStore inv, ConsumableStore cons, Category c) =>
    inv.items.where((i) => i.category == c.name).length + cons.items.where((i) => i.category == c.name).length;

class CategoryManagementPage extends StatefulWidget {
  const CategoryManagementPage({super.key});
  @override
  State<CategoryManagementPage> createState() => _CategoryManagementPageState();
}

class _CategoryManagementPageState extends State<CategoryManagementPage> {
  String _type = 'Semua';

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryStore>();
    final cons = context.watch<ConsumableStore>();
    final list = inv.categories.where((c) => _type == 'Semua' || c.type.label == _type).toList();
    return AppPage(
      title: 'Manajemen Kategori',
      fab: FloatingActionButton.extended(
        onPressed: () => push(context, const CategoryFormPage()),
        icon: const Icon(Icons.add),
        label: const Text('Tambah kategori'),
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
      ),
      body: PageList(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
        FilterRow(label: 'Jenis', options: const ['Semua', 'Per unit', 'Habis pakai'], selected: _type, onSelected: (v) => setState(() => _type = v)),
        const SizedBox(height: 8),
        if (list.isEmpty)
          const SizedBox(height: 240, child: EmptyState(icon: Icons.category_outlined, title: 'Belum ada kategori', message: 'Tambahkan kategori untuk mengelompokkan barang.'))
        else
          ResponsiveGrid(minItemWidth: 320, children: [
            for (final c in list)
              AppCard(
                onTap: () => push(context, CategoryDetailPage(categoryId: c.id)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                    StatusBadge(c.type.label, tone: c.type == CategoryType.perUnit ? BadgeTone.info : BadgeTone.success),
                  ]),
                  const SizedBox(height: 6),
                  Text(c.description.isEmpty ? '-' : c.description, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  Row(children: [
                    Text('${_usage(inv, cons, c)} barang', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const Spacer(),
                    IconButton(tooltip: 'Edit', icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => push(context, CategoryFormPage(category: c))),
                    IconButton(
                      tooltip: 'Hapus',
                      icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.danger),
                      onPressed: () => _delete(context, inv, cons, c),
                    ),
                  ]),
                ]),
              ),
          ]),
      ]),
    );
  }
}

Future<void> _delete(BuildContext context, InventoryStore inv, ConsumableStore cons, Category c) async {
  final n = _usage(inv, cons, c);
  if (n > 0) {
    snack(context, 'Kategori masih dipakai oleh $n barang. Pindahkan barang terlebih dahulu.', error: true);
    return;
  }
  final ok = await confirm(context, title: 'Hapus kategori?', message: 'Kategori "${c.name}" akan dihapus.', confirmLabel: 'Hapus', danger: true);
  if (ok && context.mounted) {
    inv.deleteCategory(c);
    snack(context, 'Kategori dihapus.');
  }
}

class CategoryDetailPage extends StatelessWidget {
  final String categoryId;
  const CategoryDetailPage({super.key, required this.categoryId});

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryStore>();
    final cons = context.watch<ConsumableStore>();
    final m = inv.categories.where((c) => c.id == categoryId);
    if (m.isEmpty) {
      return const AppPage(title: 'Detail Kategori', body: EmptyState(icon: Icons.category_outlined, title: 'Kategori tidak ditemukan', message: ''));
    }
    final c = m.first;
    final names = [...inv.items.where((i) => i.category == c.name).map((i) => i.name), ...cons.items.where((i) => i.category == c.name).map((i) => i.name)];
    return AppPage(
      title: 'Detail Kategori',
      actions: [IconButton(tooltip: 'Edit', icon: const Icon(Icons.edit_outlined), onPressed: () => push(context, CategoryFormPage(category: c)))],
      body: PageList(children: [
        ResponsiveBody(
          maxWidth: 820,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            InfoCard(title: c.name, trailing: StatusBadge(c.type.label, tone: c.type == CategoryType.perUnit ? BadgeTone.info : BadgeTone.success), rows: [
              ('Deskripsi', c.description.isEmpty ? '-' : c.description),
              ('Jumlah barang', '${names.length}'),
            ]),
            const SizedBox(height: AppSpacing.md),
            const SectionHeader('Barang dalam kategori'),
            const SizedBox(height: 8),
            if (names.isEmpty)
              const AppCard(child: Text('Belum ada barang pada kategori ini.', style: TextStyle(color: AppColors.textSecondary)))
            else
              AppCard(child: Column(children: [for (final n in names) ListTile(dense: true, leading: const Icon(Icons.inventory_2_outlined), title: Text(n))])),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.danger, side: const BorderSide(color: AppColors.danger)),
              onPressed: () async {
                await _delete(context, inv, cons, c);
                if (context.mounted && !inv.categories.contains(c)) Navigator.of(context).pop();
              },
              icon: const Icon(Icons.delete_outline),
              label: const Text('Hapus kategori'),
            ),
          ]),
        ),
      ]),
    );
  }
}

class CategoryFormPage extends StatefulWidget {
  final Category? category;
  const CategoryFormPage({super.key, this.category});
  @override
  State<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends State<CategoryFormPage> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.category?.name ?? '');
  late final _desc = TextEditingController(text: widget.category?.description ?? '');
  late CategoryType _type = widget.category?.type ?? CategoryType.perUnit;

  @override
  void dispose() {
    _name.dispose();
    _desc.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final inv = context.read<InventoryStore>();
    final cons = context.read<ConsumableStore>();
    final dup = inv.categories.any((c) => c.id != widget.category?.id && c.name.toLowerCase() == _name.text.trim().toLowerCase());
    if (dup) {
      snack(context, 'Nama kategori sudah ada.', error: true);
      return;
    }
    if (widget.category == null) {
      inv.addCategory(_name.text, _type, _desc.text);
    } else {
      inv.updateCategory(widget.category!, _name.text, _type, _desc.text, (o, n) => cons.renameCategory(o, n));
    }
    snack(context, 'Kategori disimpan.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => FormScaffold(
        title: widget.category == null ? 'Tambah Kategori' : 'Edit Kategori',
        formKey: _form,
        submitLabel: 'Simpan kategori',
        onSubmit: _save,
        children: [
          AppTextField(controller: _name, label: 'Nama kategori', icon: Icons.category_outlined, validator: (v) => (v == null || v.trim().length < 3) ? 'Nama minimal 3 karakter' : null),
          SegmentedButton<CategoryType>(
            showSelectedIcon: false,
            segments: [for (final t in CategoryType.values) ButtonSegment(value: t, label: Text(t.label))],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          AppTextField(controller: _desc, label: 'Deskripsi', icon: Icons.notes, maxLines: 3),
        ],
      );
}
