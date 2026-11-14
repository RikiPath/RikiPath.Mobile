import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_buttons.dart';
import 'package:rikipath_mobile/core/widgets/riki_loading.dart';

/// RikiPath's unified Sakura loading system.
///
/// Usage rules:
/// * Blocking operation (login, logout, submit, profile/goal save, booking,
///   payment, roadmap generation, exam submission): [AppLoadingOverlay] (or its
///   compatibility alias [SakuraLoadingOverlay]), [SakuraLoadingDialog], or
///   imperatively [showAppLoadingOverlay] / [runWithAppLoadingOverlay].
/// * Button action: [SakuraLoadingButton] / `RikiPrimaryButton(isLoading:)`.
/// * Page or list content: [SakuraSkeleton] / [SakuraSectionSkeleton].
/// * Small inline or section wait: [SakuraLoadingIndicator].

/// Sakura palette used by the bloom. Kept private to the loading system so
/// the motif stays consistent everywhere it appears.
abstract final class _SakuraBloomColors {
  static const petalDeep = Color(0xFFE5577F);
  static const petalMid = Color(0xFFF08AA6);
  static const petalLight = Color(0xFFFFD9E3);
  static const centerCream = Color(0xFFFFEDB8);
  static const stamen = Color(0xFFF2B84B);
}

abstract final class _OverlayGlassTokens {
  static const Color scrim = Color(0x6B1C1420);
  static const double panelRadius = 32;
  static const double panelMinWidth = 260;
  static const double panelMaxWidth = 320;
  static const Color titleColor = Color(0xFF281F25);
  static const Duration fadeInDuration = Duration(milliseconds: 210);
  static const Duration fadeOutDuration = Duration(milliseconds: 190);
}

bool _prefersReducedMotion(BuildContext context) {
  final media = MediaQuery.maybeOf(context);
  return (media?.disableAnimations ?? false) ||
      (media?.accessibleNavigation ?? false);
}

String _cleanOverlayCopy(String text) {
  return text.replaceFirst(RegExp(r'(?:\.{2,}|…)+\s*$'), '').trim();
}

/// Five balanced Sakura petals that breathe open and closed in sequence.
class SakuraLoadingIndicator extends StatefulWidget {
  const SakuraLoadingIndicator({
    this.size = 56,
    this.semanticsLabel,
    super.key,
  });

  final double size;
  final String? semanticsLabel;

  @override
  State<SakuraLoadingIndicator> createState() => _SakuraLoadingIndicatorState();
}

