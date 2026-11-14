import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/sakura_colorful_icon.dart';
import 'package:rikipath_mobile/core/widgets/sakura_motifs.dart';
import 'package:rikipath_mobile/features/onboarding/domain/jlpt_exam_session.dart';

/// Sakura Premium learning plan summary preview shown on Onboarding Step 4.
///
/// Reflects the learner's live draft selections across Steps 1–4 without
/// persisting anything until final confirmation.
class SakuraLearningPlanPreview extends StatelessWidget {
  const SakuraLearningPlanPreview({
    required this.currentLevelCode,
    required this.targetLevelCode,
    required this.dailyMinutes,
    required this.hasCertificate,
    required this.certifiedLevelCode,
    required this.targetExamDate,
    required this.examSession,
    super.key,
  });

  final String? currentLevelCode;
  final String? targetLevelCode;
  final int? dailyMinutes;
  final bool hasCertificate;
  final String? certifiedLevelCode;
  final DateTime? targetExamDate;
  final JlptExamSession? examSession;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final media = MediaQuery.maybeOf(context);
    final reduceMotion =
        (media?.disableAnimations ?? false) ||
        (media?.accessibleNavigation ?? false);

    final targetDisplay = targetLevelCode ?? l10n.notConfigured;
    final currentValue = currentLevelCode != null
        ? 'JLPT $currentLevelCode'
        : l10n.onboardingPlanCertificateUnspecified;
    final targetValue = targetLevelCode != null
        ? 'JLPT $targetLevelCode'
        : l10n.notConfigured;
    final dailyValue = dailyMinutes != null && dailyMinutes! > 0
        ? l10n.onboardingPlanDailyMinutesValue(dailyMinutes!)
        : l10n.notConfigured;

    final String certificateValue;
    final bool hasDeclaredCertificateLevel =
        hasCertificate && certifiedLevelCode != null;
    if (hasDeclaredCertificateLevel) {
      certificateValue = 'JLPT $certifiedLevelCode';
    } else if (hasCertificate) {
      // Checkbox marked without a chosen level: avoid claiming "Chưa có".
      certificateValue = l10n.onboardingPlanCertificateUnspecified;
    } else {
      certificateValue = l10n.onboardingPlanCertificateNone;
    }

    final tiles = <_PlanTileData>[
      _PlanTileData(
        key: const ValueKey<String>('onboarding_plan_tile_current_level'),
        icon: Icons.menu_book_rounded,
        iconBackground: AppColors.pastelBlueBg,
        iconForeground: AppColors.pastelBlueFg,
        label: l10n.onboardingPlanCurrentLevelLabel,
        value: currentValue,
      ),
      _PlanTileData(
        key: const ValueKey<String>('onboarding_plan_tile_target_level'),
        icon: Icons.flag_rounded,
        iconBackground: AppColors.brandTint,
        iconForeground: AppColors.brandPrimary,
        label: l10n.onboardingPlanTargetLabel,
        value: targetValue,
        highlightValue: true,
      ),
      _PlanTileData(
        key: const ValueKey<String>('onboarding_plan_tile_study_time'),
        icon: Icons.schedule_rounded,
        iconBackground: AppColors.featureAmberBackground,
        iconForeground: AppColors.skillGrammar,
        label: l10n.onboardingPlanDailyStudyLabel,
        value: dailyValue,
      ),
      _PlanTileData(
        key: const ValueKey<String>('onboarding_plan_tile_certificate'),
        icon: Icons.workspace_premium_rounded,
        iconBackground: hasDeclaredCertificateLevel
            ? AppColors.pastelGreenBg
            : AppColors.pastelPurpleBg,
        iconForeground: hasDeclaredCertificateLevel
            ? AppColors.pastelGreenFg
            : AppColors.pastelPurpleFg,
        label: l10n.onboardingPlanCertificateLabel,
        value: certificateValue,
      ),
    ];

