import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/app/routes.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

/// Halaman Pendaftaran Data Wajah (UI Flow Simulasi).
/// Ditampilkan ketika pengguna belum mendaftarkan data wajah setelah login.
class FaceRegistrationPage extends StatefulWidget {
  const FaceRegistrationPage({super.key});

  @override
  State<FaceRegistrationPage> createState() => _FaceRegistrationPageState();
}

class _FaceRegistrationPageState extends State<FaceRegistrationPage> {
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
    if (_simOk) {
      context.read<AuthStore>().setFaceRegistered(true);
      setState(() => _state = FaceState.success);
    } else {
      setState(() => _state = FaceState.failed);
    }
  }

  String get _stepText {
    if (_progress < 0.30) {
      return 'Mendeteksi posisi wajah...';
    }
    if (_progress < 0.60) {
      return 'Merekam kontur biometrik wajah...';
    }
    if (_progress < 0.90) {
      return 'Mengekstrak dan mengenkripsi ciri biometrik...';
    }
    return 'Menyimpan data wajah ke sistem...';
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
          icon: Icons.info_outline,
          color: AppColors.blue,
          title: 'Siap Merekam Data Wajah',
          text:
              'Posisikan wajah Anda tepat di dalam area oval. Pastikan wajah tidak tertutup masker atau kacamata, lalu tekan tombol Mulai Perekaman.',
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
        statusWidget = const _StatusCard(
          icon: Icons.check_circle,
          color: AppColors.success,
          title: 'Pendaftaran Wajah Berhasil!',
          text:
              'Data biometrik wajah Anda telah tersimpan dengan aman di sistem. Anda kini siap melakukan verifikasi wajah untuk masuk ke beranda.',
        );
      case FaceState.failed:
        statusWidget = const _StatusCard(
          icon: Icons.cancel,
          color: AppColors.danger,
          title: 'Perekaman Wajah Gagal',
          text:
              'Kamera tidak dapat mendeteksi kontur wajah dengan jelas. Pastikan pencahayaan cukup dan ulangi perekaman.',
        );
    }

    final panel =
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      // Banner peringatan belum mendaftarkan wajah
      AppCard(
        color: AppColors.warning.withValues(alpha: 0.10),
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded,
                color: AppColors.warning, size: 26),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Data Wajah Belum Ditambahkan',
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.warning,
                        fontSize: 14),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Akun Anda belum memiliki rekaman data biometrik wajah. Daftarkan wajah Anda terlebih dahulu agar dapat melanjutkan ke beranda aplikasi.',
                    style: TextStyle(fontSize: 12.5, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),

      // Info akun pengguna
      AppCard(
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
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
                          fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 4),
                  IdentityBadge(user: user),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),

      // Panduan pendaftaran wajah
      const AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Panduan Perekaman Wajah',
              style: TextStyle(fontWeight: FontWeight.w800)),
          SizedBox(height: 6),
          Text(
            '1. Arahkan kamera lurus ke depan wajah\n'
            '2. Sesuaikan jarak hingga wajah berada di dalam oval\n'
            '3. Hindari backlight atau pencahayaan terlalu gelap\n'
            '4. Tetap rileks dan jangan banyak bergerak saat merekam',
            style: TextStyle(height: 1.6, fontSize: 13),
          ),
        ]),
      ),
      const SizedBox(height: AppSpacing.md),

      // Opsi simulasi hasil pendaftaran
      AppCard(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Mode Simulasi Hasil',
              style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: true, label: Text('Berhasil')),
              ButtonSegment(value: false, label: Text('Gagal')),
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

      // Tombol aksi
      if (_state == FaceState.ready)
        PrimaryButton(
          label: 'Mulai Perekaman Wajah',
          icon: Icons.camera_alt_rounded,
          onPressed: _start,
        ),
      if (_state == FaceState.failed)
        PrimaryButton(
          label: 'Ulangi Perekaman',
          icon: Icons.refresh,
          onPressed: _start,
        ),
      if (_state == FaceState.success) ...[
        PrimaryButton(
          label: 'Lanjut ke Verifikasi Wajah',
          icon: Icons.face_rounded,
          onPressed: () => Navigator.of(context)
              .pushReplacementNamed(AppRoutes.loginFaceVerification),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          onPressed: () => Navigator.of(context)
              .pushNamedAndRemoveUntil(AppRoutes.home, (_) => false),
          icon: const Icon(Icons.arrow_forward_rounded),
          label: const Text('Langsung Masuk ke Beranda'),
        ),
      ],

      const SizedBox(height: AppSpacing.md),
      Align(
        alignment: Alignment.center,
        child: TextButton.icon(
          onPressed: () {
            auth.logout();
            Navigator.of(context)
                .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
          },
          icon: const Icon(Icons.arrow_back, size: 16),
          label: const Text('Batal dan Kembali ke Halaman Masuk'),
        ),
      ),
    ]);

    return AppPage(
      title: 'Pendaftaran Data Wajah',
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
