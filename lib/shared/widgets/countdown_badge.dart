import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sipintar/core/theme/app_colors.dart';
import 'package:sipintar/core/utils/format.dart';

class CountdownBadge extends StatefulWidget {
  final DateTime deadline;
  final VoidCallback? onExpired;
  final bool big;
  const CountdownBadge(
      {super.key, required this.deadline, this.onExpired, VoidCallback? onExpire, this.big = false});
  @override
  State<CountdownBadge> createState() => _CountdownBadgeState();
}

class _CountdownBadgeState extends State<CountdownBadge> {
  Timer? _t;
  bool _fired = false;

  @override
  void initState() {
    super.initState();
    _t = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (widget.deadline.difference(DateTime.now()).isNegative && !_fired) {
        _fired = true;
        widget.onExpired?.call();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rem = widget.deadline.difference(DateTime.now());
    final urgent = rem.inHours < 1;
    final color = rem.isNegative
        ? AppColors.danger
        : (urgent ? AppColors.danger : AppColors.warning);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: widget.big ? 16 : 10, vertical: widget.big ? 12 : 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.schedule, size: widget.big ? 18 : 14, color: color),
        const SizedBox(width: 6),
        Text(rem.isNegative ? 'Kedaluwarsa' : Fmt.countdown(rem),
            style: TextStyle(
                color: color,
                fontSize: widget.big ? 14 : 12,
                fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
