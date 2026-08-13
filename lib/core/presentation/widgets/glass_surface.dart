import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A lightweight Liquid-Glass-inspired surface for navigation and controls.
///
/// It is intentionally used sparingly. Content cards should remain mostly
/// solid so text and medical information stay easy to read.
class GlassSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;
  final double blur;
  final double lightOpacity;
  final double darkOpacity;
  final Color? tint;
  final VoidCallback? onTap;

  const GlassSurface({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.blur = 20,
    this.lightOpacity = 0.68,
    this.darkOpacity = 0.46,
    this.tint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final base = tint ?? theme.colorScheme.surface;

    final content = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: base.withValues(alpha: isDark ? darkOpacity : lightOpacity),
            borderRadius: borderRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: isDark ? 0.10 : 0.55),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.18 : 0.06),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(padding: padding ?? EdgeInsets.zero, child: child),
        ),
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Semantics(
      button: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: content,
      ),
    );
  }
}
