import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sipintar/app/routes.dart';
import 'package:sipintar/core/core.dart';
import 'package:sipintar/data/stores/auth_store.dart';

Future<void> confirmLogout(BuildContext c) async {
  final ok = await confirm(c,
      title: 'Keluar dari akun?',
      message: 'Anda perlu masuk lagi untuk menggunakan SIPINTAR.',
      confirmLabel: 'Keluar',
      danger: true);
  if (!ok || !c.mounted) return;
  final nav = Navigator.of(c, rootNavigator: true);
  c.read<AuthStore>().logout();
  nav.pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
}
