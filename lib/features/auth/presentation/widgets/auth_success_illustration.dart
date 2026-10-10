import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';

class AuthSuccessIllustration extends StatefulWidget {
  const AuthSuccessIllustration({
    required this.icon,
    this.animate = true,
    super.key,
  });

  final IconData icon;
  final bool animate;

  @override
  State<AuthSuccessIllustration> createState() =>
      _AuthSuccessIllustrationState();
}

class _AuthSuccessIllustrationState extends State<AuthSuccessIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final Animation<double> _opacity = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<double> _scale = Tween<double>(
    begin: 0.92,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
  bool _hasResolvedMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_hasResolvedMotion) return;
    _hasResolvedMotion = true;
    final mediaQuery = MediaQuery.maybeOf(context);
    final reduceMotion =
        (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);
    if (!widget.animate || reduceMotion) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      key: const ValueKey<String>('auth_success_motion'),
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: Semantics(
          image: true,
          label: context.l10n.successSemantics,
          child: SizedBox.square(
            dimension: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 144,
                  height: 144,
                  decoration: const BoxDecoration(
                    color: AppColors.successBackground,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 108,
                  height: 108,
                  decoration: const BoxDecoration(
                    color: AppColors.successBackgroundSoft,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: AppColors.successBorderSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.icon, size: 38, color: AppColors.success),
                ),
                Positioned(
                  right: 20,
                  bottom: 24,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.successAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 24,
                    ),
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
