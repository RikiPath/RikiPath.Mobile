import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mock_test/application/mock_test_controller.dart';
import 'package:rikipath_mobile/features/mock_test/application/mock_test_library_controller.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test.dart';
import 'package:rikipath_mobile/features/mock_test/domain/mock_test_display_title.dart';

class MockTestLibraryScreen extends ConsumerWidget {
  const MockTestLibraryScreen({super.key});

  Future<void> _openTest(
    BuildContext context,
    WidgetRef ref,
    LiveMockTestSummary test,
  ) async {
    try {
      await ref.read(mockTestControllerProvider.future);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.mockLibraryOpenFailed)),
        );
      }
      return;
    }
    if (!context.mounted) return;
    if (!ref
        .read(mockTestControllerProvider.notifier)
        .selectLibraryTest(test)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.mockLibraryActiveAttempt)),
      );
      return;
    }
    final flow = ref.read(mockTestControllerProvider).value;
    context.push(
      flow?.result != null
          ? AppRoutes.mockTestResult(test.id.toString())
          : AppRoutes.mockTest(test.id.toString()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(mockTestLibraryProvider);
    final selectedLevelCode = ref.watch(selectedMockTestLevelProvider);
    final flow = ref.watch(mockTestControllerProvider).value;
    final isJa = Localizations.localeOf(context).languageCode == 'ja';

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        backgroundColor: AppColors.learnerBackground,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          context.l10n.mockLibraryTitle,
          style: AppTypography.pageTitle.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: false,
      ),
      body: catalog.when(
        loading: () => const Center(
          child: CircularProgressIndicator(
            key: ValueKey<String>('mock_test_library_loading'),
          ),
        ),
        error: (error, _) => RikiErrorState(
          key: const ValueKey<String>('mock_test_library_error'),
          title: context.l10n.mockLoadFailed,
          message: context.l10n.checkConnectionRetry,
          actionLabel: context.l10n.retry,
          onAction: () => ref.invalidate(mockTestLibraryProvider),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return RikiEmptyState(
              key: const ValueKey<String>('mock_test_library_empty'),
              icon: Icons.assignment_outlined,
              title: context.l10n.mockTestTitle,
              message: context.l10n.mockNoTestsAvailable,
            );
          }

          // Resolve active selected level group
          final activeCode =
              selectedLevelCode ??
              (groups.any((g) => g.level.code == flow?.targetJlptLevelName)
                  ? flow!.targetJlptLevelName!
                  : groups.first.level.code);

          final selectedGroup = groups.firstWhere(
            (g) => g.level.code == activeCode,
            orElse: () => groups.first,
          );

          // Find if there's an in-progress attempt for a test in this selected level
          final activeAttempt =
              (flow?.hasActiveAttempt == true &&
                  selectedGroup.tests.any(
                    (t) => t.id == flow?.attempt?.mockTestId,
                  ))
              ? flow?.attempt
              : null;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Level Selector (N5 | N4 | N3 | N2)
              _LevelSelector(
                groups: groups,
                selectedCode: selectedGroup.level.code,
                onSelectLevel: (code) {
                  ref.read(selectedMockTestLevelProvider.notifier).select(code);
                },
              ),

              // 2. Main Exam Hub Content (Overview + Compact Exam List)
              Expanded(
                child: ListView(
                  key: const ValueKey<String>('mock_test_library'),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.space4,
                    AppSpacing.space2,
                    AppSpacing.space4,
                    AppSpacing.space6,
                  ),
                  children: [
                    // Selected Level Overview Card
                    _SelectedLevelOverviewCard(
                      group: selectedGroup,
                      activeAttempt: activeAttempt,
                      onTapActiveAttempt: () {
                        if (activeAttempt != null) {
                          final matching = selectedGroup.tests
                              .where((t) => t.id == activeAttempt.mockTestId)
                              .firstOrNull;
                          if (matching != null) {
                            _openTest(context, ref, matching);
                          }
                        }
                      },
                    ),

                    const SizedBox(height: AppSpacing.space4),

                    // Section Header
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            isJa ? '模擬試験一覧' : 'Danh sách đề thi',
                            style: AppTypography.sectionTitle.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${selectedGroup.tests.length} ${isJa ? '件' : 'bộ đề'}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.space3),

                    // Exam Cards
                    if (selectedGroup.tests.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.space6,
                        ),
                        child: RikiEmptyState(
                          icon: Icons.assignment_outlined,
                          title: context.l10n.mockNoTestsAvailable,
                          message: '',
                        ),
                      )
                    else
                      for (int i = 0; i < selectedGroup.tests.length; i++) ...[
                        _CompactExamCard(
                          key: ValueKey<String>(
                            'mock_library_test_${selectedGroup.tests[i].id}',
                          ),
                          index: i + 1,
                          test: selectedGroup.tests[i],
                          levelCode: selectedGroup.level.code,
                          isJa: isJa,
                          isActiveAttempt:
                              flow?.hasActiveAttempt == true &&
                              flow?.attempt?.mockTestId ==
                                  selectedGroup.tests[i].id,
                          isCompleted:
                              flow?.result != null &&
                              flow?.selectedTest?.id ==
                                  selectedGroup.tests[i].id,
                          onTap: () =>
                              _openTest(context, ref, selectedGroup.tests[i]),
                        ),
                        if (i < selectedGroup.tests.length - 1)
                          const SizedBox(height: AppSpacing.space3),
                      ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Level Selector
// ---------------------------------------------------------------------------
class _LevelSelector extends StatelessWidget {
  const _LevelSelector({
    required this.groups,
    required this.selectedCode,
    required this.onSelectLevel,
  });

  final List<MockTestLevelGroup> groups;
  final String selectedCode;
  final ValueChanged<String> onSelectLevel;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.learnerBackground,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.space2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.space4),
        child: Row(
          children: [
            for (final group in groups) ...[
              _LevelSelectorTab(
                key: ValueKey<String>('mock_level_${group.level.code}'),
                code: group.level.code,
                count: group.tests.length,
                isSelected: group.level.code == selectedCode,
                onTap: () => onSelectLevel(group.level.code),
              ),
              const SizedBox(width: AppSpacing.space2),
            ],
          ],
        ),
      ),
    );
  }
}

