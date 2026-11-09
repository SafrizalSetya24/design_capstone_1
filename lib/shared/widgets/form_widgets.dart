import 'package:flutter/material.dart';
import 'package:sipintar/core/theme/app_colors.dart';
import 'package:sipintar/core/utils/format.dart';
import 'package:sipintar/shared/widgets/app_card.dart';
import 'package:sipintar/shared/widgets/item_image.dart';

class AppDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final IconData? icon;
  final String? Function(T?)? validator;
  const AppDropdown(
      {super.key,
      required this.label,
      required this.value,
      required this.items,
      required this.onChanged,
      this.icon,
      this.validator});

  static AppDropdown<String> strings({
    Key? key,
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?>? onChanged,
    IconData? icon,
    String? Function(String?)? validator,
  }) =>
      AppDropdown<String>(
        key: key,
        label: label,
        value: options.contains(value) ? value : null,
        items: [
          for (final o in options)
            DropdownMenuItem(
                value: o, child: Text(o, overflow: TextOverflow.ellipsis))
        ],
        onChanged: onChanged,
        icon: icon,
        validator: validator,
      );

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
        initialValue: value,
        items: items,
        onChanged: onChanged,
        validator: validator,
        isExpanded: true,
        decoration: InputDecoration(
            labelText: label, prefixIcon: icon == null ? null : Icon(icon)),
      );
}

class DateTimeInput extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String? errorText;
  const DateTimeInput(
      {super.key,
      required this.label,
      required this.value,
      required this.onChanged,
      this.errorText});

  Future<void> _pickDate(BuildContext c) async {
    final today = DateTime.now();
    final first = DateTime(today.year, today.month, today.day);
    final base = value ?? first;
    final d = await showDatePicker(
      context: c,
      initialDate: base.isBefore(first) ? first : base,
      firstDate: first,
      lastDate: first.add(const Duration(days: 365)),
    );
    if (d == null) return;
    onChanged(
        DateTime(d.year, d.month, d.day, value?.hour ?? 8, value?.minute ?? 0));
  }

  Future<void> _pickTime(BuildContext c) async {
    final t = await showTimePicker(
        context: c,
        initialTime:
            TimeOfDay(hour: value?.hour ?? 8, minute: value?.minute ?? 0));
    if (t == null) return;
    final b = value ?? DateTime.now();
    onChanged(DateTime(b.year, b.month, b.day, t.hour, t.minute));
  }

  Widget _box(String title, String text, IconData icon, VoidCallback onTap,
          bool hasValue) =>
      InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: title,
            prefixIcon: Icon(icon),
            enabledBorder: errorText == null
                ? null
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.danger)),
          ),
          child: Text(text,
              style: TextStyle(
                  color: hasValue
                      ? AppColors.textPrimary
                      : AppColors.textSecondary)),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final v = value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(
              flex: 3,
              child: _box(
                  'Tanggal $label',
                  v == null ? 'Pilih tanggal' : Fmt.date(v),
                  Icons.calendar_today_outlined,
                  () => _pickDate(context),
                  v != null)),
          const SizedBox(width: 8),
          Expanded(
              flex: 2,
              child: _box('Jam $label', v == null ? 'Pilih jam' : Fmt.time(v),
                  Icons.access_time, () => _pickTime(context), v != null)),
        ]),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 12),
            child: Text(errorText!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ),
      ],
    );
  }
}

class QtyStepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  const QtyStepper(
      {super.key,
      required this.value,
      this.min = 1,
      required this.max,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          IconButton(
              tooltip: 'Kurangi',
              visualDensity: VisualDensity.compact,
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove)),
          SizedBox(
              width: 32,
              child: Text('$value',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16))),
          IconButton(
              tooltip: 'Tambah',
              visualDensity: VisualDensity.compact,
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add)),
        ]),
      );
}

class LineOption {
  final String id, name, iconKey, hint;
  final int max;
  const LineOption(
      {required this.id,
      required this.name,
      required this.iconKey,
      required this.hint,
      required this.max});
}

class LineEntry {
  final String id, name, iconKey;
  final int max;
  int qty;
  LineEntry(
      {required this.id,
      required this.name,
      required this.iconKey,
      required this.max,
      required this.qty});
}

/// Editor daftar barang (banyak jenis sekaligus): pilih barang, atur jumlah, tambahkan.
class ItemLinesEditor extends StatefulWidget {
  final List<LineOption> options;
  final List<LineEntry> lines;
  final ValueChanged<List<LineEntry>> onChanged;
  final String? errorText;
  const ItemLinesEditor(
      {super.key,
      required this.options,
      required this.lines,
      required this.onChanged,
      this.errorText});
  @override
  State<ItemLinesEditor> createState() => _ItemLinesEditorState();
}

class _ItemLinesEditorState extends State<ItemLinesEditor> {
  String? _sel;
  int _qty = 1;

  List<LineOption> get _free => widget.options
      .where((o) => !widget.lines.any((l) => l.id == o.id))
      .toList();

  void _add() {
    final o = widget.options.firstWhere((x) => x.id == _sel);
    widget.onChanged([
      ...widget.lines,
      LineEntry(
          id: o.id, name: o.name, iconKey: o.iconKey, max: o.max, qty: _qty)
    ]);
    setState(() {
      _sel = null;
      _qty = 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final free = _free;
    if (_sel != null && !free.any((o) => o.id == _sel)) _sel = null;
    final cur = _sel == null ? null : free.firstWhere((o) => o.id == _sel);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            AppDropdown<String>(
              label: 'Pilih barang',
              icon: Icons.inventory_2_outlined,
              value: _sel,
              items: [
                for (final o in free)
                  DropdownMenuItem(
                      value: o.id,
                      child: Text('${o.name} (${o.hint})',
                          overflow: TextOverflow.ellipsis)),
              ],
              onChanged: free.isEmpty
                  ? null
                  : (v) => setState(() {
                        _sel = v;
                        _qty = 1;
                      }),
            ),
            const SizedBox(height: 12),
            Row(children: [
              QtyStepper(
                  value: _qty,
                  max: cur?.max ?? 1,
                  onChanged: (v) => setState(() => _qty = v)),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(0, 48)),
                  onPressed: cur == null ? null : _add,
                  icon: const Icon(Icons.add_shopping_cart, color: Colors.white),
                  label: const Text('Tambahkan',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ]),
          ]),
        ),
        const SizedBox(height: 8),
        if (widget.lines.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
                widget.errorText ??
                    'Belum ada barang dipilih. Anda dapat menambahkan beberapa jenis sekaligus.',
                style: TextStyle(
                    color: widget.errorText == null
                        ? AppColors.textSecondary
                        : AppColors.danger,
                    fontSize: 13)),
          ),
        for (final l in widget.lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppCard(
              padding: const EdgeInsets.all(10),
              child: Row(children: [
                ItemImage(iconKey: l.iconKey, size: 44),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(l.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600))),
                QtyStepper(
                    value: l.qty,
                    max: l.max,
                    onChanged: (v) {
                      l.qty = v;
                      widget.onChanged(List.of(widget.lines));
                    }),
                IconButton(
                  tooltip: 'Hapus',
                  onPressed: () => widget.onChanged(
                      widget.lines.where((x) => x.id != l.id).toList()),
                  icon:
                      const Icon(Icons.delete_outline, color: AppColors.danger),
                ),
              ]),
            ),
          ),
      ],
    );
  }
}
