import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/features/borrowing/loan_detail_page.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

/// Verifikasi wajah SIMULASI (tidak ada kamera atau ML sungguhan).
class FaceVerificationPage extends StatefulWidget {
  final String loanId;
  const FaceVerificationPage({super.key, required this.loanId});
  @override
  State<FaceVerificationPage> createState() => _FaceVerificationPageState();
}

class _FaceVerificationPageState extends State<FaceVerificationPage> {
  FaceState _state = FaceState.ready;
  double _progress = 0;
  bool _simOk = true;
  Timer? _t;

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() {
      _state = FaceState.scanning;
      _progress = 0;
    });
    _t?.cancel();
    _t = Timer.periodic(const Duration(milliseconds: 45), (t) {
      if (!mounted) return;
      setState(() => _progress += 0.02);
      if (_progress >= 1) {
        t.cancel();
        _finish();
      }
    });
  }

  void _finish() {
    final loans = context.read<LoanStore>();
    final l = loans.byId(widget.loanId);
    if (l == null) return;
    loans.submitFace(l, ok: _simOk, score: _simOk ? 0.94 : 0.41);
    setState(() => _state = _simOk ? FaceState.success : FaceState.failed);
  }

  String get _stepText {
    if (_progress < 0.35) return 'Mendeteksi wajah...';
    if (_progress < 0.7) return 'Mencocokkan dengan data pengguna...';
    return 'Menyelesaikan verifikasi...';
  }

  @override
  Widget build(BuildContext context) {
    final camera = Center(
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 380), child: FaceCameraView(state: _state)),
    );

    Widget status;
    switch (_state) {
      case FaceState.ready:
        status = const _StatusCard(icon: Icons.info_outline, color: AppColors.blue, title: 'Siap memulai', text: 'Posisikan wajah di dalam oval, pastikan pencahayaan cukup, lalu tekan Mulai verifikasi.');
      case FaceState.scanning:
        status = AppCard(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_stepText, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: _progress.clamp(0, 1), minHeight: 8, borderRadius: BorderRadius.circular(8)),
            const SizedBox(height: 6),
            Text('${(_progress.clamp(0, 1) * 100).round()}%', style: const TextStyle(color: AppColors.textSecondary)),
          ]),
        );
      case FaceState.success:
        status = const _StatusCard(icon: Icons.check_circle, color: AppColors.success, title: 'Verifikasi berhasil', text: 'Wajah cocok dengan data akun. Pengajuan Anda siap dikirim ke Sapras.');
      case FaceState.failed:
        status = const _StatusCard(icon: Icons.cancel, color: AppColors.danger, title: 'Verifikasi gagal', text: 'Wajah tidak cocok atau kurang jelas. Pastikan wajah terlihat penuh dan ulangi verifikasi.');
    }

    final panel = Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mengapa perlu verifikasi wajah?', style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text('Verifikasi wajah diperlukan untuk peminjaman barang per unit agar peminjam tercatat dengan jelas. Barang habis pakai tidak memerlukannya.', style: TextStyle(height: 1.45)),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      const AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Panduan posisi wajah', style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text('- Hadapkan wajah lurus ke kamera depan\n- Letakkan wajah di dalam oval\n- Gunakan pencahayaan yang cukup\n- Lepas masker atau kacamata hitam', style: TextStyle(height: 1.6)),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mode simulasi hasil', style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [ButtonSegment(value: true, label: Text('Berhasil')), ButtonSegment(value: false, label: Text('Gagal'))],
            selected: {_simOk},
            onSelectionChanged: _state == FaceState.scanning ? null : (s) => setState(() => _simOk = s.first),
          ),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),
      status,
      const SizedBox(height: AppSpacing.md),
      if (_state == FaceState.ready) PrimaryButton(label: 'Mulai verifikasi', icon: Icons.play_arrow, onPressed: _start),
      if (_state == FaceState.failed) PrimaryButton(label: 'Ulangi verifikasi', icon: Icons.refresh, onPressed: _start),
      if (_state == FaceState.success)
        PrimaryButton(
          label: 'Lanjutkan',
          icon: Icons.arrow_forward,
          onPressed: () => Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => LoanSuccessPage(loanId: widget.loanId))),
        ),
    ]);

    return AppPage(
      title: 'Verifikasi Wajah',
      body: PageList(children: [TwoPane(leftFlex: 1, rightFlex: 1, left: camera, right: panel, breakpoint: 760)]),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, text;
  const _StatusCard({required this.icon, required this.color, required this.title, required this.text});
  @override
  Widget build(BuildContext context) => AppCard(
        color: color.withOpacity(0.08),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 2),
              Text(text, style: const TextStyle(height: 1.4, fontSize: 13)),
            ]),
          ),
        ]),
      );
}
