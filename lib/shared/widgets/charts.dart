import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:sipintar/core/theme/app_colors.dart';

class ChartSeries {
  final String name;
  final List<double?> values;
  final Color color;
  final bool dashed;
  const ChartSeries(this.name, this.values, this.color, {this.dashed = false});
}

class DonutSegment {
  final String label;
  final double value;
  final Color color;
  const DonutSegment(this.label, this.value, this.color);
}

void _text(Canvas c, String t, Offset o, double width,
    {double size = 10,
    Color color = AppColors.textSecondary,
    FontWeight w = FontWeight.w500,
    TextAlign align = TextAlign.center}) {
  final tp = TextPainter(
    text: TextSpan(
        text: t, style: TextStyle(fontSize: size, color: color, fontWeight: w)),
    textDirection: TextDirection.ltr,
    textAlign: align,
  )..layout(minWidth: width, maxWidth: width);
  tp.paint(c, o);
}

double _niceMax(double v) {
  if (v <= 0) return 10;
  final m = math.pow(10, (math.log(v) / math.ln10).floor()).toDouble();
  for (final f in [1, 2, 2.5, 5, 10]) {
    if (v <= f * m) return f * m;
  }
  return 10 * m;
}

Widget _legend(List<ChartSeries> s) => Wrap(
      spacing: 14,
      runSpacing: 4,
      children: [
        for (final x in s)
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: x.color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 6),
            Text(x.name,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ]),
      ],
    );

class BarChartView extends StatelessWidget {
  final List<String> labels;
  final List<ChartSeries> series;
  final double height;
  const BarChartView(
      {super.key,
      required this.labels,
      required this.series,
      this.height = 180});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              height: height,
              width: double.infinity,
              child: CustomPaint(painter: _BarPainter(labels, series))),
          if (series.length > 1 || series.first.name.isNotEmpty) ...[
            const SizedBox(height: 8),
            _legend(series)
          ],
        ],
      );
}

class _BarPainter extends CustomPainter {
  final List<String> labels;
  final List<ChartSeries> series;
  _BarPainter(this.labels, this.series);

  @override
  void paint(Canvas canvas, Size size) {
    const left = 30.0, bottom = 22.0, top = 14.0;
    final h = size.height - bottom - top;
    final w = size.width - left;
    var mx = 0.0;
    for (final s in series) {
      for (final v in s.values) {
        if (v != null && v > mx) mx = v;
      }
    }
    mx = _niceMax(mx);
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = top + h - h * i / 4;
      canvas.drawLine(Offset(left, y), Offset(size.width, y), grid);
      _text(canvas, (mx * i / 4).round().toString(), Offset(0, y - 6), left - 4,
          align: TextAlign.right);
    }
    final n = labels.length;
    final slot = w / n;
    final group = slot * 0.64;
    final bw = group / series.length;
    for (var i = 0; i < n; i++) {
      final gx = left + slot * i + (slot - group) / 2;
      for (var j = 0; j < series.length; j++) {
        final v =
            i < series[j].values.length ? (series[j].values[i] ?? 0) : 0.0;
        final bh = h * (v / mx);
        final r = RRect.fromRectAndCorners(
          Rect.fromLTWH(gx + bw * j + 1, top + h - bh, bw - 2, bh),
          topLeft: const Radius.circular(5),
          topRight: const Radius.circular(5),
        );
        canvas.drawRRect(r, Paint()..color = series[j].color);
        if (series.length == 1 && n <= 8) {
          _text(canvas, v.round().toString(),
              Offset(gx + bw * j - 8, top + h - bh - 14), bw + 14,
              color: AppColors.textPrimary, w: FontWeight.w700);
        }
      }
      _text(canvas, labels[i],
          Offset(left + slot * i, size.height - bottom + 5), slot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class LineChartView extends StatelessWidget {
  final List<String> labels;
  final List<ChartSeries> series;
  final double height;
  const LineChartView(
      {super.key,
      required this.labels,
      required this.series,
      this.height = 190});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              height: height,
              width: double.infinity,
              child: CustomPaint(painter: _LinePainter(labels, series))),
          const SizedBox(height: 8),
          _legend(series),
        ],
      );
}