    return Semantics(
      container: true,
      label: l10n.onboardingPlanHeroTitle(targetDisplay),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: reduceMotion ? 1.0 : 0.0, end: 1.0),
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
        builder: (context, progress, child) {
          return Opacity(
            opacity: progress.clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(0, 10 * (1 - progress)),
              child: child,
            ),
          );
        },
        child: Container(
          key: const ValueKey<String>('onboarding_learning_plan_preview'),
          decoration: BoxDecoration(
            color: AppColors.cardWarmWhite,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.borderSubtlePink),
            boxShadow: AppShadows.sakuraCard,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(21),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _PlanHeroBanner(
                  eyebrow: l10n.onboardingPlanPreviewEyebrow,
                  title: l10n.onboardingPlanHeroTitle(targetDisplay),
                  subtitle: l10n.onboardingPlanHeroSubtitle,
                  reduceMotion: reduceMotion,
                ),
                Divider(
                  height: 1,
                  thickness: 0.75,
                  color: AppColors.borderSubtlePink.withValues(alpha: 0.7),
                ),
                Container(
                  color: AppColors.cardWarmPorcelain,
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PlanInfoGrid(tiles: tiles),
                      const SizedBox(height: 12),
                      _PlanExamSummaryCard(
                        targetExamDate: targetExamDate,
                        examSession: examSession,
                        reduceMotion: reduceMotion,
                      ),
                    ],
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

class _PlanHeroBanner extends StatelessWidget {
  const _PlanHeroBanner({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.reduceMotion,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            Color(0xFFFFF0F4),
            Color(0xFFFFF7F9),
            Color(0xFFFFFFFF),
          ],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(
            top: 0,
            right: 0,
            child: SakuraDecorativeCorner(width: 98, height: 78, opacity: 0.22),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow,
                        style: AppTypography.badgeText.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.85,
                          color: AppColors.sakura700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedSwitcher(
                        duration: reduceMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 200),
                        child: Text(
                          title,
                          key: ValueKey<String>(title),
                          style: AppTypography.compactPageTitle.copyWith(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            height: 1.24,
                            letterSpacing: -0.4,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(
                    begin: reduceMotion ? 1.0 : 0.95,
                    end: 1.0,
                  ),
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 320),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) =>
                      Transform.scale(scale: scale, child: child),
                  child: Container(
                    width: 56,
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: <Color>[Color(0xFFFFE3EC), Color(0xFFFFF4F7)],
                      ),
                      border: Border.all(
                        color: AppColors.sakura200.withValues(alpha: 0.85),
                      ),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: AppColors.brandShadowSoft,
                          offset: Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: const SakuraColorfulIcon(
                      type: SakuraColorfulIconType.learningGoal,
                      size: 32,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanTileData {
  const _PlanTileData({
    required this.key,
    required this.icon,
    required this.iconBackground,
    required this.iconForeground,
    required this.label,
    required this.value,
    this.highlightValue = false,
  });

  final Key key;
  final IconData icon;
  final Color iconBackground;
  final Color iconForeground;
  final String label;
  final String value;
  final bool highlightValue;
}

class _PlanInfoGrid extends StatelessWidget {
  const _PlanInfoGrid({required this.tiles});

  final List<_PlanTileData> tiles;

  @override
  Widget build(BuildContext context) {
    final textScaler = MediaQuery.textScalerOf(context);
    final scaledBody = textScaler.scale(14);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useSingleColumn = constraints.maxWidth < 260 || scaledBody >= 24;
        if (useSingleColumn) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < tiles.length; i++) ...[
                _PlanInfoTile(data: tiles[i]),
                if (i < tiles.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }

        return Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _PlanInfoTile(data: tiles[0])),
                  const SizedBox(width: 10),
                  Expanded(child: _PlanInfoTile(data: tiles[1])),
                ],
              ),
            ),
            const SizedBox(height: 10),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _PlanInfoTile(data: tiles[2])),
                  const SizedBox(width: 10),
                  Expanded(child: _PlanInfoTile(data: tiles[3])),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PlanInfoTile extends StatelessWidget {
  const _PlanInfoTile({required this.data});

  final _PlanTileData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: data.key,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.cardWarmWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEE8EA)),
        boxShadow: AppShadows.cardSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: data.iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(data.icon, size: 22, color: data.iconForeground),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                data.label,
                style: AppTypography.metadata.copyWith(
                  fontSize: 12,
                  height: 1.35,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                data.value,
                style: AppTypography.sectionTitle.copyWith(
                  fontSize: 18,
                  height: 1.25,
                  letterSpacing: -0.25,
                  fontWeight: FontWeight.w700,
                  color: data.highlightValue
                      ? AppColors.sakura600
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PlanExamSummaryCard extends StatelessWidget {
  const _PlanExamSummaryCard({
    required this.targetExamDate,
    required this.examSession,
    required this.reduceMotion,
  });

  final DateTime? targetExamDate;
  final JlptExamSession? examSession;
  final bool reduceMotion;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasDate = targetExamDate != null;
    final formattedDate = targetExamDate == null
        ? null
        : _formatExamDate(targetExamDate!);

    final String headline;
    final String supporting;
    if (!hasDate) {
      headline = l10n.onboardingPlanNoExamTitle;
      supporting = l10n.onboardingPlanNoExamSubtitle;
    } else if (examSession != null) {
      headline = l10n.onboardingPlanExamMonthYear(
        examSession!.month,
        examSession!.year,
      );
      supporting = l10n.onboardingEstimatedDate(formattedDate!);
    } else {
      headline = formattedDate!;
      supporting = l10n.onboardingSavedExamDate(formattedDate);
    }

    return AnimatedContainer(
      key: const ValueKey<String>('onboarding_plan_exam_summary'),
      duration: reduceMotion
          ? Duration.zero
          : const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasDate ? AppColors.sakura50 : AppColors.surfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasDate ? AppColors.sakura200 : const Color(0xFFEAE3E5),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: hasDate
                  ? AppColors.cardWarmWhite
                  : AppColors.cardWarmWhite.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: hasDate
                    ? AppColors.sakura200.withValues(alpha: 0.8)
                    : const Color(0xFFECE6E8),
              ),
            ),
            child: Icon(
              hasDate
                  ? Icons.event_available_rounded
                  : Icons.event_note_outlined,
              size: 22,
              color: hasDate ? AppColors.brandPrimary : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AnimatedSwitcher(
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 200),
              child: Align(
                key: ValueKey<String>('$headline|$supporting'),
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.onboardingPlanExamSummaryLabel,
                      style: AppTypography.metadata.copyWith(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      headline,
                      style: AppTypography.sectionTitle.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      supporting,
                      style: AppTypography.metadata.copyWith(
                        fontSize: 12,
                        color: hasDate
                            ? AppColors.sakura700
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatExamDate(DateTime date) =>
    '${date.day.toString().padLeft(2, '0')}/'
    '${date.month.toString().padLeft(2, '0')}/${date.year}';
