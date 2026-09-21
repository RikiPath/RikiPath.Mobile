import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';

class RikiLanguageSwitcher extends ConsumerStatefulWidget {
  const RikiLanguageSwitcher({super.key});

  @override
  ConsumerState<RikiLanguageSwitcher> createState() =>
      _RikiLanguageSwitcherState();
}

class _RikiLanguageSwitcherState extends ConsumerState<RikiLanguageSwitcher>
    with SingleTickerProviderStateMixin {
  static const _popoverWidth = 188.0;

  final _layerLink = LayerLink();
  final _overlayController = OverlayPortalController();
  final _focusNode = FocusNode(debugLabel: 'Riki language switcher');
  late final AnimationController _animationController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
    reverseDuration: const Duration(milliseconds: 160),
  );
  late final Animation<double> _animation = CurvedAnimation(
    parent: _animationController,
    curve: Curves.easeOutCubic,
    reverseCurve: Curves.easeInCubic,
  );

  bool _isOpen = false;
  bool _reduceMotion = false;
  String? _pendingLanguageCode;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.of(context);
    _reduceMotion =
        mediaQuery.disableAnimations || mediaQuery.accessibleNavigation;
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _togglePopover() {
    if (_isOpen) {
      unawaited(_closePopover());
    } else {
      _openPopover();
    }
  }

  void _openPopover() {
    if (_isOpen) return;
    setState(() => _isOpen = true);
    _overlayController.show();
    _focusNode.requestFocus();
    if (_reduceMotion) {
      _animationController.value = 1;
    } else {
      _animationController.forward(from: 0);
    }
  }

  Future<void> _closePopover() async {
    if (!_isOpen) return;
    if (!_reduceMotion) await _animationController.reverse();
    if (!mounted) return;
    _overlayController.hide();
    setState(() {
      _isOpen = false;
      _pendingLanguageCode = null;
    });
  }

  Future<void> _selectLocale(Locale locale) async {
    final currentLocale = ref.read(localeControllerProvider);
    if (currentLocale.languageCode == locale.languageCode) {
      await _closePopover();
      return;
    }

    setState(() => _pendingLanguageCode = locale.languageCode);
    if (!_reduceMotion) {
      await Future<void>.delayed(const Duration(milliseconds: 70));
    }
    await _closePopover();
    if (!mounted) return;
    await ref.read(localeControllerProvider.notifier).changeLocale(locale);
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape &&
        _isOpen) {
      unawaited(_closePopover());
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeControllerProvider);
    final l10n = context.l10n;
    final languageCode = locale.languageCode == 'ja'
        ? l10n.languageCodeJapanese
        : l10n.languageCodeVietnamese;
    final transitionDuration = _reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 200);

    return PopScope(
      canPop: !_isOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isOpen) unawaited(_closePopover());
      },
      child: Focus(
        focusNode: _focusNode,
        onKeyEvent: _handleKeyEvent,
        child: OverlayPortal(
          controller: _overlayController,
          overlayChildBuilder: (overlayContext) => _buildOverlay(locale),
          child: CompositedTransformTarget(
            link: _layerLink,
            child: Semantics(
              button: true,
              expanded: _isOpen,
              label: l10n.languagePickerSemantics,
              child: Material(
                color: AppColors.surface,
                shape: const StadiumBorder(side: AppBorders.standard),
                elevation: 1,
                shadowColor: AppColors.brandShadow,
                child: InkWell(
                  key: const Key('language_switcher_button'),
                  onTap: _togglePopover,
                  canRequestFocus: true,
                  customBorder: const StadiumBorder(),
                  overlayColor: const WidgetStatePropertyAll<Color>(
                    AppColors.brandTint,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 44),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                        vertical: AppSpacing.space2,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.language,
                            size: 17,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 6),
                          AnimatedSwitcher(
                            duration: transitionDuration,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.08),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: Text(
                              languageCode,
                              key: ValueKey<String>(languageCode),
                              style: AppTypography.badgeText.copyWith(
                                color: AppColors.textBody,
                              ),
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
        ),
      ),
    );
  }

  Widget _buildOverlay(Locale currentLocale) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: GestureDetector(
            key: const Key('language_switcher_barrier'),
            behavior: HitTestBehavior.translucent,
            onTap: () => unawaited(_closePopover()),
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          width: _popoverWidth,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            targetAnchor: Alignment.bottomRight,
            followerAnchor: Alignment.topRight,
            offset: const Offset(0, AppSpacing.space2),
            child: FadeTransition(
              opacity: _animation,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.96, end: 1).animate(_animation),
                alignment: Alignment.topRight,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.025),
                    end: Offset.zero,
                  ).animate(_animation),
                  child: _LanguagePopover(
                    currentLanguageCode:
                        _pendingLanguageCode ?? currentLocale.languageCode,
                    onSelected: _selectLocale,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LanguagePopover extends StatelessWidget {
  const _LanguagePopover({
    required this.currentLanguageCode,
    required this.onSelected,
  });

  final String currentLanguageCode;
  final ValueChanged<Locale> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      key: const Key('language_switcher_popover'),
      color: AppColors.surface,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          boxShadow: AppShadows.cardSoft,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.space2),
          child: FocusTraversalGroup(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space2,
                    AppSpacing.space1,
                    AppSpacing.space2,
                    AppSpacing.space2,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.language,
                        size: 16,
                        color: AppColors.brandPrimary,
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Flexible(
                        child: Text(
                          l10n.languageMenuTitle,
                          style: AppTypography.badgeText.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.space1),
                _LanguageOption(
                  key: const Key('language_option_vi'),
                  label: l10n.languageVietnamese,
                  flagAsset: 'assets/flags/vi.svg',
                  selected: currentLanguageCode == 'vi',
                  onTap: () => onSelected(const Locale('vi')),
                ),
                _LanguageOption(
                  key: const Key('language_option_ja'),
                  label: l10n.languageJapanese,
                  flagAsset: 'assets/flags/ja.svg',
                  selected: currentLanguageCode == 'ja',
                  onTap: () => onSelected(const Locale('ja')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  const _LanguageOption({
    required this.label,
    required this.flagAsset,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final String flagAsset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.compact),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.compact),
          overlayColor: const WidgetStatePropertyAll<Color>(
            AppColors.brandTint,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.space2,
                vertical: 6,
              ),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 16,
                    clipBehavior: Clip.antiAlias,
                    foregroundDecoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(AppRadius.micro / 2),
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(AppRadius.micro / 2),
                    ),
                    child: SvgPicture.asset(
                      flagAsset,
                      key: ValueKey<String>(flagAsset),
                      fit: BoxFit.cover,
                      excludeFromSemantics: true,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space2),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodySmall.copyWith(
                        color: selected
                            ? AppColors.brandPrimary
                            : AppColors.textPrimary,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (selected) ...[
                    const SizedBox(width: AppSpacing.space2),
                    const Icon(
                      Icons.check,
                      key: Key('language_selected_indicator'),
                      size: 18,
                      color: AppColors.brandPrimary,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