class _LinePainter extends CustomPainter {
  final List<String> labels;
  final List<ChartSeries> series;
  _LinePainter(this.labels, this.series);

  @override
  void paint(Canvas canvas, Size size) {
    const left = 30.0, bottom = 22.0, top = 12.0, right = 12.0;
    final h = size.height - bottom - top;
    final w = size.width - left - right;
    var mx = 0.0;
    for (final s in series) {
      for (final v in s.values) {
        if (v != null && v > mx) mx = v;
      }
    }
    mx = _niceMax(mx);
    final grid = Paint()
      ..color = AppColors.border
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = top + h - h * i / 4;
      canvas.drawLine(Offset(left, y), Offset(size.width - right, y), grid);
      _text(canvas, (mx * i / 4).round().toString(), Offset(0, y - 6), left - 4,
          align: TextAlign.right);
    }
    final n = labels.length;
    double x(int i) => left + (n == 1 ? w / 2 : w * i / (n - 1));
    double y(double v) => top + h - h * (v / mx);
    for (var i = 0; i < n; i++) {
      _text(canvas, labels[i], Offset(x(i) - 20, size.height - bottom + 5), 40);
    }
    for (final s in series) {
      final paint = Paint()
        ..color = s.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6
        ..strokeCap = StrokeCap.round;
      final path = Path();
      var started = false;
      for (var i = 0; i < n && i < s.values.length; i++) {
        final v = s.values[i];
        if (v == null) {
          started = false;
          continue;
        }
        if (!started) {
          path.moveTo(x(i), y(v));
          started = true;
        } else {
          path.lineTo(x(i), y(v));
        }
      }
      if (s.dashed) {
        for (final m in path.computeMetrics()) {
          var d = 0.0;
          while (d < m.length) {
            canvas.drawPath(m.extractPath(d, math.min(d + 6, m.length)), paint);
            d += 10;
          }
        }
      } else {
        canvas.drawPath(path, paint);
      }
      for (var i = 0; i < n && i < s.values.length; i++) {
        final v = s.values[i];
        if (v == null) continue;
        canvas.drawCircle(Offset(x(i), y(v)), 4, Paint()..color = Colors.white);
        canvas.drawCircle(Offset(x(i), y(v)), 3, Paint()..color = s.color);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

class DonutChartView extends StatelessWidget {
  final List<DonutSegment> segments;
  final String centerValue;
  final String centerLabel;
  const DonutChartView(
      {super.key,
      required this.segments,
      required this.centerValue,
      required this.centerLabel});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                  size: const Size(130, 130), painter: _DonutPainter(segments)),
              Column(mainAxisSize: MainAxisSize.min, children: [
                Text(centerValue,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navy)),
                Text(centerLabel,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ]),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final s in segments)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(children: [
                    Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                            color: s.color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(
                        child: Text(s.label,
                            style: const TextStyle(fontSize: 13))),
                    Text(s.value.round().toString(),
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSegment> segs;
  _DonutPainter(this.segs);
  @override
  void paint(Canvas canvas, Size size) {
    final total = segs.fold<double>(0, (a, s) => a + s.value);
    final rect = Rect.fromLTWH(10, 10, size.width - 20, size.height - 20);
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 18
      ..color = AppColors.border;
    canvas.drawArc(rect, 0, math.pi * 2, false, base);
    if (total <= 0) return;
    var start = -math.pi / 2;
    for (final s in segs) {
      if (s.value <= 0) continue;
      final sweep = math.pi * 2 * s.value / total;
      canvas.drawArc(rect, start, math.max(0.0, sweep - 0.04), false,
          base..color = s.color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
