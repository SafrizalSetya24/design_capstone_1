import 'package:flutter/material.dart';
import 'package:sipintar/core/theme/app_colors.dart';

/// Ilustrasi barang (ikon + latar gradasi) sebagai pengganti foto, tanpa aset eksternal.
class ItemIcons {
  ItemIcons._();
  static const keys = [
    'laptop',
    'proyektor',
    'kamera',
    'speaker',
    'mikrofon',
    'kertas',
    'pulpen',
    'spidol',
    'tinta',
    'penghapus',
    'umum'
  ];
  static const labels = {
    'laptop': 'Laptop',
    'proyektor': 'Proyektor',
    'kamera': 'Kamera',
    'speaker': 'Speaker',
    'mikrofon': 'Mikrofon',
    'kertas': 'Kertas',
    'pulpen': 'Pulpen',
    'spidol': 'Spidol',
    'tinta': 'Tinta',
    'penghapus': 'Penghapus',
    'umum': 'Umum',
  };
  static IconData icon(String k) => switch (k) {
        'laptop' => Icons.laptop_mac_rounded,
        'proyektor' => Icons.slideshow_rounded,
        'kamera' => Icons.photo_camera_rounded,
        'speaker' => Icons.speaker_rounded,
        'mikrofon' => Icons.mic_rounded,
        'kertas' => Icons.description_rounded,
        'pulpen' => Icons.edit_rounded,
        'spidol' => Icons.brush_rounded,
        'tinta' => Icons.water_drop_rounded,
        'penghapus' => Icons.cleaning_services_rounded,
        _ => Icons.inventory_2_rounded,
      };
  static Color color(String k) => switch (k) {
        'laptop' => const Color(0xFF1F6FEB),
        'proyektor' => const Color(0xFF0B2A5B),
        'kamera' => const Color(0xFF3B5BA9),
        'speaker' => const Color(0xFF2B7BB9),
        'mikrofon' => const Color(0xFF4A6FA5),
        'kertas' => const Color(0xFF5B8DEF),
        'pulpen' => const Color(0xFF2E4A7D),
        'spidol' => const Color(0xFF1B5FBF),
        'tinta' => const Color(0xFF16508F),
        'penghapus' => const Color(0xFF4F7CAC),
        _ => AppColors.navy,
      };
}

class ItemImage extends StatelessWidget {
  final String iconKey;
  final double size;
  final double? height;
  const ItemImage(
      {super.key, required this.iconKey, this.size = 64, this.height});

  @override
  Widget build(BuildContext context) {
    final c = ItemIcons.color(iconKey);
    return Container(
      width: size,
      height: height ?? size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c.withValues(alpha: 0.10), c.withValues(alpha: 0.24)],
        ),
      ),
      child:
          Icon(ItemIcons.icon(iconKey), size: (height ?? size) * 0.5, color: c),
    );
  }
}

class ItemIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? color;
  const ItemIcon({super.key, required this.name, this.size = 24, this.color});

  @override
  Widget build(BuildContext context) {
    return Icon(ItemIcons.icon(name), size: size, color: color ?? ItemIcons.color(name));
  }
}
