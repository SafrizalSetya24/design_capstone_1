import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../data/models/user_model.dart';

/// Label role + identitas (NIS/NIK). Teks diambil dari model, sehingga
/// Siswa selalu tampil "NIS" dan Guru selalu tampil "NIK".
class IdentityBadge extends StatelessWidget {
  final AppUser user;
  final bool onDark;
  const IdentityBadge({super.key, required this.user, this.onDark = false});

  @override
  Widget build(BuildContext context) {
    final fg = onDark ? Colors.white : AppColors.navy;
    final bg = onDark ? Colors.white.withOpacity(0.16) : AppColors.blue.withOpacity(0.10);
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _chip(user.role.label, fg, bg, bold: true),
        _chip('${user.identityLabel}: ${user.identityValue}', fg, bg),
      ],
    );
  }

  Widget _chip(String text, Color fg, Color bg, {bool bold = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(
                color: fg, fontSize: 12, fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
      );
}