class _LevelSelectorTab extends StatelessWidget {
  const _LevelSelectorTab({
    required this.code,
    required this.count,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String code;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : AppColors.cardWarmWhite,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : AppColors.cardBorderSubtle,
              width: 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'JLPT $code',
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textPrimary,
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
              if (count > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1.5,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.25)
                        : AppColors.learnerBackground,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textMuted,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 2. Selected Level Overview Card
// ---------------------------------------------------------------------------
class _SelectedLevelOverviewCard extends StatelessWidget {
  const _SelectedLevelOverviewCard({
    required this.group,
    this.activeAttempt,
    this.onTapActiveAttempt,
  });

  final MockTestLevelGroup group;
  final LiveMockTestAttempt? activeAttempt;
  final VoidCallback? onTapActiveAttempt;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardWarmWhite,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.cardBorderSubtle, width: 1),
        boxShadow: AppShadows.sakuraSubtle,
      ),
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.brandTint,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Sakura3DIcon(
                  type: Sakura3DIconType.mockExam,
                  size: 38,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'JLPT ${group.level.code}',
                            style: AppTypography.cardTitle.copyWith(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        _LevelPill(label: group.level.code),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.l10n.mockLibraryAvailableCount(
                        group.tests.length,
                      ),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (activeAttempt != null) ...[
            const SizedBox(height: AppSpacing.space3),
            InkWell(
              onTap: onTapActiveAttempt,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: AppColors.pastelOrangeBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.pastelOrangeFg.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.play_circle_fill_rounded,
                      color: AppColors.pastelOrangeFg,
                      size: 17,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        context.l10n.mockInProgress(
                          activeAttempt!.answers.length,
                          activeAttempt!.questions.length,
                        ),
                        style: const TextStyle(
                          color: AppColors.pastelOrangeFg,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      context.l10n.continueLabel,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.primary,
                      size: 10,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 3. Compact Exam Item Card
// ---------------------------------------------------------------------------
class _CompactExamCard extends StatelessWidget {
  const _CompactExamCard({
    required this.index,
    required this.test,
    required this.levelCode,
    required this.isJa,
    required this.isActiveAttempt,
    required this.isCompleted,
    required this.onTap,
    super.key,
  });

  final int index;
  final LiveMockTestSummary test;
  final String levelCode;
  final bool isJa;
  final bool isActiveAttempt;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = mockTestDisplayTitle(
      test.title,
      japanese: isJa,
      compact: true,
    );
    final formattedIndex = index.toString().padLeft(2, '0');

    return Material(
      color: AppColors.cardWarmWhite,
      borderRadius: BorderRadius.circular(AppRadius.cardSmooth),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.cardSmooth),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.cardSmooth),
            border: Border.all(
              color: isActiveAttempt
                  ? AppColors.pastelOrangeFg.withValues(alpha: 0.4)
                  : AppColors.cardBorderSubtle,
              width: 1,
            ),
            boxShadow: AppShadows.sakuraSubtle,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Index Badge
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isActiveAttempt
                      ? AppColors.pastelOrangeBg
                      : AppColors.brandTint,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  formattedIndex,
                  style: TextStyle(
                    color: isActiveAttempt
                        ? AppColors.pastelOrangeFg
                        : AppColors.primary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Title & Metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.cardTitle.copyWith(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              size: 13,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${test.timeLimitMinutes} ${isJa ? '分' : 'phút'}',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textMuted,
                                fontSize: 11.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const Text(
                          '•',
                          style: TextStyle(
                            color: AppColors.cardBorderSubtle,
                            fontSize: 12,
                          ),
                        ),
                        _StatusPill(
                          label: isActiveAttempt
                              ? (isJa ? '受験中' : 'Đang làm')
                              : isCompleted
                              ? (isJa ? '完了' : 'Đã thi')
                              : (isJa ? '未受験' : 'Chưa thi'),
                          backgroundColor: isActiveAttempt
                              ? AppColors.pastelOrangeBg
                              : isCompleted
                              ? AppColors.pastelGreenBg
                              : AppColors.learnerBackground,
                          textColor: isActiveAttempt
                              ? AppColors.pastelOrangeFg
                              : isCompleted
                              ? AppColors.pastelGreenFg
                              : AppColors.textMuted,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Action / Chevron
              if (isActiveAttempt)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isJa ? '再開' : 'Tiếp tục',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 11,
                      ),
                    ],
                  ),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textMuted,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------
class _LevelPill extends StatelessWidget {
  const _LevelPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.brandTint,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
