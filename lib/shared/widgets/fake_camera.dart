import 'package:flutter/material.dart';
import 'package:sipintar/core/theme/app_colors.dart';

enum FaceState { ready, scanning, success, failed }

Widget _cameraBase(
        {required Widget child, IconData icon = Icons.person_rounded}) =>
    ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF1B2540), Color(0xFF0A1022)]),
        ),
        child: Stack(fit: StackFit.expand, children: [
          Align(
              alignment: const Alignment(0, 0.15),
              child: Icon(icon, size: 190, color: Colors.white10)),
          child,
        ]),
      ),
    );

/// Tampilan kamera depan SIMULASI dengan panduan oval wajah.
class FaceCameraView extends StatefulWidget {
  final FaceState state;
  const FaceCameraView({super.key, required this.state});
  @override
  State<FaceCameraView> createState() => _FaceCameraViewState();
}

class _FaceCameraViewState extends State<FaceCameraView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1500))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 4,
      child: _cameraBase(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) =>
              CustomPaint(painter: _FacePainter(widget.state, _c.value)),
        ),
      ),
    );
  }
}

class _FacePainter extends CustomPainter {
  final FaceState state;
  final double t;
  _FacePainter(this.state, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final oval = Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.46),
        width: size.width * 0.62,
        height: size.height * 0.55);
    final hole = Path()..addOval(oval);
    final scrim = Path.combine(
        PathOperation.difference, Path()..addRect(Offset.zero & size), hole);
    canvas.drawPath(scrim, Paint()..color = Colors.black54);
    final color = switch (state) {
      FaceState.ready => Colors.white,
      FaceState.scanning => const Color(0xFF6EA8FF),
      FaceState.success => AppColors.success,
      FaceState.failed => AppColors.danger,
    };
    canvas.drawOval(
        oval,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..color = color);
    if (state == FaceState.scanning) {
      canvas.save();
      canvas.clipPath(hole);
      final y = oval.top + oval.height * t;
      canvas.drawRect(
        Rect.fromLTWH(oval.left, y - 14, oval.width, 28),
        Paint()
          ..shader = LinearGradient(colors: [
            Colors.transparent,
            color.withValues(alpha: 0.55),
            Colors.transparent
          ], begin: Alignment.topCenter, end: Alignment.bottomCenter)
              .createShader(Rect.fromLTWH(oval.left, y - 14, oval.width, 28)),
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _FacePainter old) => true;
}

/// Tampilan kamera pemindai barcode SIMULASI.
class ScanFrameView extends StatefulWidget {
  final bool scanning;
  final double aspect;
  const ScanFrameView({super.key, required this.scanning, this.aspect = 4 / 3});
  @override
  State<ScanFrameView> createState() => _ScanFrameViewState();
}

class _ScanFrameViewState extends State<ScanFrameView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
    ..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: widget.aspect,
      child: _cameraBase(
        icon: Icons.qr_code_2_rounded,
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, __) =>
              CustomPaint(painter: _ScanPainter(widget.scanning, _c.value)),
        ),
      ),
    );
  }
}

class _ScanPainter extends CustomPainter {
  final bool scanning;
  final double t;
  _ScanPainter(this.scanning, this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final r = Rect.fromCenter(
        center: size.center(Offset.zero),
        width: size.width * 0.72,
        height: size.height * 0.46);
    final p = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    const l = 26.0;
    for (final c in [r.topLeft, r.topRight, r.bottomLeft, r.bottomRight]) {
      final dx = c.dx == r.left ? 1.0 : -1.0;
      final dy = c.dy == r.top ? 1.0 : -1.0;
      canvas.drawLine(c, c.translate(dx * l, 0), p);
      canvas.drawLine(c, c.translate(0, dy * l), p);
    }
    if (scanning) {
      final y = r.top + r.height * t;
      canvas.drawLine(
          Offset(r.left + 8, y),
          Offset(r.right - 8, y),
          Paint()
            ..color = AppColors.danger
            ..strokeWidth = 2.5);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanPainter old) => true;
}
