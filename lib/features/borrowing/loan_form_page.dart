import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/face_verification/face_verification_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class LoanDraft {
  final List<LoanLine> lines;
  final DateTime start, end;
  final String purpose;
  LoanDraft(this.lines, this.start, this.end, this.purpose);
}

/// Form pengajuan: satu pengajuan bisa berisi beberapa jenis barang sekaligus.
class LoanFormPage extends StatefulWidget {
  final String? presetItemId;
  const LoanFormPage({super.key, this.presetItemId});
  @override
  State<LoanFormPage> createState() => _LoanFormPageState();
}

class _LoanFormPageState extends State<LoanFormPage> {
  final _form = GlobalKey<FormState>();
  final _purpose = TextEditingController();
  List<LineEntry> _lines = [];
  DateTime? _start, _end;
  String? _linesErr, _startErr, _endErr;

  @override
  void initState() {
    super.initState();
    final it = widget.presetItemId == null ? null : context.read<InventoryStore>().itemById(widget.presetItemId!);
    if (it != null && it.available > 0) {
      _lines = [LineEntry(id: it.id, name: it.name, iconKey: it.iconKey, max: it.available, qty: 1)];
    }
  }

  @override
  void dispose() {
    _purpose.dispose();
    super.dispose();
  }

  void _next() {
    var ok = _form.currentState!.validate();
    String? le, se, ee;
    if (_lines.isEmpty) {
      le = 'Tambahkan minimal satu barang.';
      ok = false;
    }
    if (_start == null) {
      se = 'Pilih tanggal dan jam mulai.';
      ok = false;
    } else if (_start!.isBefore(DateTime.now().subtract(const Duration(minutes: 5)))) {
      se = 'Waktu mulai tidak boleh di masa lalu.';
      ok = false;
    }
    if (_end == null) {
      ee = 'Pilih tanggal dan jam selesai.';
      ok = false;
    } else if (_start != null && !_end!.isAfter(_start!)) {
      ee = 'Waktu selesai harus setelah waktu mulai.';
      ok = false;
    }
    setState(() {
      _linesErr = le;
      _startErr = se;
      _endErr = ee;
    });
    if (!ok) return;
    final inv = context.read<InventoryStore>();
    final lines = [for (final l in _lines) LoanLine(itemId: l.id, itemName: l.name, iconKey: l.iconKey, qty: l.qty)];
    // pastikan jumlah masih tersedia
    for (final l in lines) {
      if ((inv.itemById(l.itemId)?.available ?? 0) < l.qty) {
        snack(context, 'Unit ${l.itemName} tidak mencukupi.', error: true);
        return;
      }
    }
    push(context, LoanSummaryPage(draft: LoanDraft(lines, _start!, _end!, _purpose.text.trim())));
  }

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryStore>();
    final options = [
      for (final i in inv.items.where((x) => x.available > 0))
        LineOption(id: i.id, name: i.name, iconKey: i.iconKey, hint: '${i.available} unit tersedia', max: i.available),
    ];
    final total = _lines.fold<int>(0, (a, l) => a + l.qty);

