import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_card.dart';

/// RikiPath's default Japanese-inspired loading mark.
///
/// The incomplete ensō, study card, and restrained sakura petals keep the
/// motion recognizable without looking like a generic platform spinner.
class RikiAnimatedStudyLoader extends StatefulWidget {
  const RikiAnimatedStudyLoader({
    this.size = 112,
    this.semanticsLabel,
    super.key,
  });

  final double size;
  final String? semanticsLabel;

  @override
  State<RikiAnimatedStudyLoader> createState() =>
      _RikiAnimatedStudyLoaderState();
}

class _RikiAnimatedStudyLoaderState extends State<RikiAnimatedStudyLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.maybeOf(context);
    final reduceMotion =
        (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);
    if (_reduceMotion == reduceMotion && _controller.isAnimating) return;
    _reduceMotion = reduceMotion;
    if (_reduceMotion) {
      _controller
        ..stop()
        ..value = 0.68;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel,
      liveRegion: true,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox.square(
            key: const ValueKey<String>('riki_animated_study_loader'),
            dimension: widget.size,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final progress = _controller.value;
                final pulse = _reduceMotion
                    ? 1.0
                    : 1 + math.sin(progress * math.pi * 2) * 0.018;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: CustomPaint(
                        painter: _StudySealPainter(progress: progress),
                      ),
                    ),
                    Transform.scale(scale: pulse, child: child),
                  ],
                );
              },
              child: Container(
                width: widget.size * 0.39,
                height: widget.size * 0.46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.brandBorder),
                  borderRadius: BorderRadius.circular(AppRadius.compact),
                  boxShadow: AppShadows.cardSoft,
                ),
                child: Text(
                  '文',
                  style: AppTypography.compactPageTitle.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StudySealPainter extends CustomPainter {
  const _StudySealPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.38;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final track = Paint()
      ..color = AppColors.brandSecondary.withValues(alpha: 0.42)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.shortestSide * 0.045;
    final stroke = Paint()
      ..color = AppColors.brandPrimary.withValues(alpha: 0.88)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = size.shortestSide * 0.052;

    canvas.drawArc(rect, -math.pi * 0.78, math.pi * 1.62, false, track);
    canvas.drawArc(
      rect,
      -math.pi * 0.78 + progress * math.pi * 2,
      math.pi * 0.48,
      false,
      stroke,
    );

    _drawPetal(
      canvas,
      center +
          Offset(
            radius * 0.78 + math.sin(progress * math.pi * 2) * 2,
            -radius * 0.72 + math.cos(progress * math.pi * 2) * 2,
          ),
      size.shortestSide * 0.045,
      progress * math.pi,
      AppColors.brandPrimary.withValues(alpha: 0.56),
    );
    _drawPetal(
      canvas,
      center +
          Offset(
            -radius * 0.88 + math.cos(progress * math.pi * 2) * 1.5,
            radius * 0.48 + math.sin(progress * math.pi * 2) * 2,
          ),
      size.shortestSide * 0.038,
      -progress * math.pi * 0.7,
      AppColors.brandSecondary.withValues(alpha: 0.78),
    );
  }

  void _drawPetal(
    Canvas canvas,
    Offset center,
    double radius,
    double rotation,
    Color color,
  ) {
    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..rotate(rotation);
    final path = Path()
      ..moveTo(0, -radius)
      ..quadraticBezierTo(radius, -radius * 0.15, 0, radius)
      ..quadraticBezierTo(-radius, -radius * 0.15, 0, -radius)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StudySealPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class RikiFullScreenLoader extends StatelessWidget {
  const RikiFullScreenLoader({
    required this.title,
    this.subtitle,
    this.header,
    this.semanticsLabel,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? header;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space6),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (header != null) ...[
                  header!,
                  const SizedBox(height: AppSpacing.space8),
                ],
                RikiAnimatedStudyLoader(
                  semanticsLabel: semanticsLabel ?? title,
                ),
                const SizedBox(height: AppSpacing.space5),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTypography.sectionTitle,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: AppSpacing.space2),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: AppTypography.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RikiInlineLoader extends StatefulWidget {
  const RikiInlineLoader({
    this.size = 18,
    this.color = AppColors.brandPrimary,
    this.semanticsLabel,
    super.key,
  });

  final double size;
  final Color color;
  final String? semanticsLabel;

  @override
  State<RikiInlineLoader> createState() => _RikiInlineLoaderState();
}

class _RikiInlineLoaderState extends State<RikiInlineLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1050),
  );
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.maybeOf(context);
    final reduceMotion =
        (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);
    _reduceMotion = reduceMotion;
    if (_reduceMotion) {
      _controller
        ..stop()
        ..value = 0.38;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel,
      liveRegion: true,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox(
            key: const ValueKey<String>('riki_inline_loader'),
            width: widget.size * 1.45,
            height: widget.size,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: _InlineDotsPainter(
                  progress: _controller.value,
                  color: widget.color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineDotsPainter extends CustomPainter {
  const _InlineDotsPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = size.height * 0.12;
    final spacing = size.width / 4;
    for (var index = 0; index < 3; index++) {
      final phase = (progress - index * 0.16) % 1.0;
      final wave = (math.sin(phase * math.pi * 2 - math.pi / 2) + 1) / 2;
      final dotRadius = radius * (0.72 + wave * 0.38);
      canvas.drawCircle(
        Offset(spacing * (index + 1), size.height / 2),
        dotRadius,
        Paint()..color = color.withValues(alpha: 0.5 + wave * 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(_InlineDotsPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}

/// Owns one shimmer controller for all [RikiSkeleton] descendants.
class RikiShimmer extends StatefulWidget {
  const RikiShimmer({required this.child, this.semanticsLabel, super.key});

  final Widget child;
  final String? semanticsLabel;

  @override
  State<RikiShimmer> createState() => _RikiShimmerState();
}

class _RikiShimmerState extends State<RikiShimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1450),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.maybeOf(context);
    final reduceMotion =
        (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);
    if (reduceMotion) {
      _controller
        ..stop()
        ..value = 0.42;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel,
      liveRegion: true,
      container: true,
      child: _RikiShimmerScope(animation: _controller, child: widget.child),
    );
  }
}

class _RikiShimmerScope extends InheritedWidget {
  const _RikiShimmerScope({required this.animation, required super.child});

  final Animation<double> animation;

  static Animation<double>? maybeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<_RikiShimmerScope>()
      ?.animation;

  @override
  bool updateShouldNotify(_RikiShimmerScope oldWidget) =>
      oldWidget.animation != animation;
}

class RikiSkeleton extends StatelessWidget {
  const RikiSkeleton({
    required this.height,
    this.width,
    this.borderRadius = AppRadius.compact,
    this.shape = BoxShape.rectangle,
    super.key,
  });

  final double height;
  final double? width;
  final double borderRadius;
  final BoxShape shape;

  @override
  Widget build(BuildContext context) {
    final animation =
        _RikiShimmerScope.maybeOf(context) ??
        const AlwaysStoppedAnimation<double>(0.42);
    return SizedBox(
      width: width,
      height: height,
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) {
          final position = animation.value * 3.2 - 1.6;
          return DecoratedBox(
            decoration: BoxDecoration(
              shape: shape,
              borderRadius: shape == BoxShape.circle
                  ? null
                  : BorderRadius.circular(borderRadius),
              gradient: LinearGradient(
                begin: Alignment(position - 1, 0),
                end: Alignment(position + 1, 0),
                colors: const [
                  AppColors.inputProcessing,
                  AppColors.surface,
                  AppColors.inputProcessing,
                ],
                stops: const [0.18, 0.5, 0.82],
              ),
            ),
          );
        },
      ),
    );
  }
}

class RikiSkeletonCard extends StatelessWidget {
  const RikiSkeletonCard({
    this.height = 132,
    this.leading = true,
    this.lineCount = 3,
    this.trailing = false,
    super.key,
  });

  final double height;
  final bool leading;
  final int lineCount;
  final bool trailing;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      boxShadow: const <BoxShadow>[],
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: SizedBox(
        height: height,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (leading) ...[
              const RikiSkeleton(width: 52, height: 52),
              const SizedBox(width: AppSpacing.space3),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FractionallySizedBox(
                    widthFactor: 0.62,
                    child: RikiSkeleton(height: 18),
                  ),
                  const SizedBox(height: 10),
                  for (var index = 0; index < lineCount; index++) ...[
                    FractionallySizedBox(
                      widthFactor: index.isEven ? 0.92 : 0.68,
                      child: const RikiSkeleton(height: 10),
                    ),
                    if (index < lineCount - 1) const SizedBox(height: 6),
                  ],
                  const Spacer(),
                  if (height >= 120) ...[
                    const SizedBox(height: AppSpacing.space2),
                    const RikiSkeleton(width: 76, height: 24),
                  ],
                ],
              ),
            ),
            if (trailing) ...[
              const SizedBox(width: AppSpacing.space3),
              const RikiSkeleton(width: 28, height: 28, shape: BoxShape.circle),
            ],
          ],
        ),
      ),
    );
  }
}

