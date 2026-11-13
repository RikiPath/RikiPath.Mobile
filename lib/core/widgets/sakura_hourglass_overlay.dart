import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

/// Lớp chờ tập trung cho các thao tác xác thực đã bắt đầu thực thi.
class SakuraHourglassOverlay extends StatefulWidget {
  const SakuraHourglassOverlay({
    required this.visible,
    required this.message,
    super.key,
  });

  final bool visible;
  final String message;

  @override
  State<SakuraHourglassOverlay> createState() => _SakuraHourglassOverlayState();
}

class _SakuraHourglassOverlayState extends State<SakuraHourglassOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1900),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
  }

  @override
  void didUpdateWidget(SakuraHourglassOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) _syncMotion();
  }

  void _syncMotion() {
    final media = MediaQuery.maybeOf(context);
    final reduceMotion =
        (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);
    if (!widget.visible || reduceMotion) {
      _turn.stop();
      _turn.value = 0;
    } else if (!_turn.isAnimating) {
      _turn.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _turn.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return IgnorePointer(
      ignoring: !widget.visible,
      child: AnimatedOpacity(
        opacity: widget.visible ? 1 : 0,
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 200),
        child: Semantics(
          container: true,
          liveRegion: true,
          label: widget.visible ? widget.message : null,
          child: ColoredBox(
            key: const ValueKey<String>('sakura_hourglass_overlay'),
            color: const Color(0xB0382B3D),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _turn,
                    builder: (context, child) {
                      final angle =
                          math.pi *
                          Curves.easeInOutCubic.transform(_turn.value);
                      return Transform.rotate(angle: angle, child: child);
                    },
                    child: Image.asset(
                      'assets/images/auth/sakura_hourglass.png',
                      width: 96,
                      height: 120,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: const Color(0xCC382B3D),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                        vertical: AppSpacing.space2,
                      ),
                      child: Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: AppTypography.sectionTitle.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
