import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/app/routes.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

/// Verifikasi wajah setelah login sebelum masuk ke beranda (UI Flow Simulasi).
class LoginFaceVerificationPage extends StatefulWidget {
  const LoginFaceVerificationPage({super.key});

  @override
  State<LoginFaceVerificationPage> createState() =>
      _LoginFaceVerificationPageState();
}

class _LoginFaceVerificationPageState extends State<LoginFaceVerificationPage> {
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
    _t = Timer.periodic(const Duration(milliseconds: 40), (t) {
      if (!mounted) {
        return;
      }
      setState(() => _progress += 0.02);
      if (_progress >= 1) {
        t.cancel();
        _finish();
      }
    });
  }

  void _finish() {
    setState(() => _state = _simOk ? FaceState.success : FaceState.failed);
  }

  String get _stepText {
    if (_progress < 0.35) {
      return 'Mendeteksi wajah...';
    }
    if (_progress < 0.7) {
      return 'Mencocokkan biometrik dengan data akun...';
    }
    return 'Menyelesaikan verifikasi identitas...';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthStore>();
    final user = auth.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: EmptyState(
            icon: Icons.lock_outline,
            title: 'Sesi tidak ditemukan',
            message: 'Silakan masuk terlebih dahulu.',
            actionLabel: 'Ke Halaman Masuk',
            onAction: () => Navigator.of(context)
                .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false),
          ),
        ),
      );
    }

    final camera = Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 380),
        child: FaceCameraView(state: _state),
      ),
    );

    Widget statusWidget;
    switch (_state) {
      case FaceState.ready:
        statusWidget = const _StatusCard(
          icon: Icons.shield_outlined,
          color: AppColors.blue,
          title: 'Verifikasi Identitas Masuk',
          text:
              'Posisikan wajah Anda di dalam area oval dan pastikan pencahayaan cukup, lalu tekan tombol Mulai Verifikasi.',
        );
      case FaceState.scanning:
        statusWidget = AppCard(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_stepText,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: _progress.clamp(0, 1),
              minHeight: 8,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 6),
            Text('${(_progress.clamp(0, 1) * 100).round()}%',
                style: const TextStyle(color: AppColors.textSecondary)),
          ]),
        );
      case FaceState.success:
        statusWidget = _StatusCard(
          icon: Icons.check_circle,
          color: AppColors.success,
          title: 'Verifikasi Berhasil!',
          text:
              'Wajah cocok dengan data akun ${user.name}. Akses ke beranda SIPINTAR telah disetujui.',
        );
      case FaceState.failed:
        statusWidget = const _StatusCard(
          icon: Icons.cancel,
          color: AppColors.danger,
          title: 'Verifikasi Gagal',
          text:
              'Wajah tidak cocok dengan data biometrik yang terdaftar. Pastikan wajah terlihat jelas atau daftarkan ulang data wajah Anda.',
        );
    }

    final panel =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Info pengguna yang sedang login
      AppCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.navy,
              child: Text(
                user.initials,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 4),
                  IdentityBadge(user: user),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),

      // Petunjuk posisi
      const AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Panduan Verifikasi Wajah',
              style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text(
            '- Hadapkan wajah lurus ke arah kamera depan\n'
            '- Tempatkan wajah tepat di dalam garis oval\n'
            '- Lepas masker atau kacamata gelap\n'
            '- Pastikan ruangan memiliki pencahayaan cukup',
            style: TextStyle(height: 1.55, fontSize: 13),
          ),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),

      // Opsi simulasi hasil (untuk demo / pengetesan capstone)
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mode Simulasi Hasil',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: true, label: Text('Berhasil (Cocok)')),
              ButtonSegment(value: false, label: Text('Gagal (Tidak Cocok)')),
            ],
            selected: {_simOk},
            onSelectionChanged: _state == FaceState.scanning
                ? null
                : (s) => setState(() => _simOk = s.first),
          ),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),

      statusWidget,
      const SizedBox(height: AppSpacing.md),

      // Tombol aksi sesuai state
      if (_state == FaceState.ready)
        PrimaryButton(
          label: 'Mulai Verifikasi Wajah',
          icon: Icons.face_rounded,
          onPressed: _start,
        ),
      if (_state == FaceState.failed) ...[
        PrimaryButton(
          label: 'Ulangi Verifikasi',
          icon: Icons.refresh,
          onPressed: _start,
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () =>
              Navigator.of(context).pushNamed(AppRoutes.faceRegistration),
          icon: const Icon(Icons.app_registration_rounded),
          label: const Text('Daftarkan Ulang Data Wajah'),
        ),
      ],
      if (_state == FaceState.success)
        PrimaryButton(
          label: 'Masuk ke Beranda',
          icon: Icons.arrow_forward_rounded,
          onPressed: () => Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
        ),

      const SizedBox(height: AppSpacing.md),
      // Navigasi alternatif jika ingin ganti akun atau daftar wajah ulang
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: () {
              auth.logout();
              Navigator.of(context)
                  .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
            },
            icon: const Icon(Icons.logout, size: 16),
            label: const Text('Keluar / Ganti Akun'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pushNamed(AppRoutes.faceRegistration),
            child: const Text('Daftar Ulang Wajah'),
          ),
        ],
      ),
    ]);

    return AppPage(
      title: 'Verifikasi Wajah Masuk',
      body: PageList(
        children: [
          TwoPane(
            leftFlex: 1,
            rightFlex: 1,
            left: camera,
            right: panel,
            breakpoint: 760,
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title, text;
  const _StatusCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) => AppCard(
        color: color.withValues(alpha: 0.08),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title,
                  style: TextStyle(fontWeight: FontWeight.w800, color: color)),
              const SizedBox(height: 2),
              Text(text, style: const TextStyle(height: 1.4, fontSize: 13)),
            ]),
          ),
        ]),
      );
}
