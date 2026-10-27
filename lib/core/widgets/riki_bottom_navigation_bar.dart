import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';

class RikiBottomNavigationBar extends StatelessWidget {
  const RikiBottomNavigationBar({
    required this.selectedIndex,
    required this.onDestinationSelected,
    super.key,
  }) : assert(selectedIndex >= 0 && selectedIndex < destinationCount);

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const int destinationCount = 5;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final destinations = <RikiNavigationDestination>[
      RikiNavigationDestination(
        label: l10n.navigationHome,
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
      ),
      RikiNavigationDestination(
        label: l10n.navigationLearn,
        icon: Icons.menu_book_outlined,
        selectedIcon: Icons.menu_book,
      ),
      RikiNavigationDestination(
        label: l10n.navigationPractice,
        icon: Icons.quiz_outlined,
        selectedIcon: Icons.quiz,
      ),
      RikiNavigationDestination(
        label: l10n.navigationNotebook,
        icon: Icons.style_outlined,
        selectedIcon: Icons.style,
      ),
      RikiNavigationDestination(
        label: l10n.navigationProfile,
        icon: Icons.person_outline,
        selectedIcon: Icons.person,
      ),
    ];
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.cardBorderSubtle)),
        boxShadow: AppShadows.learnerBottomNavigation,
      ),
      child: Material(
        color: AppColors.surface,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: List<Widget>.generate(destinations.length, (index) {
                final destination = destinations[index];
                return Expanded(
                  child: _NavigationItem(
                    destination: destination,
                    selected: selectedIndex == index,
                    onPressed: () => onDestinationSelected(index),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class RikiNavigationDestination {
  const RikiNavigationDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

class _NavigationItem extends StatelessWidget {
  const _NavigationItem({
    required this.destination,
    required this.selected,
    required this.onPressed,
  });

  final RikiNavigationDestination destination;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final foreground = selected
        ? AppColors.brandPrimary
        : AppColors.textSecondary;

    return Semantics(
      key: ValueKey<String>('bottom_navigation_item_${destination.label}'),
      button: true,
      selected: selected,
      label: destination.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 48,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selected
                      ? AppColors.learnerPrimaryFixed
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Icon(
                  selected ? destination.selectedIcon : destination.icon,
                  color: foreground,
                  size: 22,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.badgeText.copyWith(
                  color: foreground,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
