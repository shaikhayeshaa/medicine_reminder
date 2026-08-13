import 'dart:ui';

import 'package:flutter/material.dart';

/// A stable glass-style app bar that paints its own background.
///
/// Unlike a fully transparent [AppBar], this widget does not depend on the
/// page body being rendered behind the toolbar. That prevents the black/dark
/// strip that can appear on transparent scaffolds while keeping the modern
/// translucent visual style.
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;

  const GlassAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      title: Text(title),
      leading: leading,
      actions: actions,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: isDark ? 0.84 : 0.78),
              border: Border(
                bottom: BorderSide(
                  color: scheme.outlineVariant.withValues(
                    alpha: isDark ? 0.28 : 0.42,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