class _SakuraLoadingIndicatorState extends State<SakuraLoadingIndicator>
    with SingleTickerProviderStateMixin {
  // Calm 1.6s bloom cycle so the blossom breathes smoothly without reading like
  // a rapid spinner.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = _prefersReducedMotion(context);
    if (_reduceMotion) {
      _controller.stop();
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
      liveRegion: widget.semanticsLabel != null,
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox.square(
            key: const ValueKey<String>('sakura_loading_indicator'),
            dimension: widget.size,
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                painter: SakuraBloomPainter(
                  progress: _controller.value,
                  isStatic: _reduceMotion,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the flat / 2.5D Sakura bloom. [progress] is a looping 0..1 value.
class SakuraBloomPainter extends CustomPainter {
  const SakuraBloomPainter({required this.progress, this.isStatic = false});

  final double progress;
  final bool isStatic;

  static const _petalCount = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final unit = size.shortestSide;
    // Gentle breathing between 0.95 and 1.03 without orbiting or backdrop halo.
    final breath = isStatic
        ? 1.0
        : 0.99 + 0.04 * math.sin(progress * math.pi * 2);

    canvas
      ..save()
      ..translate(center.dx, center.dy)
      ..scale(breath);

    final baseLength = unit * 0.44;
    for (var index = 0; index < _petalCount; index++) {
      // Each petal peaks a fifth of a cycle after the previous one.
      final phase = (progress - index / _petalCount) % 1.0;
      final wave = isStatic
          ? 1.0
          : (math.sin(phase * math.pi * 2 - math.pi / 2) + 1) / 2;
      final length = baseLength * (0.92 + 0.08 * wave);
      final opacity = 0.70 + 0.30 * wave;
      canvas
        ..save()
        ..rotate(index * math.pi * 2 / _petalCount);
      _drawPetal(canvas, length, opacity, index.isEven);
      canvas.restore();
    }

    // Cream-yellow centre with five tiny stamens.
    final centerRadius = unit * 0.11;
    canvas.drawCircle(
      Offset.zero,
      centerRadius,
      Paint()..color = _SakuraBloomColors.centerCream,
    );
    final stamenPaint = Paint()..color = _SakuraBloomColors.stamen;
    for (var index = 0; index < _petalCount; index++) {
      final angle = -math.pi / 2 + index * math.pi * 2 / _petalCount;
      canvas.drawCircle(
        Offset(math.cos(angle), math.sin(angle)) * centerRadius * 0.55,
        unit * 0.022,
        stamenPaint,
      );
    }
    canvas.restore();
  }

  void _drawPetal(Canvas canvas, double length, double opacity, bool deep) {
    final width = length * 0.64;
    final path = _notchedPetalPath(width: width, length: length);

    // Soft 2.5D depth: a faint shadow, then a light-to-deep gradient.
    canvas.drawPath(
      path.shift(Offset(0, length * 0.04)),
      Paint()
        ..color = _SakuraBloomColors.petalDeep.withValues(alpha: 0.12 * opacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, length * 0.06),
    );
    final outer = deep
        ? _SakuraBloomColors.petalDeep
        : _SakuraBloomColors.petalMid;
    canvas.drawPath(
      path,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: <Color>[
            _SakuraBloomColors.petalLight.withValues(alpha: opacity),
            outer.withValues(alpha: opacity),
          ],
        ).createShader(Rect.fromLTWH(-width, -length, width * 2, length)),
    );
  }

  Path _notchedPetalPath({required double width, required double length}) {
    // Petal points upwards from the centre with the characteristic notch.
    return Path()
      ..moveTo(0, 0)
      ..cubicTo(
        -width * 0.95,
        -length * 0.22,
        -width * 0.78,
        -length * 0.96,
        -width * 0.24,
        -length,
      )
      ..quadraticBezierTo(-width * 0.08, -length * 1.01, 0, -length * 0.86)
      ..quadraticBezierTo(width * 0.08, -length * 1.01, width * 0.24, -length)
      ..cubicTo(
        width * 0.78,
        -length * 0.96,
        width * 0.95,
        -length * 0.22,
        0,
        0,
      )
      ..close();
  }

  @override
  bool shouldRepaint(SakuraBloomPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.isStatic != isStatic;
}

/// Three dots that hop in sequence; kept for inline button loading states.
class SakuraBouncingDots extends StatefulWidget {
  const SakuraBouncingDots({
    this.color = AppColors.brandPrimary,
    this.dotSize = 5,
    super.key,
  });

  final Color color;
  final double dotSize;

  @override
  State<SakuraBouncingDots> createState() => _SakuraBouncingDotsState();
}

class _SakuraBouncingDotsState extends State<SakuraBouncingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  );
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = _prefersReducedMotion(context);
    if (_reduceMotion) {
      _controller.stop();
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
    final dot = widget.dotSize;
    return ExcludeSemantics(
      child: SizedBox(
        key: const ValueKey<String>('sakura_bouncing_dots'),
        width: dot * 5,
        height: dot * 2.6,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (var index = 0; index < 3; index++)
                Transform.translate(
                  offset: Offset(
                    0,
                    _reduceMotion
                        ? 0
                        : -dot *
                              1.4 *
                              sakuraDotBounce(_controller.value, index),
                  ),
                  child: Container(
                    width: dot,
                    height: dot,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hop height (0..1) of dot [index] at loop [progress]; each dot hops once per
/// cycle, then rests so the motion reads as a gentle wave.
double sakuraDotBounce(double progress, int index) {
  final phase = (progress - index * 0.16) % 1.0;
  if (phase > 0.5) return 0;
  return math.sin(phase * 2 * math.pi).clamp(0.0, 1.0);
}

/// Compatibility alias so existing [SakuraLoadingOverlay] call sites share
/// [AppLoadingOverlay].
typedef SakuraLoadingOverlay = AppLoadingOverlay;

/// Shared blocking fullscreen Sakura loading overlay.
class AppLoadingOverlay extends StatefulWidget {
  const AppLoadingOverlay({
    required this.visible,
    required this.title,
    this.subtitle,
    this.blurBackground = true,
    super.key,
  });

  final bool visible;
  final String title;
  final String? subtitle;
  final bool blurBackground;

  @override
  State<AppLoadingOverlay> createState() => _AppLoadingOverlayState();
}

class _AppLoadingOverlayState extends State<AppLoadingOverlay> {
  bool _rendered = false;

  @override
  void initState() {
    super.initState();
    _rendered = widget.visible;
  }

  @override
  void didUpdateWidget(covariant AppLoadingOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible) {
      _rendered = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.visible,
      child: !_rendered && !widget.visible
          ? const SizedBox.shrink()
          : IgnorePointer(
              ignoring: !widget.visible,
              child: _SakuraBlockingOverlayShell(
                visible: widget.visible,
                title: widget.title,
                subtitle: widget.subtitle,
                blurBackground: widget.blurBackground,
                onDismissed: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && !widget.visible && _rendered) {
                      setState(() => _rendered = false);
                    }
                  });
                },
              ),
            ),
    );
  }
}

/// Reusable Sakura loading card for route dialogs.
class SakuraLoadingDialog extends StatelessWidget {
  const SakuraLoadingDialog({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return PopScope(
      canPop: false,
      child: Material(
        type: MaterialType.transparency,
        child: Padding(
          padding: EdgeInsets.only(bottom: keyboard),
          child: Center(child: _SakuraLoadingContent(title: title)),
        ),
      ),
    );
  }
}

/// Handle returned by [showAppLoadingOverlay] to update copy or dismiss the
/// blocking overlay after an imperative async workflow finishes.
class AppLoadingHandle {
  AppLoadingHandle._(this._onUpdate, this._onDismiss);

  final void Function({String? title, String? subtitle}) _onUpdate;
  final Future<void> Function() _onDismiss;
  bool _dismissed = false;

  void update({String? title, String? subtitle}) {
    if (_dismissed) return;
    _onUpdate(title: title, subtitle: subtitle);
  }

  Future<void> dismiss() {
    if (_dismissed) return Future<void>.value();
    _dismissed = true;
    return _onDismiss();
  }
}

/// Imperatively mounts a fullscreen blocking [AppLoadingOverlay] onto the root
/// [Overlay]. Safe across navigation and redirects (does not pop routes).
AppLoadingHandle showAppLoadingOverlay(
  BuildContext context, {
  required String title,
  String? subtitle,
  bool blurBackground = true,
}) {
  if (!context.mounted) {
    return AppLoadingHandle._(
      ({String? title, String? subtitle}) {},
      () async {},
    );
  }
  final overlay = Overlay.maybeOf(context, rootOverlay: true);
  if (overlay == null) {
    return AppLoadingHandle._(
      ({String? title, String? subtitle}) {},
      () async {},
    );
  }

  final shellKey = GlobalKey<_SakuraBlockingOverlayShellState>();
  var currentTitle = title;
  var currentSubtitle = subtitle;
  var visible = true;
  var removed = false;
  late final OverlayEntry entry;

  void removeEntryOnce() {
    if (removed) return;
    removed = true;
    // Remove even if `entry.mounted` is still false (before the first frame
    // builds `_entries`), otherwise `Overlay` mounts a stale visible entry on
    // the next frame and never dismisses it.
    if (overlay.mounted) {
      entry.remove();
    }
  }

  entry = OverlayEntry(
    builder: (_) => PopScope(
      canPop: false,
      child: _SakuraBlockingOverlayShell(
        key: shellKey,
        visible: visible,
        title: currentTitle,
        subtitle: currentSubtitle,
        blurBackground: blurBackground,
        onDismissed: removeEntryOnce,
      ),
    ),
  );

  overlay.insert(entry);
  final dismissCompleter = Completer<void>();

  return AppLoadingHandle._(
    ({String? title, String? subtitle}) {
      if (removed) return;
      currentTitle = title ?? currentTitle;
      currentSubtitle = subtitle;
      if (entry.mounted) {
        entry.markNeedsBuild();
      }
    },
    () async {
      if (removed) {
        if (!dismissCompleter.isCompleted) dismissCompleter.complete();
        return;
      }
      visible = false;
      final state = shellKey.currentState;
      if (state == null || !entry.mounted) {
        removeEntryOnce();
        if (!dismissCompleter.isCompleted) dismissCompleter.complete();
        return;
      }
      entry.markNeedsBuild();
      state.whenDismissed().whenComplete(() {
        removeEntryOnce();
        if (!dismissCompleter.isCompleted) dismissCompleter.complete();
      });
      await dismissCompleter.future;
    },
  );
}

/// Runs [action] while displaying a fullscreen blocking [AppLoadingOverlay] and
/// guarantees dismissal even when [action] throws or navigates away.
Future<T> runWithAppLoadingOverlay<T>(
  BuildContext context, {
  required String title,
  String? subtitle,
  bool blurBackground = true,
  required Future<T> Function() action,
}) async {
  final handle = showAppLoadingOverlay(
    context,
    title: title,
    subtitle: subtitle,
    blurBackground: blurBackground,
  );
  try {
    return await action();
  } finally {
    unawaited(handle.dismiss());
  }
}

class _SakuraBlockingOverlayShell extends StatefulWidget {
  const _SakuraBlockingOverlayShell({
    required this.visible,
    required this.title,
    required this.subtitle,
    required this.blurBackground,
    this.onDismissed,
    super.key,
  });

  final bool visible;
  final String title;
  final String? subtitle;
  final bool blurBackground;
  final VoidCallback? onDismissed;

  @override
  State<_SakuraBlockingOverlayShell> createState() =>
      _SakuraBlockingOverlayShellState();
}

class _SakuraBlockingOverlayShellState
    extends State<_SakuraBlockingOverlayShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _OverlayGlassTokens.fadeInDuration,
    reverseDuration: _OverlayGlassTokens.fadeOutDuration,
  );
  late final CurvedAnimation _fadeCurve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  late final Animation<double> _panelScale = Tween<double>(
    begin: 0.96,
    end: 1.0,
  ).animate(_fadeCurve);
  bool _reduceMotion = false;
  Completer<void>? _dismissCompleter;

  Future<void> whenDismissed() {
    if (!widget.visible && _controller.isDismissed) {
      return Future<void>.value();
    }
    return (_dismissCompleter ??= Completer<void>()).future;
  }

  @override
  void initState() {
    super.initState();
    _controller.addStatusListener(_handleStatus);
  }

  void _completeDismiss() {
    if (_dismissCompleter != null && !_dismissCompleter!.isCompleted) {
      _dismissCompleter!.complete();
    }
    widget.onDismissed?.call();
  }

  void _handleStatus(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && !widget.visible) {
      // Defer if reverse() finished synchronously inside build/didUpdateWidget
      // (e.g., value was still 0.0 when dismissing).
      if (SchedulerBinding.instance.schedulerPhase ==
          SchedulerPhase.persistentCallbacks) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !widget.visible && _controller.isDismissed) {
            _completeDismiss();
          }
        });
        return;
      }
      _completeDismiss();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = _prefersReducedMotion(context);
    _syncAnimation(immediateIfReduced: true);
  }

  @override
  void didUpdateWidget(covariant _SakuraBlockingOverlayShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visible != widget.visible) {
      _syncAnimation(immediateIfReduced: true);
    }
  }

  void _syncAnimation({required bool immediateIfReduced}) {
    if (_reduceMotion && immediateIfReduced) {
      _controller.value = widget.visible ? 1.0 : 0.0;
      if (!widget.visible) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && !widget.visible) {
            _handleStatus(AnimationStatus.dismissed);
          }
        });
      }
      return;
    }
    if (widget.visible) {
      unawaited(_controller.forward());
    } else {
      unawaited(_controller.reverse());
    }
  }

  @override
  void dispose() {
    if (_dismissCompleter != null && !_dismissCompleter!.isCompleted) {
      _dismissCompleter!.complete();
    }
    _controller.removeStatusListener(_handleStatus);
    _fadeCurve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final safeView = MediaQuery.viewPaddingOf(context);
    final cleanTitle = _cleanOverlayCopy(widget.title);

    // Material supplies a real text theme so labels never fall back to the
    // debug yellow underline style even outside Scaffold/MaterialApp.
    return Material(
      type: MaterialType.transparency,
      child: Semantics(
        key: const ValueKey<String>('sakura_loading_overlay'),
        container: true,
        liveRegion: true,
        label: cleanTitle,
        child: FadeTransition(
          opacity: _fadeCurve,
          child: AbsorbPointer(
            absorbing: true,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  key: const ValueKey<String>('app_loading_scrim'),
                  child: const ModalBarrier(
                    dismissible: false,
                    color: _OverlayGlassTokens.scrim,
                  ),
                ),
                Positioned.fill(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      math.max(safeView.left, AppSpacing.space6),
                      math.max(safeView.top, AppSpacing.space4),
                      math.max(safeView.right, AppSpacing.space6),
                      math.max(safeView.bottom, AppSpacing.space4) + keyboard,
                    ),
                    child: Center(
                      child: ScaleTransition(
                        scale: _panelScale,
                        child: ExcludeSemantics(
                          child: _SakuraLoadingContent(title: cleanTitle),
                        ),
                      ),
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

class _SakuraLoadingContent extends StatelessWidget {
  const _SakuraLoadingContent({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final cleanTitle = _cleanOverlayCopy(title);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxAllowedWidth = constraints.maxWidth.isFinite
            ? math.min(_OverlayGlassTokens.panelMaxWidth, constraints.maxWidth)
            : _OverlayGlassTokens.panelMaxWidth;
        final minWidth = math.min(
          _OverlayGlassTokens.panelMinWidth,
          maxAllowedWidth,
        );
        return ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: minWidth,
            maxWidth: maxAllowedWidth,
          ),
          child: DecoratedBox(
            key: const ValueKey<String>('app_loading_glass_panel'),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                _OverlayGlassTokens.panelRadius,
              ),
              boxShadow: const <BoxShadow>[
                BoxShadow(
                  color: Color(0x281B121F),
                  blurRadius: 28,
                  offset: Offset(0, 12),
                ),
                BoxShadow(
                  color: Color(0x1EE05A7A),
                  blurRadius: 18,
                  spreadRadius: -2,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                _OverlayGlassTokens.panelRadius,
              ),
              child: DecoratedBox(
                key: const ValueKey<String>('app_loading_glass_surface'),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    _OverlayGlassTokens.panelRadius,
                  ),
                ),
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.space6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SakuraLoadingIndicator(size: 68),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              cleanTitle,
                              textAlign: TextAlign.center,
                              style: AppTypography.sectionTitle.copyWith(
                                color: _OverlayGlassTokens.titleColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 16.5,
                                height: 1.32,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          const SakuraBouncingDots(),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// In-place data loading; it does not block the rest of the application.
class SakuraSectionLoading extends StatelessWidget {
  const SakuraSectionLoading({required this.title, this.size = 48, super.key});

  final String title;
  final double size;

  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      container: true,
      liveRegion: true,
      label: title,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SakuraLoadingIndicator(size: size),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const SakuraBouncingDots(),
          ],
        ),
      ),
    ),
  );
}

/// Primary action with a compact in-button loading state (bouncing dots and
/// label). Disables itself while loading to block double submission.
class SakuraLoadingButton extends StatelessWidget {
  const SakuraLoadingButton({
    required this.label,
    required this.isLoading,
    required this.onPressed,
    this.loadingLabel,
    this.leadingIcon,
    this.trailingIcon,
    super.key,
  });

  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;
  final String? loadingLabel;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return RikiPrimaryButton(
      label: label,
      loadingLabel: loadingLabel,
      isLoading: isLoading,
      leadingIcon: leadingIcon,
      trailingIcon: trailingIcon,
      onPressed: onPressed,
    );
  }
}

/// Content placeholders share the existing shimmer implementation so there is
/// exactly one skeleton system in the app.
typedef SakuraSkeleton = RikiSkeleton;
typedef SakuraSkeletonCard = RikiSkeletonCard;
typedef SakuraSectionSkeleton = RikiSectionSkeleton;
