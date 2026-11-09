import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

/// Shared top app bar for learner-shell destinations and contextual subpages.
///
/// Keeping the surface, height, horizontal alignment, and elevation here
/// prevents the header from shifting when users switch bottom-navigation tabs.
class RikiLearnerHeader extends StatelessWidget implements PreferredSizeWidget {
  const RikiLearnerHeader({
    required this.title,
    this.actions = const <Widget>[],
    this.leading,
    this.leadingWidth,
    this.titleSpacing = AppSpacing.space4,
    this.isScrolled = false,
    super.key,
  });

  static const double height = 64;

  final Widget title;
  final List<Widget> actions;
  final Widget? leading;
  final double? leadingWidth;
  final double titleSpacing;
  final bool isScrolled;

  @override
  Size get preferredSize => const Size.fromHeight(height);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: height,
      titleSpacing: titleSpacing,
      elevation: 0,
      scrolledUnderElevation: 0,
      flexibleSpace: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: isScrolled ? AppShadows.learnerHeaderScrolled : const [],
          border: isScrolled
              ? const Border(
                  bottom: BorderSide(
                    color: Color(0x0A000000),
                    width: 0.5,
                  ),
                )
              : null,
        ),
      ),
      leading: leading,
      leadingWidth: leadingWidth,
      title: title,
      actions: actions,
    );
  }
}
