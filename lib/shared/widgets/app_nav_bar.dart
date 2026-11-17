import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text.dart';

class NavDestination {
  const NavDestination(this.label, this.icon, this.selectedIcon);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

/// Floating pill navigation. The active tab grows into a soft pill with its
/// label; the others stay as quiet icons.
class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.destinations,
    required this.index,
    required this.onChanged,
  });

  final List<NavDestination> destinations;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 0, 24, bottom > 0 ? bottom : 16),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: AppColors.navy800,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.navyLine.withValues(alpha: 0.55),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy950.withValues(alpha: 0.55),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < destinations.length; i++)
                  Flexible(
                    // The active tab gets more room for its label.
                    flex: i == index ? 2 : 1,
                    child: _NavItem(
                      destination: destinations[i],
                      selected: i == index,
                      onTap: () {
                        if (i != index) HapticFeedback.selectionClick();
                        onChanged(i);
                      },
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

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOutCubic,
          height: 44,
          padding: EdgeInsets.symmetric(horizontal: selected ? 12 : 6),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.cream.withValues(alpha: 0.09)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  key: ValueKey(selected),
                  size: 23,
                  color: selected ? AppColors.mustard : AppColors.creamMuted,
                ),
              ),
              Flexible(
                child: AnimatedSize(
                  duration: const Duration(milliseconds: 280),
                  curve: Curves.easeOutCubic,
                  child: selected
                      ? Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Text(
                            destination.label,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.fade,
                            style: AppText.body(
                              14,
                              weight: FontWeight.w800,
                              color: AppColors.cream,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
