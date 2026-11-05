import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/inventory/unit_detail_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

/// Pindai barcode SIMULASI: kamera dan hasil pindai berupa simulasi frontend.
class ScanPage extends StatefulWidget {
  const ScanPage({super.key});
  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final _manual = TextEditingController();
  bool _scanning = false;
  String? _code;
  bool _notFound = false;
  int _next = 0;

  @override
  void dispose() {
    _manual.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final inv = context.read<InventoryStore>();
    final all = inv.allUnits();
    if (all.isEmpty) return;
    setState(() {
      _scanning = true;
      _code = null;
      _notFound = false;
    });
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    final pick = all[_next % all.length];
    _next++;
    setState(() {
      _scanning = false;
      _code = pick.unit.code;
    });
  }

  void _lookup() {
    final t = _manual.text.trim().toUpperCase();
    if (t.isEmpty) return;
    final found = context.read<InventoryStore>().findByCode(t) != null;
    setState(() {
      _code = t;
      _notFound = !found;
    });
  }

  void _reset() => setState(() {
        _code = null;
        _notFound = false;
        _manual.clear();
      });

  @override
  Widget build(BuildContext context) {
    final inv = context.watch<InventoryStore>();
    final ref = _code == null ? null : inv.findByCode(_code!);

    final left =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Center(
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ScanFrameView(scanning: _scanning))),
      const SizedBox(height: AppSpacing.md),
      PrimaryButton(
          label: _scanning ? 'Memindai...' : 'Pindai barcode (simulasi)',
          icon: Icons.qr_code_scanner,
          loading: _scanning,
          onPressed: _scan),
      const SizedBox(height: AppSpacing.md),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Atau masukkan kode manual',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: AppTextField(
                    controller: _manual,
                    label: 'Kode unit',
                    hint: 'Contoh: LPT-2026-001',
                    icon: Icons.keyboard_outlined)),
            const SizedBox(width: 8),
            FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(88, 54)),
                onPressed: _lookup,
                child: const Text('Cari')),
          ]),
        ]),
      ),
    ]);

    Widget right;
    if (_scanning) {
      right = const SizedBox(height: 260, child: LoadingView());
    } else if (_code == null) {
      right = const SizedBox(
          height: 260,
          child: EmptyState(
              icon: Icons.qr_code_2,
              title: 'Belum ada hasil pindai',
              message:
                  'Arahkan kamera ke barcode unit atau masukkan kode secara manual.'));
    } else if (ref == null || _notFound) {
      right = SizedBox(
          height: 280,
          child: ErrorState(
              message: 'Kode "$_code" tidak terdaftar pada inventaris.',
              onRetry: _reset));
    } else {
      final u = ref.unit;
      right = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        AppCard(
          color: AppColors.success.withValues(alpha: 0.08),
          child: Row(children: [
            const Icon(Icons.check_circle, color: AppColors.success),
            const SizedBox(width: 10),
            Expanded(
                child: Text('Barcode terdeteksi: $_code',
                    style: const TextStyle(fontWeight: FontWeight.w800))),
          ]),
        ),
        const SizedBox(height: AppSpacing.md),
        BarcodeView(code: u.code),
        const SizedBox(height: AppSpacing.md),
        InfoCard(title: ref.item.name, rows: [
          ('Kode unit', u.code),
          ('Kategori', ref.item.category),
          ('Lokasi', ref.item.location),
        ]),
        const SizedBox(height: 8),
        AppCard(
          child: Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Kondisi:',
                    style: TextStyle(color: AppColors.textSecondary)),
                StatusBadge.fromStatus(u.condition.label),
                const Text('Ketersediaan:',
                    style: TextStyle(color: AppColors.textSecondary)),
                StatusBadge.fromStatus(u.status.label),
              ]),
        ),
        const SizedBox(height: AppSpacing.md),
        PrimaryButton(
            label: 'Lihat detail unit',
            icon: Icons.open_in_new,
            onPressed: () => push(context, UnitDetailPage(code: u.code))),
        const SizedBox(height: 8),
        OutlinedButton(onPressed: _reset, child: const Text('Pindai lagi')),
      ]);
    }

    return AppPage(
        title: 'Scan Barcode',
        body: PageList(children: [
          TwoPane(
              left: left,
              right: right,
              leftFlex: 1,
              rightFlex: 1,
              breakpoint: 820)
        ]));
  }
}

/// Sheet pindai SIMULASI untuk penyerahan/pengembalian. Mengembalikan [code] setelah "terpindai".
Future<String?> showScanSheet(BuildContext c, {required String code}) =>
    showModalBottomSheet<String>(
      context: c,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _ScanSheet(code: code),
    );

class _ScanSheet extends StatefulWidget {
  final String code;
  const _ScanSheet({required this.code});
  @override
  State<_ScanSheet> createState() => _ScanSheetState();
}

class _ScanSheetState extends State<_ScanSheet> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (mounted) Navigator.of(context).pop(widget.code);
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: const ScanFrameView(scanning: true, aspect: 16 / 10)),
            const SizedBox(height: 12),
            Text('Memindai barcode ${widget.code} (simulasi)...',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
        ),
      );
}