    final formCol = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SectionHeader('1. Pilih barang dan jumlah'),
      const SizedBox(height: 8),
      ItemLinesEditor(options: options, lines: _lines, errorText: _linesErr, onChanged: (v) => setState(() {
            _lines = v;
            _linesErr = null;
          })),
      const SizedBox(height: AppSpacing.lg),
      const SectionHeader('2. Jadwal peminjaman'),
      const SizedBox(height: 8),
      FormRow(breakpoint: 640, children: [
        DateTimeInput(label: 'mulai', value: _start, errorText: _startErr, onChanged: (v) => setState(() {
              _start = v;
              _startErr = null;
            })),
        DateTimeInput(label: 'selesai', value: _end, errorText: _endErr, onChanged: (v) => setState(() {
              _end = v;
              _endErr = null;
            })),
      ]),
      const SizedBox(height: AppSpacing.lg),
      const SectionHeader('3. Tujuan peminjaman'),
      const SizedBox(height: 8),
      AppTextField(
        controller: _purpose,
        label: 'Tujuan peminjaman',
        icon: Icons.notes,
        maxLines: 3,
        validator: (v) => (v == null || v.trim().length < 10) ? 'Tujuan minimal 10 karakter' : null,
      ),
    ]);

    final summary = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Ringkasan pengajuan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
          const SizedBox(height: 10),
          if (_lines.isEmpty)
            const Text('Belum ada barang dipilih.', style: TextStyle(color: AppColors.textSecondary))
          else
            for (final l in _lines)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Expanded(child: Text(l.name, overflow: TextOverflow.ellipsis)),
                  Text('x${l.qty}', style: const TextStyle(fontWeight: FontWeight.w800)),
                ]),
              ),
          const Divider(height: 24),
          Row(children: [const Expanded(child: Text('Total unit')), Text('$total', style: const TextStyle(fontWeight: FontWeight.w800))]),
          const SizedBox(height: 6),
          Text(_start == null ? 'Mulai: -' : 'Mulai: ${Fmt.dateTime(_start!)}', style: const TextStyle(fontSize: 13)),
          Text(_end == null ? 'Selesai: -' : 'Selesai: ${Fmt.dateTime(_end!)}', style: const TextStyle(fontSize: 13)),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      AppCard(
        color: AppColors.blue.withOpacity(0.06),
        child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.face_retouching_natural, color: AppColors.blue),
          SizedBox(width: 10),
          Expanded(child: Text('Verifikasi wajah diperlukan untuk peminjaman barang per unit. Anda akan diarahkan ke kamera setelah konfirmasi.', style: TextStyle(fontSize: 13, height: 1.4))),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      PrimaryButton(label: 'Lanjut ke konfirmasi', icon: Icons.arrow_forward, onPressed: _next),
    ]);

    return AppPage(
      title: 'Ajukan Peminjaman',
      body: PageList(children: [Form(key: _form, child: TwoPane(leftFlex: 3, rightFlex: 2, left: formCol, right: summary))]),
    );
  }
}

class LoanSummaryPage extends StatelessWidget {
  final LoanDraft draft;
  const LoanSummaryPage({super.key, required this.draft});

  Future<void> _confirm(BuildContext context) async {
    final ok = await confirm(context,
        title: 'Konfirmasi pengajuan?',
        message: 'Setelah ini Anda akan melakukan verifikasi wajah. Pengajuan baru dikirim ke Sapras setelah verifikasi berhasil.',
        confirmLabel: 'Lanjutkan');
    if (!ok || !context.mounted) return;
    final user = context.read<AuthStore>().currentUser!;
    final loan = context.read<LoanStore>().createDraft(
        borrower: Borrower.fromUser(user), lines: draft.lines, start: draft.start, end: draft.end, purpose: draft.purpose);
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => FaceVerificationPage(loanId: loan.id)));
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthStore>().currentUser!;
    return AppPage(
      title: 'Konfirmasi Pengajuan',
      body: PageList(children: [
        TwoPane(
          left: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            AppCard(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Daftar barang', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 8),
                for (final l in draft.lines)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(children: [
                      ItemImage(iconKey: l.iconKey, size: 40),
                      const SizedBox(width: 10),
                      Expanded(child: Text(l.itemName, style: const TextStyle(fontWeight: FontWeight.w600))),
                      Text('${l.qty} unit', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ]),
                  ),
              ]),
            ),
            const SizedBox(height: AppSpacing.md),
            InfoCard(title: 'Jadwal dan tujuan', rows: [
              ('Mulai', Fmt.dateTime(draft.start)),
              ('Selesai', Fmt.dateTime(draft.end)),
              ('Tujuan', draft.purpose),
            ]),
          ]),
          right: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            InfoCard(title: 'Peminjam', rows: [
              ('Nama', user.name),
              ('Jenis akun', user.role.label),
              (user.identityLabel, user.identityValue),
              if (user.extraValue != null) (user.extraLabel!, user.extraValue!),
            ]),
            const SizedBox(height: AppSpacing.md),
            PrimaryButton(label: 'Konfirmasi dan verifikasi wajah', icon: Icons.face_retouching_natural, onPressed: () => _confirm(context)),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ubah pengajuan')),
          ]),
        ),
      ]),
    );
  }
}
