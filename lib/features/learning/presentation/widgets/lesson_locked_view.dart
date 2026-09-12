import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/learning/domain/lesson.dart';

class LessonLockedView extends StatelessWidget {
  const LessonLockedView({
    required this.lesson,
    required this.onContinuePrerequisite,
    required this.onBackToRoadmap,
    super.key,
  });

  final Lesson lesson;
  final VoidCallback? onContinuePrerequisite;
  final VoidCallback onBackToRoadmap;

  @override
  Widget build(BuildContext context) {
    final prerequisite = lesson.prerequisite;
    return ListView(
      key: const ValueKey<String>('lesson_locked_view'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space8,
      ),
      children: [
        RikiCard(
          child: Column(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.warningBackground,
                foregroundColor: AppColors.skillGrammar,
                child: Icon(Icons.lock_outline, size: 30),
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(
                'NỘI DUNG CÓ KHÓA TIẾN TRÌNH',
                textAlign: TextAlign.center,
                style: AppTypography.badgeText.copyWith(
                  color: AppColors.learnerTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                'Bài ${lesson.lessonNumber}: ${lesson.title}',
                textAlign: TextAlign.center,
                style: AppTypography.sectionTitle.copyWith(
                  color: AppColors.learnerTextPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                lesson.lockedReason ?? 'Bài học này chưa được mở.',
                textAlign: TextAlign.center,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
        if (prerequisite != null) ...[
          const SizedBox(height: AppSpacing.space4),
          RikiCard(
            borderColor: AppColors.brandBorder,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'ĐIỀU KIỆN MỞ KHÓA',
                  style: AppTypography.badgeText.copyWith(
                    color: AppColors.brandPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
                Text(
                  'Bài ${prerequisite.lessonNumber}: ${prerequisite.title}',
                  style: AppTypography.cardTitle,
                ),
                const SizedBox(height: AppSpacing.space1),
                Text(
                  prerequisite.focus,
                  style: AppTypography.cardTitle.copyWith(
                    color: AppColors.brandPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  child: LinearProgressIndicator(
                    value: prerequisite.progressPercent / 100,
                    minHeight: 8,
                    color: AppColors.brandPrimary,
                    backgroundColor: AppColors.learnerSurfaceLow,
                  ),
                ),
                const SizedBox(height: AppSpacing.space2),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: AppSpacing.space3,
                  runSpacing: AppSpacing.space1,
                  children: [
                    Text(
                      'Tiến độ: ${prerequisite.completedParts}/'
                      '${prerequisite.totalParts} phần',
                      style: AppTypography.metadata.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Còn ~${prerequisite.remainingMinutes} phút',
                      style: AppTypography.metadata.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.space5),
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          spacing: AppSpacing.space3,
          runSpacing: AppSpacing.space1,
          children: [
            Text(
              'Xem trước nội dung Bài ${lesson.lessonNumber}',
              style: AppTypography.sectionTitle.copyWith(
                color: AppColors.learnerTextPrimary,
              ),
            ),
            Text(
              '${lesson.parts.length} phần học • ~${lesson.durationMinutes} phút',
              style: AppTypography.metadata.copyWith(
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.space3),
        for (var index = 0; index < lesson.parts.length; index++) ...[
          _LockedPart(part: lesson.parts[index]),
          if (index != lesson.parts.length - 1)
            const SizedBox(height: AppSpacing.space2),
        ],
        const SizedBox(height: AppSpacing.space5),
        if (prerequisite != null)
          RikiPrimaryButton(
            key: const ValueKey<String>('lesson_continue_prerequisite_button'),
            label:
                'Tiếp tục Bài ${prerequisite.lessonNumber} '
                '(còn ${100 - prerequisite.progressPercent}%)',
            trailingIcon: Icons.arrow_forward,
            onPressed: onContinuePrerequisite,
          ),
        const SizedBox(height: AppSpacing.space2),
        RikiSecondaryButton(
          label: 'Quay lại lộ trình học tập',
          onPressed: onBackToRoadmap,
        ),
      ],
    );
  }
}

class _LockedPart extends StatelessWidget {
  const _LockedPart({required this.part});

  final LessonPart part;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.78,
      child: RikiCard(
        padding: const EdgeInsets.all(AppSpacing.space3),
        boxShadow: const <BoxShadow>[],
        child: Row(
          children: [
            const CircleAvatar(
              radius: 17,
              backgroundColor: AppColors.surfaceSubtle,
              foregroundColor: AppColors.textMuted,
              child: Icon(Icons.menu_book_outlined, size: 18),
            ),
            const SizedBox(width: AppSpacing.space3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${part.number}. ${part.title}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.learnerTextPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${part.subtitle} • ${part.durationMinutes} phút',
                    style: AppTypography.metadata.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.lock_outline,
              color: AppColors.textMuted,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
