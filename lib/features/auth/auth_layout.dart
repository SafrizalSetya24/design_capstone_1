import 'package:flutter/material.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/shared/widgets/widgets.dart';

/// Layout autentikasi responsif: dua panel (brand + form) pada layar lebar,
/// satu kolom pada tablet/mobile.
class AuthLayout extends StatelessWidget {
  final Widget child;
  final bool showBack;
  const AuthLayout({super.key, required this.child, this.showBack = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (context, cons) {
        final wide = cons.maxWidth >= 900;
        final form = SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(cons.maxWidth < Breakpoints.mobile
                  ? AppSpacing.md
                  : AppSpacing.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 460),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showBack)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                              onPressed: () => Navigator.of(context).maybePop(),
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Kembali')),
                        ),
                      if (!wide) ...[
                        const Align(
                            alignment: Alignment.centerLeft,
                            child: SipintarLogo(size: 56)),
                        const SizedBox(height: AppSpacing.md),
                      ],
                      child,
                    ]),
              ),
            ),
          ),
        );
        if (!wide) return form;
        return Row(children: [
          const Expanded(flex: 5, child: _BrandPanel()),
          Expanded(flex: 4, child: form),
        ]);
      }),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();
  @override
  Widget build(BuildContext context) {
    Widget feature(IconData i, String t, String d) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(i, color: Colors.white),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    const SizedBox(height: 2),
                    Text(d,
                        style: const TextStyle(
                            color: Color(0xFFBFD3F5), height: 1.4)),
                  ]),
            ),
          ]),
        );
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.navy, Color(0xFF123B82)]),
      ),
      padding: const EdgeInsets.all(56),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SipintarLogo(size: 84, inverted: true),
                const SizedBox(height: 28),
                const Text('SIPINTAR',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 40,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5)),
                const SizedBox(height: 8),
                const Text('Kelola Inventaris Sekolah dengan Mudah',
                    style: TextStyle(color: Color(0xFFBFD3F5), fontSize: 18)),
                const SizedBox(height: 40),
                feature(
                    Icons.event_available_rounded,
                    'Pinjam barang tanpa antre',
                    'Ajukan dari ponsel atau komputer, pantau statusnya langsung.'),
                feature(Icons.face_retouching_natural, 'Verifikasi wajah',
                    'Peminjaman barang per unit lebih aman dan tercatat jelas.'),
                feature(Icons.inventory_2_outlined, 'Inventaris terpantau',
                    'Kondisi, stok, dan riwayat barang tersimpan rapi.'),
              ]),
        ),
      ),
    );
  }
}
