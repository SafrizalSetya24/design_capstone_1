import 'package:flutter/material.dart';

enum ScreenSize { mobile, tablet, desktop }

/// Breakpoint konsisten untuk seluruh aplikasi.
/// Mobile < 600, Tablet 600-1023, Desktop >= 1024.
class Breakpoints {
  Breakpoints._();
  static const double mobile = 600;
  static const double desktop = 1024;

  static ScreenSize of(double width) {
    if (width < mobile) return ScreenSize.mobile;
    if (width < desktop) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  /// Jumlah kolom grid berdasarkan lebar area konten (bukan lebar jendela).
  static int columns(double width,
      {int mobile = 1, int tablet = 2, int desktop = 3}) {
    switch (of(width)) {
      case ScreenSize.mobile:
        return mobile;
      case ScreenSize.tablet:
        return tablet;
      case ScreenSize.desktop:
        return desktop;
    }
  }
}

extension ResponsiveContext on BuildContext {
  /// Ukuran berdasarkan lebar jendela penuh (MediaQuery).
  ScreenSize get screen => Breakpoints.of(MediaQuery.of(this).size.width);
  bool get isMobile => screen == ScreenSize.mobile;
  bool get isDesktop => screen == ScreenSize.desktop;
}

/// Membangun UI berdasarkan lebar area yang tersedia (LayoutBuilder).
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, ScreenSize size, double width)
      builder;
  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (c, cons) {
          final w = cons.maxWidth.isFinite
              ? cons.maxWidth
              : MediaQuery.of(c).size.width;
          return builder(c, Breakpoints.of(w), w);
        },
      );
}
