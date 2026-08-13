import 'package:flutter/material.dart';

import 'glass_surface.dart';

class GlassIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const GlassIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GlassSurface(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        padding: const EdgeInsets.all(12),
        child: Icon(icon, size: 22),
      ),
    );
  }
}
