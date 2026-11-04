import 'package:flutter/material.dart';
import 'package:sipintar/core/theme/app_colors.dart';
import 'package:sipintar/shared/widgets/app_card.dart';
import 'package:sipintar/shared/widgets/responsive_widgets.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  const StatCard({super.key, required this.icon, required this.value, required this.label, this.color = AppColors.blue, this.onTap});

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      );
}

/// Grid statistik: 2 kolom kecil di mobile, bertambah otomatis pada layar lebar.
class StatGrid extends StatelessWidget {
  final List<StatCard> cards;
  final double minItemWidth;
  const StatGrid(this.cards, {super.key, this.minItemWidth = 150});
  @override
  Widget build(BuildContext context) => ResponsiveGrid(minItemWidth: minItemWidth, children: cards);
}
