import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/inventory/barcode_pages.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

/// Form tambah/edit inventaris (barang per unit atau habis pakai). Dua kolom pada layar lebar.
class InventoryFormPage extends StatefulWidget {
  final UnitItem? unit;
  final ConsumableItem? cons;
  final bool startUnit;
  const InventoryFormPage({super.key, this.unit, this.cons, this.startUnit = true});
  @override
  State<InventoryFormPage> createState() => _InventoryFormPageState();
}

class _InventoryFormPageState extends State<InventoryFormPage> {
  final _form = GlobalKey<FormState>();
  late bool _isUnit = widget.unit != null ? true : (widget.cons != null ? false : widget.startUnit);
  bool get _editing => widget.unit != null || widget.cons != null;
  late final _name = TextEditingController(text: widget.unit?.name ?? widget.cons?.name ?? '');
  late final _desc = TextEditingController(text: widget.unit?.description ?? widget.cons?.description ?? '');
  late final _loc = TextEditingController(text: widget.unit?.location ?? widget.cons?.location ?? '');
  late final _count = TextEditingController(text: widget.unit != null ? '0' : '1');
  late final _stock = TextEditingController(text: widget.cons?.stock.toString() ?? '0');
  late final _min = TextEditingController(text: widget.cons?.minStock.toString() ?? '10');
  late final _satuan = TextEditingController(text: widget.cons?.satuan ?? 'pcs');
  late String? _cat = widget.unit?.category ?? widget.cons?.category;
  late String _icon = widget.unit?.iconKey ?? widget.cons?.iconKey ?? (widget.startUnit ? 'laptop' : 'kertas');
  ItemCondition _cond = ItemCondition.layak;

