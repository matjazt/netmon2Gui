import 'package:flutter/material.dart';

/// Provides [openDrawer] to widgets nested inside [MainScaffold]'s narrow
/// layout, allowing them to open the navigation drawer even when they own
/// their own inner [Scaffold].
class ShellScope extends InheritedWidget {
  final VoidCallback openDrawer;

  const ShellScope({super.key, required this.openDrawer, required super.child});

  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope old) => openDrawer != old.openDrawer;
}

/// An [AppBar] leading widget that shows a hamburger icon in narrow (shell)
/// mode so that screens with their own inner [Scaffold] can open the
/// navigation drawer. Returns an empty widget on wide screens where the
/// [NavigationRail] is always visible and no drawer exists.
class ShellMenuLeading extends StatelessWidget {
  const ShellMenuLeading({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = ShellScope.maybeOf(context);
    if (shell == null) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.menu),
      tooltip: 'Open navigation menu',
      onPressed: shell.openDrawer,
    );
  }
}

/// An [AppBar] action widget that opens the global navigation drawer when the
/// app runs in narrow layout.
class ShellMenuAction extends StatelessWidget {
  const ShellMenuAction({super.key});

  @override
  Widget build(BuildContext context) {
    final shell = ShellScope.maybeOf(context);
    if (shell == null) return const SizedBox.shrink();
    return IconButton(
      icon: const Icon(Icons.menu),
      tooltip: 'Open navigation menu',
      onPressed: shell.openDrawer,
    );
  }
}
