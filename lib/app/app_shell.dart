import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/presentation/widgets/glass_surface.dart';

class AppShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({
    super.key,
    required this.navigationShell,
  });

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: GlassSurface(
          borderRadius: BorderRadius.circular(28),
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              _NavItem(
                label: 'Today',
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                selected: navigationShell.currentIndex == 0,
                onTap: () => _onDestinationSelected(0),
              ),
              _NavItem(
                label: 'History',
                icon: Icons.history_outlined,
                selectedIcon: Icons.history_rounded,
                selected: navigationShell.currentIndex == 1,
                onTap: () => _onDestinationSelected(1),
              ),
              _NavItem(
                label: 'Settings',
                icon: Icons.tune_outlined,
                selectedIcon: Icons.tune_rounded,
                selected: navigationShell.currentIndex == 2,
                onTap: () => _onDestinationSelected(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Expanded(
      child: Semantics(
        selected: selected,
        button: true,
        label: label,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primary.withValues(alpha: 0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  selected ? selectedIcon : icon,
                  color: selected
                      ? scheme.primary
                      : scheme.onSurfaceVariant,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  maxLines: 1,
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(
                        color: selected
                            ? scheme.primary
                            : scheme.onSurfaceVariant,
                        fontWeight: selected
                            ? FontWeight.w800
                            : FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
