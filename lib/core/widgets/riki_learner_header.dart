import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

/// Shared top app bar for the five learner-shell destinations.
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
    super.key,
  });

  static const double height = 64;

  final Widget title;
  final List<Widget> actions;
  final Widget? leading;
  final double? leadingWidth;
  final double titleSpacing;

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
      flexibleSpace: const DecoratedBox(
        decoration: BoxDecoration(boxShadow: AppShadows.learnerHeader),
      ),
      leading: leading,
      leadingWidth: leadingWidth,
      title: title,
      actions: actions,
    );
  }
}
