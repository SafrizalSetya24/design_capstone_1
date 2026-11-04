import 'package:flutter/material.dart';
import 'package:sipintar/core/theme/app_colors.dart';

/// Barcode SIMULASI (pola batang dari kode aset), bukan standar Code 128 sungguhan.
class BarcodeView extends StatelessWidget {
  final String code;
  final double height;
  const BarcodeView({super.key, required this.code, this.height = 70});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(height: height, width: double.infinity, child: CustomPaint(painter: _BarcodePainter(code))),
          const SizedBox(height: 4),
          Text(code, style: const TextStyle(fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w700, color: Colors.black87)),
        ],
      ),
    );
  }
}

class _BarcodePainter extends CustomPainter {
  final String code;
  _BarcodePainter(this.code);
  @override
  void paint(Canvas canvas, Size size) {
    final widths = <int>[1, 1, 1];
    for (final cu in code.codeUnits) {
      widths..add(1 + cu % 3)..add(1 + (cu ~/ 3) % 3)..add(1 + (cu ~/ 9) % 3)..add(1 + (cu ~/ 27) % 2);
    }
    widths.addAll([1, 1, 1]);
    final total = widths.fold<int>(0, (a, b) => a + b);
    final unit = size.width / total;
    var x = 0.0;
    final paint = Paint()..color = Colors.black87;
    for (var i = 0; i < widths.length; i++) {
      final w = widths[i] * unit;
      if (i.isEven) canvas.drawRect(Rect.fromLTWH(x, 0, w, size.height), paint);
      x += w;
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodePainter old) => old.code != code;
}
