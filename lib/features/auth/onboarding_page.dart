import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../shared/widgets/primary_button.dart';
import '../../shared/widgets/responsive_body.dart';
import 'package:sipintar/app/routes.dart';

class _Slide {
  final IconData icon;
  final String title;
  final String body;
  const _Slide(this.icon, this.title, this.body);
}

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});
  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = [
    _Slide(Icons.event_available_rounded, 'Pinjam barang tanpa antre',
        'Ajukan peminjaman laptop, proyektor, atau kamera dari ponsel. Pantau persetujuan dan jadwal pengembalian langsung di aplikasi.'),
    _Slide(Icons.inventory_2_outlined, 'Lihat katalog inventaris',
        'Cek ketersediaan, kondisi, dan kode aset setiap barang sebelum mengajukan. Barang habis pakai juga bisa diminta dari sini.'),
  ];

  void _start() => Navigator.of(context).pushReplacementNamed(AppRoutes.login);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final last = _index == _slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: ResponsiveBody(
          maxWidth: 560,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                      onPressed: _start, child: const Text('Lewati')),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _slides.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (_, i) {
                      final s = _slides[i];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 160,
                            height: 160,
                            decoration: BoxDecoration(
                              color: AppColors.blue.withValues(alpha: 0.10),
                              shape: BoxShape.circle,
                            ),
                            child:
                                Icon(s.icon, size: 76, color: AppColors.navy),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(s.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.navy)),
                          const SizedBox(height: AppSpacing.md),
                          Text(s.body,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: AppColors.textSecondary)),
                        ],
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _slides.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _index ? AppColors.navy : AppColors.border,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: last ? 'Mulai' : 'Lanjut',
                  onPressed: last
                      ? _start
                      : () => _controller.nextPage(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
