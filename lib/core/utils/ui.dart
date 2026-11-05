import 'package:flutter/material.dart';
import 'package:sipintar/core/theme/app_colors.dart';

void snack(BuildContext c, String m, {bool error = false}) {
  ScaffoldMessenger.of(c)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(m),
      backgroundColor: error ? AppColors.danger : AppColors.navy,
      behavior: SnackBarBehavior.floating,
    ));
}

Future<bool> confirm(BuildContext c,
    {required String title,
    required String message,
    String confirmLabel = 'Ya',
    bool danger = false}) async {
  final r = await showDialog<bool>(
    context: c,
    builder: (_) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal')),
        FilledButton(
          style: FilledButton.styleFrom(
              backgroundColor: danger ? AppColors.danger : AppColors.navy,
              minimumSize: const Size(96, 44)),
          onPressed: () => Navigator.pop(c, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return r ?? false;
}

Future<T?> push<T>(BuildContext c, Widget page) =>
    Navigator.of(c).push<T>(MaterialPageRoute<T>(builder: (_) => page));

void popToRoot(BuildContext c) => Navigator.of(c).popUntil((r) => r.isFirst);

/// Simulasi ekspor/cetak berkas (tanpa berkas sungguhan).
Future<void> simulateExport(BuildContext c, String fileName) async {
  showDialog<void>(
    context: c,
    barrierDismissible: false,
    builder: (_) => const AlertDialog(
      content: Row(children: [
        CircularProgressIndicator(),
        SizedBox(width: 16),
        Expanded(child: Text('Menyiapkan berkas...')),
      ]),
    ),
  );
  await Future.delayed(const Duration(milliseconds: 1100));
  if (!c.mounted) return;
  Navigator.of(c, rootNavigator: true).pop();
  snack(c, '$fileName berhasil dibuat (simulasi).');
}
