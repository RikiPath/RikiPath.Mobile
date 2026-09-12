import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/learning/domain/learning_snapshot.dart';

class JlptProgressView extends StatelessWidget {
  const JlptProgressView({
    required this.snapshot,
    required this.onOpenRoadmap,
    super.key,
  });

  final LearningSnapshot snapshot;
  final VoidCallback onOpenRoadmap;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey<String>('jlpt_progress_success_view'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space3,
        AppSpacing.space4,
        AppSpacing.space8,
      ),
      children: [
        _OverallProgressCard(snapshot: snapshot),
        const SizedBox(height: AppSpacing.space5),
        _SkillProgressCard(skills: snapshot.skillProgress),
        const SizedBox(height: AppSpacing.space5),
        Semantics(
          enabled: false,
          hint: 'Chi tiết bài học được triển khai trong C10',
          child: RikiPrimaryButton(
            key: const ValueKey<String>('progress_continue_lesson_button'),
            label: 'Tiếp tục học',
            trailingIcon: Icons.arrow_forward,
            onPressed: null,
          ),
        ),
        const SizedBox(height: AppSpacing.space3),
        RikiSecondaryButton(
          key: const ValueKey<String>('progress_open_roadmap_button'),
          label: 'Xem lộ trình chi tiết',
          leadingIcon: Icons.map_outlined,
          onPressed: onOpenRoadmap,
        ),
      ],
    );
  }
}

class _OverallProgressCard extends StatelessWidget {
  const _OverallProgressCard({required this.snapshot});

  final LearningSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      borderColor: AppColors.border,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.space3,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.brandTint,
                        border: Border.all(color: AppColors.brandBorder),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const DecoratedBox(
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: SizedBox.square(dimension: 7),
                          ),
                          const SizedBox(width: AppSpacing.space2),
                          Flexible(
                            child: Text(
                              'Cấp độ mục tiêu: ${snapshot.jlptTarget.label}',
                              style: AppTypography.badgeText.copyWith(
                                color: AppColors.brandPrimary,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    Text(
                      'Tổng tiến độ toàn khóa',
                      style: AppTypography.sectionTitle.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Text(
                '${snapshot.overallPercent}%',
                style: AppTypography.heroTitle.copyWith(
                  color: AppColors.brandPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: snapshot.overallProgress,
              minHeight: 12,
              color: AppColors.brandPrimary,
              backgroundColor: AppColors.learnerSurfaceLow,
              semanticsLabel:
                  'Tổng tiến độ toàn khóa ${snapshot.overallPercent} phần trăm',
            ),
          ),
          const SizedBox(height: AppSpacing.space3),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.space2),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: AppSpacing.space3,
            runSpacing: AppSpacing.space1,
            children: [
              Text(
                'Đã hoàn thành ${snapshot.completedLessons}/'
                '${snapshot.totalLessons} bài học tổng thể',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                'Kỳ thi dự kiến: ${snapshot.examDateLabel}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.learnerTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SkillProgressCard extends StatelessWidget {
  const _SkillProgressCard({required this.skills});

  final List<LearningSkillProgress> skills;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      borderColor: AppColors.border,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Chi tiết tiến độ kỹ năng',
                  style: AppTypography.sectionTitle.copyWith(
                    color: AppColors.learnerTextPrimary,
                  ),
                ),
              ),
              Text(
                '${skills.length}/5 kỹ năng',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space3),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.space4),
          for (var index = 0; index < skills.length; index++) ...[
            _SkillProgressRow(skill: skills[index]),
            if (index != skills.length - 1)
              const SizedBox(height: AppSpacing.space5),
          ],
        ],
      ),
    );
  }
}

class _SkillProgressRow extends StatelessWidget {
  const _SkillProgressRow({required this.skill});

  final LearningSkillProgress skill;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final glyph = Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: skill.category.backgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.compact),
              ),
              child: Text(
                skill.category.glyph,
                style: AppTypography.cardTitle.copyWith(
                  color: skill.category.foregroundColor,
                ),
              ),
            );
            final label = Text(
              skill.category.label,
              style: AppTypography.cardTitle.copyWith(
                color: AppColors.learnerTextPrimary,
              ),
            );
            final value = Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: '${skill.current}'),
                  TextSpan(
                    text: ' / ${skill.total} ${skill.unit}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.learnerTextPrimary,
                fontWeight: FontWeight.w700,
              ),
            );
            final percent = Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: skill.category.backgroundColor,
                borderRadius: BorderRadius.circular(AppRadius.tag),
              ),
              child: Text(
                '${skill.progressPercent}%',
                style: AppTypography.badgeText.copyWith(
                  color: skill.category.foregroundColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            );

            if (constraints.maxWidth < 300) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      glyph,
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(child: label),
                      const SizedBox(width: AppSpacing.space2),
                      percent,
                    ],
                  ),
                  const SizedBox(height: AppSpacing.space1),
                  Align(alignment: Alignment.centerRight, child: value),
                ],
              );
            }

            return Row(
              children: [
                glyph,
                const SizedBox(width: AppSpacing.space3),
                Expanded(child: label),
                value,
                const SizedBox(width: AppSpacing.space2),
                percent,
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.space2),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: skill.progress,
            minHeight: 8,
            color: skill.category.foregroundColor,
            backgroundColor: AppColors.learnerSurfaceLow,
            semanticsLabel:
                'Tiến độ ${skill.category.label} '
                '${skill.progressPercent} phần trăm',
          ),
        ),
      ],
    );
  }
}

extension on LearningSkillCategory {
  String get glyph => switch (this) {
    LearningSkillCategory.vocabulary => '語',
    LearningSkillCategory.kanji => '漢',
    LearningSkillCategory.grammar => '文',
    LearningSkillCategory.reading => '読',
    LearningSkillCategory.listening => '聴',
  };

  Color get foregroundColor => switch (this) {
    LearningSkillCategory.vocabulary => AppColors.brandPrimary,
    LearningSkillCategory.kanji => AppColors.info,
    LearningSkillCategory.grammar => AppColors.skillGrammar,
    LearningSkillCategory.reading => AppColors.success,
    LearningSkillCategory.listening => AppColors.skillListening,
  };

  Color get backgroundColor => switch (this) {
    LearningSkillCategory.vocabulary => AppColors.brandTint,
    LearningSkillCategory.kanji => AppColors.infoBackground,
    LearningSkillCategory.grammar => AppColors.warningBackground,
    LearningSkillCategory.reading => AppColors.successBackground,
    LearningSkillCategory.listening => AppColors.skillListeningBackground,
  };
}
