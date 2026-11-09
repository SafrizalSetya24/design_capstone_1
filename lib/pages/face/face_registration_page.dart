import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/app/routes.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/data.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

class FaceRegistrationPage extends StatefulWidget {
  const FaceRegistrationPage({super.key});

  @override
  State<FaceRegistrationPage> createState() => _FaceRegistrationPageState();
}

class _FaceRegistrationPageState extends State<FaceRegistrationPage> {
  bool _scanning = false;
  bool _success = false;

  Future<void> _capture() async {
    setState(() => _scanning = true);
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;

    final auth = context.read<AuthStore>();
    auth.registerFace();

    setState(() {
      _scanning = false;
      _success = true;
    });

    await Future.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;

    Navigator.of(context).pushReplacementNamed(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = context.watch<AuthStore>().currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrasi Biometrik Wajah'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: AppCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Pendaftaran Profil Wajah',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Halo, ${user?.name ?? "Pengguna"}! Wajah Anda didaftarkan untuk verifikasi otomatis sebelum mengajukan peminjaman barang.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 20),

                    // Kotak Kamera Depan
                    Container(
                      height: 280,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _success
                              ? Colors.green
                              : _scanning
                                  ? AppColors.primary
                                  : Colors.grey.shade700,
                          width: 2.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            const FakeCamera(isFront: true),
                            Center(
                              child: Container(
                                width: 170,
                                height: 210,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(90),
                                  border: Border.all(
                                    color: _success
                                        ? Colors.green
                                        : _scanning
                                            ? Colors.yellowAccent
                                            : Colors.white.withValues(alpha: 0.6),
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                            if (_scanning)
                              Container(
                                color: Colors.black45,
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(color: Colors.white),
                                      SizedBox(height: 12),
                                      Text(
                                        'Mendeteksi titik fitur wajah...',
                                        style: TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (_success)
                              Container(
                                color: Colors.black54,
                                child: const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 48),
                                      SizedBox(height: 10),
                                      Text(
                                        'Profil Wajah Berhasil Disimpan!',
                                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lightbulb_outline, size: 16, color: Colors.amber),
                        SizedBox(width: 6),
                        Text(
                          'Posisikan wajah di dalam bingkai oval dengan pencahayaan cukup',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    PrimaryButton(
                      label: _scanning
                          ? 'Memproses Wajah...'
                          : _success
                              ? 'Menyimpan...'
                              : 'Ambil Foto & Simpan Profil Wajah',
                      icon: Icons.camera_alt_outlined,
                      loading: _scanning,
                      onPressed: (_scanning || _success) ? null : _capture,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
