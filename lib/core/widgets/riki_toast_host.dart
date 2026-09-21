import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';

class RikiToastHost extends ConsumerWidget {
  const RikiToastHost({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toasts = ref.watch(rikiToastServiceProvider);
    final topInset =
        MediaQuery.viewPaddingOf(context).top +
        kToolbarHeight +
        AppSpacing.space2;
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        Positioned(
          top: topInset,
          left: AppSpacing.space4,
          right: AppSpacing.space4,
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
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 170),
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
    if (_started) return;
    _started = true;
    if (_reduceMotion) {
      _controller.value = 1;
    } else {
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
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final visual = _ToastVisual.forType(widget.toast.type);
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final description = widget.toast.description;

    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.14),
          end: Offset.zero,
        ).animate(animation),
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.98, end: 1).animate(animation),
          child: Semantics(
            container: true,
            liveRegion: true,
            label: description == null
                ? widget.toast.title
                : '${widget.toast.title}. $description',
            child: Material(
              key: ValueKey<String>('riki_toast_${widget.toast.type.name}'),
              color: Colors.transparent,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.banner),
                  border: Border.all(
                    color: visual.accent.withValues(alpha: 0.28),
                  ),
                  boxShadow: AppShadows.cardSoft,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space4,
                    AppSpacing.space3,
                    AppSpacing.space2,
                    AppSpacing.space3,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: visual.background,
                        ),
                        child: Icon(
                          visual.icon,
                          key: ValueKey<String>(
                            'riki_toast_icon_${widget.toast.type.name}',
                          ),
                          size: 20,
                          color: visual.accent,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.toast.title,
                                style: AppTypography.cardTitle,
                              ),
                              if (description != null &&
                                  description.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.space1),
                                Text(
                                  description,
                                  style: AppTypography.bodySmall,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: context.l10n.close,
                        child: IconButton(
                          key: ValueKey<String>(
                            'riki_toast_close_${widget.toast.id}',
                          ),
                          visualDensity: VisualDensity.compact,
                          onPressed: _dismiss,
                          icon: const Icon(Icons.close, size: 18),
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
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

class _ToastVisual {
  const _ToastVisual({
    required this.accent,
    required this.background,
    required this.icon,
  });

  final Color accent;
  final Color background;
  final IconData icon;

  factory _ToastVisual.forType(RikiToastType type) => switch (type) {
    RikiToastType.success => const _ToastVisual(
      accent: AppColors.success,
      background: AppColors.successBackgroundSoft,
      icon: Icons.check_circle_outline_rounded,
    ),
    RikiToastType.error => const _ToastVisual(
      accent: AppColors.error,
      background: AppColors.errorBackground,
      icon: Icons.error_outline_rounded,
    ),
    RikiToastType.warning => const _ToastVisual(
      accent: AppColors.warning,
      background: AppColors.warningBackground,
      icon: Icons.warning_amber_rounded,
    ),
    RikiToastType.info => const _ToastVisual(
      accent: AppColors.brandPrimary,
      background: AppColors.brandTint,
      icon: Icons.info_outline_rounded,
    ),
  };
}