class RikiSectionSkeleton extends StatelessWidget {
  const RikiSectionSkeleton({
    this.itemCount = 3,
    this.cardHeight = 112,
    this.showSearch = true,
    this.showFilters = true,
    this.cardLeading = true,
    this.padding = const EdgeInsets.all(AppSpacing.space4),
    this.semanticsLabel,
    super.key,
  });

  final int itemCount;
  final double cardHeight;
  final bool showSearch;
  final bool showFilters;
  final bool cardLeading;
  final EdgeInsetsGeometry padding;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return RikiShimmer(
      semanticsLabel: semanticsLabel,
      child: ListView(
        padding: padding,
        children: [
          if (showSearch) ...[
            const RikiSkeleton(height: 48, borderRadius: AppRadius.input),
            const SizedBox(height: AppSpacing.space3),
          ],
          if (showFilters) ...[
            const Row(
              children: [
                RikiSkeleton(
                  width: 66,
                  height: 32,
                  borderRadius: AppRadius.pill,
                ),
                SizedBox(width: AppSpacing.space2),
                RikiSkeleton(
                  width: 58,
                  height: 32,
                  borderRadius: AppRadius.pill,
                ),
                SizedBox(width: AppSpacing.space2),
                RikiSkeleton(
                  width: 58,
                  height: 32,
                  borderRadius: AppRadius.pill,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.space4),
          ],
          for (var index = 0; index < itemCount; index++) ...[
            RikiSkeletonCard(
              height: cardHeight,
              leading: cardLeading,
              trailing: index.isEven,
            ),
            if (index < itemCount - 1)
              const SizedBox(height: AppSpacing.space3),
          ],
        ],
      ),
    );
  }
}