  @override
  void dispose() {
    for (final c in [_name, _desc, _loc, _count, _stock, _min, _satuan]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _prefix {
    final l = _name.text.toUpperCase().replaceAll(RegExp(r'[^A-Z]'), '');
    return l.length >= 3 ? l.substring(0, 3) : l.padRight(3, 'X');
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final inv = context.read<InventoryStore>();
    final cons = context.read<ConsumableStore>();
    if (_isUnit) {
      final n = int.tryParse(_count.text) ?? 0;
      if (widget.unit != null) {
        inv.updateItem(widget.unit!, name: _name.text, category: _cat!, description: _desc.text, location: _loc.text, iconKey: _icon);
        if (n > 0) inv.addUnits(widget.unit!, n, _cond);
        snack(context, 'Data barang diperbarui.');
        Navigator.of(context).pop();
      } else {
        final it = inv.addItem(name: _name.text, category: _cat!, description: _desc.text, location: _loc.text, count: n, condition: _cond, iconKey: _icon);
        snack(context, '${it.name} ditambahkan dengan $n kode barcode unik.');
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => BarcodePreviewPage(itemId: it.id)));
      }
    } else {
      final stock = int.tryParse(_stock.text) ?? 0;
      final min = int.tryParse(_min.text) ?? 0;
      if (widget.cons != null) {
        cons.updateItem(widget.cons!, name: _name.text, category: _cat!, satuan: _satuan.text, stock: stock, minStock: min, location: _loc.text, description: _desc.text, iconKey: _icon);
        snack(context, 'Data barang diperbarui.');
      } else {
        cons.addItem(name: _name.text, category: _cat!, satuan: _satuan.text, stock: stock, minStock: min, location: _loc.text, description: _desc.text, iconKey: _icon);
        snack(context, '${_name.text.trim()} ditambahkan.');
      }
      Navigator.of(context).pop();
    }
  }

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null;
  String? _num(String? v, {int min = 0}) {
    final n = int.tryParse(v ?? '');
    if (n == null) return 'Masukkan angka';
    if (n < min) return 'Minimal $min';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryStore>();
    final cats = inv.categoryNames(_isUnit ? CategoryType.perUnit : CategoryType.habisPakai);
    if (_cat != null && !cats.contains(_cat)) _cat = null;
    final digits = [FilteringTextInputFormatter.digitsOnly];

    return FormScaffold(
      title: _editing ? 'Edit Inventaris' : 'Tambah Inventaris',
      formKey: _form,
      submitLabel: _editing ? 'Simpan perubahan' : (_isUnit ? 'Simpan dan buat barcode' : 'Simpan barang'),
      submitIcon: _isUnit && !_editing ? Icons.qr_code_2 : Icons.save_outlined,
      onSubmit: _save,
      children: [
        if (!_editing)
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: true, label: Text('Per unit'), icon: Icon(Icons.laptop_mac_rounded)),
              ButtonSegment(value: false, label: Text('Habis pakai'), icon: Icon(Icons.layers_outlined)),
            ],
            selected: {_isUnit},
            onSelectionChanged: (s) => setState(() {
              _isUnit = s.first;
              _cat = null;
              _icon = _isUnit ? 'laptop' : 'kertas';
            }),
          ),
        AppTextField(controller: _name, label: 'Nama barang', icon: Icons.inventory_2_outlined, validator: _req, onChanged: (_) => setState(() {})),
        FormRow(children: [
          AppDropdown.strings(label: 'Kategori', icon: Icons.category_outlined, value: _cat, options: cats, onChanged: (v) => setState(() => _cat = v), validator: (v) => v == null ? 'Pilih kategori' : null),
          AppDropdown.strings(label: 'Ikon barang', icon: Icons.image_outlined, value: _icon, options: ItemIcons.keys, onChanged: (v) => setState(() => _icon = v ?? _icon)),
        ]),
        if (_isUnit) ...[
          FormRow(children: [
            AppTextField(
              controller: _count,
              label: _editing ? 'Tambah unit baru (opsional)' : 'Jumlah unit',
              icon: Icons.numbers,
              keyboardType: TextInputType.number,
              formatters: digits,
              validator: (v) => _num(v, min: _editing ? 0 : 1),
              onChanged: (_) => setState(() {}),
            ),
            AppTextField(controller: _loc, label: 'Lokasi penyimpanan', icon: Icons.place_outlined, validator: _req),
          ]),
          AppDropdown<ItemCondition>(
            label: _editing ? 'Kondisi unit baru' : 'Kondisi barang',
            icon: Icons.health_and_safety_outlined,
            value: _cond,
            items: [for (final c in ItemCondition.values) DropdownMenuItem(value: c, child: Text(c.label))],
            onChanged: (v) => setState(() => _cond = v ?? _cond),
          ),
          AppCard(
            color: AppColors.blue.withOpacity(0.06),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Pratinjau barcode unik', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(_editing ? 'Unit baru akan mendapat kode lanjutan otomatis.' : 'Setiap unit mendapat satu kode unik, misalnya $_prefix-${DateTime.now().year}-001.', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 10),
              SizedBox(width: 280, child: BarcodeView(code: '$_prefix-${DateTime.now().year}-001', height: 54)),
            ]),
          ),
        ] else ...[
          FormRow(children: [
            AppTextField(controller: _satuan, label: 'Satuan', icon: Icons.straighten, hint: 'pcs, rim, botol', validator: _req),
            AppTextField(controller: _loc, label: 'Lokasi penyimpanan', icon: Icons.place_outlined, validator: _req),
          ]),
          FormRow(children: [
            AppTextField(controller: _stock, label: _editing ? 'Stok (koreksi)' : 'Stok awal', icon: Icons.layers_outlined, keyboardType: TextInputType.number, formatters: digits, validator: (v) => _num(v)),
            AppTextField(controller: _min, label: 'Stok minimum', icon: Icons.warning_amber_outlined, keyboardType: TextInputType.number, formatters: digits, validator: (v) => _num(v)),
          ]),
        ],
        AppTextField(controller: _desc, label: 'Deskripsi', icon: Icons.notes, maxLines: 3),
      ],
    );
  }
}
