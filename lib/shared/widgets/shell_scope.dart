import 'package:flutter/material.dart';

/// Diberikan oleh AdaptiveShell kepada halaman di dalam area konten.
class ShellScope extends InheritedWidget {
  final bool showMenu;
  final VoidCallback openDrawer;
  final void Function(String id, {int arg}) go;
  final String current;

  const ShellScope({
    super.key,
    required this.showMenu,
    required this.openDrawer,
    required this.go,
    required this.current,
    required super.child,
  });

  static ShellScope? maybeOf(BuildContext c) => c.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope old) => old.showMenu != showMenu || old.current != current;
}
