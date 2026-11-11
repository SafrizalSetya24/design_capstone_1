import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

// Logo identitas visual Inventaris Muhamka
class SipintarLogo extends StatelessWidget {
  /// Ukuran sisi persegi logo (default 88px)
  final double size;

  /// Mode inverted (putih di background gelap atau sebaliknya)
  final bool inverted;

  const SipintarLogo({
    super.key, 
    this.size = 88, 
    this.inverted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: inverted ? Colors.white : AppColors.navy,
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Center(
        child: Icon(
          Icons.inventory_2_rounded,
          size: size * 0.52,
          color: inverted ? AppColors.navy : Colors.white,
        ),
      ),
    );
  }
}
