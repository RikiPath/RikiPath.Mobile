import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';

/// Opens the Sakura-styled modal bottom sheet to select the application language.
Future<Locale?> showSakuraLanguageBottomSheet(BuildContext context) {
  return showModalBottomSheet<Locale>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x66000000),
    builder: (context) => const SakuraLanguageBottomSheet(),
  );
}

class SakuraLanguageBottomSheet extends ConsumerStatefulWidget {
  const SakuraLanguageBottomSheet({super.key});

  @override
  ConsumerState<SakuraLanguageBottomSheet> createState() =>
      _SakuraLanguageBottomSheetState();
}

class _SakuraLanguageBottomSheetState
    extends ConsumerState<SakuraLanguageBottomSheet> {
  String? _pendingLanguageCode;

  Future<void> _handleSelect(Locale targetLocale) async {
    final currentCode = ref.read(localeControllerProvider).languageCode;
    setState(() => _pendingLanguageCode = targetLocale.languageCode);

    if (currentCode != targetLocale.languageCode) {
      await ref.read(localeControllerProvider.notifier).changeLocale(targetLocale);
    }

    if (!mounted) return;
    await Future<void>.delayed(const Duration(milliseconds: 120));
    if (!mounted) return;
    Navigator.of(context).pop(targetLocale);
  }

  @override
  Widget build(BuildContext context) {
    final activeLocale = ref.watch(localeControllerProvider);
    final selectedCode = _pendingLanguageCode ?? activeLocale.languageCode;
    final l10n = context.l10n;

    return Container(
      key: const ValueKey<String>('sakura_language_bottom_sheet'),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space5,
            AppSpacing.space3,
            AppSpacing.space5,
            AppSpacing.space6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  key: const ValueKey<String>('sakura_language_bottom_sheet_drag_handle'),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.space4),
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: AppColors.brandTint,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.language_rounded,
                      size: 20,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.appLanguageTitle,
                          style: AppTypography.sectionTitle.copyWith(
                            color: AppColors.learnerTextPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.appLanguageSubtitle,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.learnerTextSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space5),
              // Option 1: Vietnamese
              _LanguageOptionCard(
                key: const ValueKey<String>('language_bottom_sheet_option_vi'),
                flagAsset: 'assets/flags/vi.svg',
                nativeName: l10n.languageVietnamese,
                subLabel: l10n.vietnameseSubLabel,
                isSelected: selectedCode == 'vi',
                onTap: () => _handleSelect(const Locale('vi')),
              ),
              const SizedBox(height: AppSpacing.space3),
              // Option 2: Japanese
              _LanguageOptionCard(
                key: const ValueKey<String>('language_bottom_sheet_option_ja'),
                flagAsset: 'assets/flags/ja.svg',
                nativeName: l10n.languageJapanese,
                subLabel: l10n.japaneseSubLabel,
                isSelected: selectedCode == 'ja',
                onTap: () => _handleSelect(const Locale('ja')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageOptionCard extends StatelessWidget {
  const _LanguageOptionCard({
    required this.flagAsset,
    required this.nativeName,
    required this.subLabel,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String flagAsset;
  final String nativeName;
  final String subLabel;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      label: '$nativeName, $subLabel',
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandTint : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.brandPrimary : AppColors.border,
              width: isSelected ? 1.4 : 1,
            ),
            boxShadow: isSelected
                ? const [
                    BoxShadow(
                      color: Color(0x1AE05A7A),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : AppShadows.cardSoft,
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            overlayColor: const WidgetStatePropertyAll<Color>(
              AppColors.brandTint,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 56),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space4,
                  vertical: AppSpacing.space3,
                ),
                child: Row(
                  children: [
                    // Flag asset with clean rounded border
                    Container(
                      width: 32,
                      height: 22,
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: AppColors.border,
                          width: 0.6,
                        ),
                      ),
                      child: SvgPicture.asset(
                        flagAsset,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space4),
                    // Language labels
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            nativeName,
                            style: AppTypography.cardTitle.copyWith(
                              color: isSelected
                                  ? AppColors.brandPrimary
                                  : AppColors.learnerTextPrimary,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subLabel,
                            style: AppTypography.metadata.copyWith(
                              color: AppColors.learnerTextSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    // Selection indicator (Radio / Checkmark)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected
                            ? AppColors.brandPrimary
                            : Colors.transparent,
                        border: Border.all(
                          color: isSelected
                              ? AppColors.brandPrimary
                              : AppColors.border,
                          width: isSelected ? 1 : 1.5,
                        ),
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check_rounded,
                              size: 15,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
