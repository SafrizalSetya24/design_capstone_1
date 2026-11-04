import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/inventory/unit_detail_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

/// Kondisi barang diinput dan dikonfirmasi manual oleh Sapras (bukan oleh ML).
class ConditionRepairPage extends StatefulWidget {
  const ConditionRepairPage({super.key});
  @override
  State<ConditionRepairPage> createState() => _ConditionRepairPageState();
}

class _ConditionRepairPageState extends State<ConditionRepairPage> {
  String _repairFilter = 'Semua';

  Widget _units(BuildContext context, InventoryStore inv, ItemCondition c) {
    final list = inv.allUnits().where((r) => r.unit.condition == c).toList();
    if (list.isEmpty) {
      return PageList(children: [SizedBox(height: 280, child: EmptyState(icon: Icons.check_circle_outline, title: 'Tidak ada unit', message: 'Tidak ada unit dengan kondisi "${c.label}".'))]);
    }
    return PageList(children: [
      ResponsiveTable(
        columns: const ['Kode unit', 'Barang', 'Lokasi', 'Status', 'Aksi'],
        onRowTap: (i) => push(context, UnitDetailPage(code: list[i].unit.code)),
        rows: [
          for (final r in list)
            [
              cellText(r.unit.code, bold: true),
              cellText(r.item.name),
              cellText(r.item.location),
              StatusBadge.fromStatus(r.unit.status.label),
              c == ItemCondition.layak
                  ? TextButton(onPressed: r.unit.status == UnitStatus.dipinjam ? null : () => push(context, DamageFormPage(code: r.unit.code)), child: const Text('Catat kerusakan'))
                  : TextButton(
                      onPressed: () {
                        final rec = inv.repairs.where((x) => x.unitCode == r.unit.code && !x.confirmed).toList();
                        if (rec.isEmpty) {
                          push(context, UnitDetailPage(code: r.unit.code));
                        } else {
                          push(context, RepairDetailPage(repairId: rec.first.id));
                        }
                      },
                      child: const Text('Lihat perbaikan'),
                    ),
            ],
        ],
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryStore>();
    final repairs = _repairFilter == 'Semua' ? inv.repairs : inv.repairs.where((r) => r.status.label == _repairFilter).toList();
    return DefaultTabController(
      length: 5,
      child: AppPage(
        title: 'Kondisi dan Perbaikan',
        fab: FloatingActionButton.extended(
          onPressed: () => push(context, const DamageFormPage()),
          icon: const Icon(Icons.report_problem_outlined),
          label: const Text('Catat kerusakan'),
          backgroundColor: AppColors.danger,
          foregroundColor: Colors.white,
        ),
        bottom: TabBar(isScrollable: true, tabAlignment: TabAlignment.start, tabs: [
          Tab(text: 'Layak pakai (${inv.countCond(ItemCondition.layak)})'),
          Tab(text: 'Perlu diperbaiki (${inv.countCond(ItemCondition.perluDiperbaiki)})'),
          Tab(text: 'Rusak total (${inv.countCond(ItemCondition.rusakTotal)})'),
          const Tab(text: 'Perbaikan'),
          const Tab(text: 'Riwayat kondisi'),
        ]),
        body: TabBarView(children: [
          _units(context, inv, ItemCondition.layak),
          _units(context, inv, ItemCondition.perluDiperbaiki),
          _units(context, inv, ItemCondition.rusakTotal),
          PageList(padding: const EdgeInsets.fromLTRB(16, 16, 16, 96), children: [
            FilterRow(label: 'Status perbaikan', options: ['Semua', ...RepairStatus.values.map((s) => s.label)], selected: _repairFilter, onSelected: (v) => setState(() => _repairFilter = v)),
            const SizedBox(height: 8),
            if (repairs.isEmpty)
              const SizedBox(height: 240, child: EmptyState(icon: Icons.build_outlined, title: 'Tidak ada data perbaikan', message: 'Catatan perbaikan akan muncul di sini.'))
            else
              ResponsiveGrid(minItemWidth: 400, children: [
                for (final r in repairs)
                  RowCard(
                    title: '${r.unitCode} - ${r.itemName}',
                    subtitle: r.issue,
                    extra: [Text('Dilaporkan ${Fmt.date(r.reportedAt)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))],
                    trailing: StatusBadge.fromStatus(r.status.label),
                    onTap: () => push(context, RepairDetailPage(repairId: r.id)),
                  ),
              ]),
          ]),
          PageList(children: [
            if (inv.logs.isEmpty)
              const SizedBox(height: 240, child: EmptyState(icon: Icons.history, title: 'Belum ada riwayat', message: 'Perubahan kondisi barang akan tercatat di sini.'))
            else
              ResponsiveTable(
                columns: const ['Tanggal', 'Unit', 'Perubahan', 'Catatan', 'Petugas'],
                rows: [
                  for (final l in inv.logs)
                    [cellText(Fmt.dateTime(l.date)), cellText('${l.unitCode}\n${l.itemName}', bold: true), cellText('${l.from.label} ke ${l.to.label}'), cellText(l.note), cellText(l.actor)],
                ],
              ),
          ]),
        ]),
      ),
    );
  }
}

class DamageFormPage extends StatefulWidget {
  final String? code;
  const DamageFormPage({super.key, this.code});
  @override
  State<DamageFormPage> createState() => _DamageFormPageState();
}

class _DamageFormPageState extends State<DamageFormPage> {
  final _form = GlobalKey<FormState>();
  final _issue = TextEditingController();
  final _note = TextEditingController();
  late String? _code = widget.code;
  ItemCondition _sev = ItemCondition.perluDiperbaiki;

  @override
  void dispose() {
    _issue.dispose();
    _note.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    final inv = context.read<InventoryStore>();
    inv.reportDamage(_code!, issue: _issue.text.trim(), severity: _sev, note: _note.text.trim());
    snack(context, 'Kerusakan unit $_code dicatat.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryStore>();
    final opts = inv.allUnits().where((r) => r.unit.status != UnitStatus.dipinjam || r.unit.code == widget.code).toList();
    return FormScaffold(
      title: 'Catat Kerusakan',
      formKey: _form,
      submitLabel: 'Simpan catatan kerusakan',
      submitIcon: Icons.save_outlined,
      onSubmit: _save,
      children: [
        AppDropdown<String>(
          label: 'Unit barang',
          icon: Icons.qr_code_2,
          value: _code,
          items: [for (final r in opts) DropdownMenuItem(value: r.unit.code, child: Text('${r.unit.code} - ${r.item.name}', overflow: TextOverflow.ellipsis))],
          onChanged: widget.code != null ? null : (v) => setState(() => _code = v),
          validator: (v) => v == null ? 'Pilih unit barang' : null,
        ),
        AppDropdown<ItemCondition>(
          label: 'Tingkat kerusakan',
          icon: Icons.health_and_safety_outlined,
          value: _sev,
          items: const [
            DropdownMenuItem(value: ItemCondition.perluDiperbaiki, child: Text('Perlu diperbaiki')),
            DropdownMenuItem(value: ItemCondition.rusakTotal, child: Text('Rusak total')),
          ],
          onChanged: (v) => setState(() => _sev = v ?? _sev),
        ),
        AppTextField(controller: _issue, label: 'Deskripsi kerusakan', icon: Icons.report_problem_outlined, maxLines: 3, validator: (v) => (v == null || v.trim().length < 5) ? 'Jelaskan kerusakan (minimal 5 karakter)' : null),
        AppTextField(controller: _note, label: 'Catatan tambahan (opsional)', icon: Icons.notes, maxLines: 2),
        AppCard(
          color: AppColors.blue.withOpacity(0.06),
          child: const Text('Kondisi barang diputuskan dan dikonfirmasi secara manual oleh Sapras.', style: TextStyle(fontSize: 13)),
        ),
      ],
    );
  }
}

class RepairDetailPage extends StatelessWidget {
  final String repairId;
  const RepairDetailPage({super.key, required this.repairId});

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryStore>();
    final m = inv.repairs.where((r) => r.id == repairId);
    if (m.isEmpty) {
      return const AppPage(title: 'Detail Perbaikan', body: EmptyState(icon: Icons.build_outlined, title: 'Data tidak ditemukan', message: ''));
    }
    final r = m.first;
    return AppPage(
      title: 'Detail Perbaikan',
      body: PageList(children: [
        ResponsiveBody(
          maxWidth: 820,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AppCard(
              child: Row(children: [
                Expanded(child: Text(r.unitCode, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy))),
                StatusBadge.fromStatus(r.status.label),
              ]),
            ),
            const SizedBox(height: AppSpacing.md),
            InfoCard(title: r.itemName, rows: [
              ('Kerusakan', r.issue),
              ('Tingkat', r.severity.label),
              ('Dilaporkan', Fmt.dateTime(r.reportedAt)),
              ('Diperbarui', Fmt.dateTime(r.updatedAt)),
              ('Teknisi/bengkel', r.technician),
              ('Catatan', r.notes.isEmpty ? '-' : r.notes),
              if (r.confirmed) ('Kondisi akhir', r.finalCondition?.label ?? '-'),
            ]),
            const SizedBox(height: AppSpacing.md),
            if (r.status == RepairStatus.menunggu || r.status == RepairStatus.diperbaiki)
              PrimaryButton(label: 'Proses perbaikan', icon: Icons.build, onPressed: () => push(context, RepairProcessPage(repairId: r.id))),
            if (r.status == RepairStatus.selesai && !r.confirmed)
              PrimaryButton(label: 'Konfirmasi pemeriksaan', icon: Icons.fact_check, onPressed: () => push(context, RepairConfirmPage(repairId: r.id))),
            const SizedBox(height: 8),
            OutlinedButton(onPressed: () => push(context, UnitDetailPage(code: r.unitCode)), child: const Text('Lihat detail unit')),
          ]),
        ),
      ]),
    );
  }
}

class RepairProcessPage extends StatefulWidget {
  final String repairId;
  const RepairProcessPage({super.key, required this.repairId});
  @override
  State<RepairProcessPage> createState() => _RepairProcessPageState();
}

class _RepairProcessPageState extends State<RepairProcessPage> {
  final _form = GlobalKey<FormState>();
  late final RepairRecord _r = context.read<InventoryStore>().repairs.firstWhere((x) => x.id == widget.repairId);
  late final _tech = TextEditingController(text: _r.technician == '-' ? '' : _r.technician);
  late final _notes = TextEditingController(text: _r.notes);
  late RepairStatus _status = _r.status == RepairStatus.menunggu ? RepairStatus.diperbaiki : _r.status;

  @override
  void dispose() {
    _tech.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    context.read<InventoryStore>().updateRepair(_r, status: _status, technician: _tech.text, notes: _notes.text);
    snack(context, 'Status perbaikan diperbarui: ${_status.label}.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) => FormScaffold(
        title: 'Proses Perbaikan',
        formKey: _form,
        submitLabel: 'Simpan status perbaikan',
        onSubmit: _save,
        children: [
          InfoCard(rows: [('Unit', _r.unitCode), ('Kerusakan', _r.issue)]),
          AppDropdown<RepairStatus>(
            label: 'Status perbaikan',
            icon: Icons.build_circle_outlined,
            value: _status,
            items: [for (final s in RepairStatus.values) DropdownMenuItem(value: s, child: Text(s.label))],
            onChanged: (v) => setState(() => _status = v ?? _status),
          ),
          AppTextField(controller: _tech, label: 'Teknisi / bengkel', icon: Icons.engineering_outlined, validator: (v) => (_status != RepairStatus.menunggu && (v == null || v.trim().isEmpty)) ? 'Wajib diisi' : null),
          AppTextField(controller: _notes, label: 'Catatan perbaikan', icon: Icons.notes, maxLines: 3),
        ],
      );
}

class RepairConfirmPage extends StatefulWidget {
  final String repairId;
  const RepairConfirmPage({super.key, required this.repairId});
  @override
  State<RepairConfirmPage> createState() => _RepairConfirmPageState();
}

class _RepairConfirmPageState extends State<RepairConfirmPage> {
  final _note = TextEditingController();
  ItemCondition _cond = ItemCondition.layak;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = context.read<InventoryStore>().repairs.firstWhere((x) => x.id == widget.repairId);
    return FormScaffold(
      title: 'Konfirmasi Pemeriksaan',
      submitLabel: 'Konfirmasi kondisi akhir',
      submitIcon: Icons.verified_outlined,
      onSubmit: () {
        context.read<InventoryStore>().confirmRepair(r, _cond, _note.text.trim());
        snack(context, 'Kondisi ${r.unitCode} dikonfirmasi: ${_cond.label}.');
        Navigator.of(context).pop();
      },
      children: [
        InfoCard(rows: [('Unit', r.unitCode), ('Barang', r.itemName), ('Teknisi', r.technician)]),
        AppDropdown<ItemCondition>(
          label: 'Kondisi setelah pemeriksaan',
          icon: Icons.health_and_safety_outlined,
          value: _cond,
          items: [for (final c in ItemCondition.values) DropdownMenuItem(value: c, child: Text(c.label))],
          onChanged: (v) => setState(() => _cond = v ?? _cond),
        ),
        AppTextField(controller: _note, label: 'Catatan pemeriksaan', icon: Icons.notes, maxLines: 3),
        const AppCard(child: Text('Unit baru dapat dipinjam kembali jika dikonfirmasi "Layak pakai".', style: TextStyle(fontSize: 13))),
      ],
    );
  }
}
