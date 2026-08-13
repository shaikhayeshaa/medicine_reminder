import 'package:flutter/material.dart';

/// Shared edge-to-edge background used across the app.
/// Decorative gradients provide depth for the glass navigation/controls.
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? const [
                  Color(0xFF07111F),
                  Color(0xFF0B1728),
                  Color(0xFF071B1D),
                ]
              : const [
                  Color(0xFFF8FBFF),
                  Color(0xFFF2F7FF),
                  Color(0xFFF1FBFA),
                ],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -90,
            right: -70,
            child: _GlowOrb(
              size: 260,
              color: scheme.primary.withValues(
                alpha: isDark ? 0.18 : 0.14,
              ),
            ),
          ),
          Positioned(
            top: 260,
            left: -100,
            child: _GlowOrb(
              size: 220,
              color: scheme.secondary.withValues(
                alpha: isDark ? 0.13 : 0.12,
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            right: -90,
            child: _GlowOrb(
              size: 300,
              color: scheme.tertiary.withValues(
                alpha: isDark ? 0.10 : 0.09,
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color,
              color.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}
