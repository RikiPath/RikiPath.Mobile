import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_learner_header.dart';
import 'package:rikipath_mobile/core/widgets/sakura_glass_notification.dart';

/// Shared Sakura Glass notification overlay host for both Learner and Mentor
/// experiences.
class RikiToastHost extends ConsumerWidget {
  const RikiToastHost({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toasts = ref.watch(rikiToastServiceProvider);
    final viewPadding = MediaQuery.viewPaddingOf(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;
    // Clear the 64dp Sakura header / 56dp AppBar with breathing space below
    // header controls (bell, calendar, streak badge, back button).
    final topInset =
        viewPadding.top + RikiLearnerHeader.height + AppSpacing.space2;
    final horizontalLeft = math.max(viewPadding.left, AppSpacing.space4);
    final horizontalRight = math.max(viewPadding.right, AppSpacing.space4);

    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (toasts.isNotEmpty && toasts.first.type == RikiToastType.celebration)
          Positioned.fill(
            child: IgnorePointer(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalLeft,
                  viewPadding.top + AppSpacing.space4,
                  horizontalRight,
                  math.max(viewPadding.bottom, AppSpacing.space4) +
                      keyboardInset,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 340),
                    child: _RikiToastCard(
                      key: ValueKey<int>(toasts.first.id),
                      toast: toasts.first,
                      onDismiss: () => ref
                          .read(rikiToastServiceProvider.notifier)
                          .dismiss(toasts.first.id),
                    ),
                  ),
                ),
              ),
            ),
          )
        else if (toasts.isNotEmpty)
          Positioned(
            top: topInset,
            left: horizontalLeft,
            right: horizontalRight,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (final toast in toasts) ...[
                      _RikiToastCard(
                        key: ValueKey<int>(toast.id),
                        toast: toast,
                        onDismiss: () => ref
                            .read(rikiToastServiceProvider.notifier)
                            .dismiss(toast.id),
                      ),
                      if (toast != toasts.last)
                        const SizedBox(height: AppSpacing.space2),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _RikiToastCard extends StatefulWidget {
  const _RikiToastCard({
    required this.toast,
    required this.onDismiss,
    super.key,
  });

  final RikiToastData toast;
  final VoidCallback onDismiss;

  @override
  State<_RikiToastCard> createState() => _RikiToastCardState();
}

class _RikiToastCardState extends State<_RikiToastCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    reverseDuration: const Duration(milliseconds: 220),
  );
  late final CurvedAnimation _animation = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );
  Timer? _dismissTimer;
  bool _reduceMotion = false;
  bool _started = false;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(widget.toast.duration, _dismiss);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.maybeOf(context);
    _reduceMotion =
        (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);
    if (_reduceMotion) {
      _controller.value = 1;
      _started = true;
      return;
    }
    if (!_started) {
      _started = true;
      unawaited(_controller.forward());
    }
  }

  Future<void> _dismiss() async {
    if (_dismissing || !mounted) return;
    _dismissing = true;
    _dismissTimer?.cancel();
    if (!_reduceMotion) await _controller.reverse();
    if (mounted) widget.onDismiss();
  }

  @override
  void dispose() {
    _dismissTimer?.cancel();
    _animation.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final description = widget.toast.description;
    final hasDescription = description != null && description.isNotEmpty;
    final semanticsLabel = hasDescription
        ? '${widget.toast.title}. $description'
        : widget.toast.title;
    final cardKey = ValueKey<String>('riki_toast_${widget.toast.type.name}');
    final iconKey = ValueKey<String>(
      'riki_toast_icon_${widget.toast.type.name}',
    );
    final closeKey = ValueKey<String>('riki_toast_close_${widget.toast.id}');

    if (widget.toast.type == RikiToastType.celebration) {
      return FadeTransition(
        opacity: _animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, -0.06),
            end: Offset.zero,
          ).animate(_animation),
          child: Semantics(
            container: true,
            liveRegion: true,
            label: semanticsLabel,
            child: SakuraGlassNotification(
              type: widget.toast.type,
              title: widget.toast.title,
              description: description,
              showCloseButton: false,
              centered: true,
              borderRadius:
                  SakuraGlassNotificationTokens.celebrationBorderRadius,
              cardKey: cardKey,
              iconKey: iconKey,
            ),
          ),
        ),
      );
    }

    return FadeTransition(
      opacity: _animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.10),
          end: Offset.zero,
        ).animate(_animation),
        child: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragEnd: (details) {
            if ((details.primaryVelocity ?? 0) < -160) {
              unawaited(_dismiss());
            }
          },
          child: Semantics(
            container: true,
            liveRegion: true,
            label: semanticsLabel,
            child: SakuraGlassNotification(
              type: widget.toast.type,
              title: widget.toast.title,
              description: description,
              onClose: _dismiss,
              cardKey: cardKey,
              iconKey: iconKey,
              closeButtonKey: closeKey,
            ),
          ),
        ),
      ),
    );
  }
}
