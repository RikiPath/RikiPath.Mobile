import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/learner_mentor_shared_widgets.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

/// Màn hình danh sách gói học cùng Mentor 1-1 (Screen 01 theo chuẩn Neo-Japoniste Sakura).
class LearnerMentorMeetingsScreen extends ConsumerWidget {
  const LearnerMentorMeetingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(learnerMentorPlansControllerProvider);
    return Scaffold(
      key: const Key('learner_mentor_meetings_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        title: const Text('Học cùng Mentor'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: AppSpacing.space3),
            child: RikiLanguageSwitcher(),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: switch (state) {
          AsyncLoading() => const MentorListSkeleton(
              key: Key('learner_mentor_plans_loading'),
            ),
          AsyncError() => Center(
              child: MentorErrorState(
                key: const Key('learner_mentor_plans_error'),
                message: context.l10n.learnerMentorPlansError,
                onRetry: ref
                    .read(learnerMentorPlansControllerProvider.notifier)
                    .retry,
              ),
            ),
          AsyncData(:final value) => _PlansBody(
              plans: value,
              onRefresh: ref
                  .read(learnerMentorPlansControllerProvider.notifier)
                  .retry,
            ),
        },
      ),
    );
  }
}

class _PlansBody extends StatefulWidget {
  const _PlansBody({required this.plans, required this.onRefresh});

  final List<MentorMeetingPlan> plans;
  final Future<void> Function() onRefresh;

  @override
  State<_PlansBody> createState() => _PlansBodyState();
}

class _PlansBodyState extends State<_PlansBody> {
  int? _selectedPlanId;

  @override
  void initState() {
    super.initState();
    _selectedPlanId = widget.plans.firstOrNull?.id;
  }

  @override
  Widget build(BuildContext context) {
    final selectedPlan = widget.plans
            .where((p) => p.id == _selectedPlanId)
            .firstOrNull ??
        widget.plans.firstOrNull;

    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: ListView(
              key: const Key('learner_mentor_plans_list'),
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              children: [
                // Warm Neo-Japoniste Header Banner
                Container(
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    border: Border.all(
                      color: AppColors.brandPrimary.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.brandTint,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_florist,
                          color: AppColors.brandPrimary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space3),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: AppColors.brandPrimary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'ĐỒNG HÀNH 1 KÈM 1',
                                    style: AppTypography.metadata.copyWith(
                                      color: AppColors.brandPrimary,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Được hướng dẫn trực tiếp bởi Mentor giàu kinh nghiệm luyện thi JLPT.',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textPrimary,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),

                RikiSecondaryButton(
                  key: const Key('learner_mentor_my_meetings_button'),
                  label: context.l10n.learnerMentorMyMeetings,
                  leadingIcon: Icons.event_note_outlined,
                  onPressed: () =>
                      context.push(AppRoutes.learnerMentorBookings),
                ),
                const SizedBox(height: AppSpacing.space4),

                if (widget.plans.isEmpty)
                  MentorEmptyState(
                    key: const Key('learner_mentor_plans_empty'),
                    icon: Icons.support_agent_outlined,
                    title: context.l10n.learnerMentorPlansTitle,
                    description: context.l10n.learnerMentorPlansEmpty,
                  )
                else
                  for (var index = 0; index < widget.plans.length; index++) ...[
                    GestureDetector(
                      onTap: () {
                        setState(() => _selectedPlanId = widget.plans[index].id);
                      },
                      child: Stack(
                        children: [
                          LearnerMentorPlanCard(
                            key: ValueKey<String>(
                              'learner_mentor_plan_${widget.plans[index].id}',
                            ),
                            plan: widget.plans[index],
                            onTap: () {
                              setState(() =>
                                  _selectedPlanId = widget.plans[index].id);
                              context.push(
                                AppRoutes.learnerMentorDiscovery(
                                  widget.plans[index].id,
                                ),
                              );
                            },
                          ),
                          // Radio selection indicator at top-right
                          Positioned(
                            top: 18,
                            right: 18,
                            child: Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _selectedPlanId == widget.plans[index].id
                                    ? AppColors.brandPrimary
                                    : AppColors.surfaceContainer,
                                border: Border.all(
                                  color: _selectedPlanId == widget.plans[index].id
                                      ? AppColors.brandPrimary
                                      : AppColors.border,
                                  width: 1.5,
                                ),
                              ),
                              child: _selectedPlanId == widget.plans[index].id
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (index < widget.plans.length - 1)
                      const SizedBox(height: AppSpacing.space4),
                  ],
              ],
            ),
          ),
        ),

        // Sticky Bottom Bar
        if (selectedPlan != null)
          Container(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: AppShadows.cardSoft,
              border: const Border(
                top: BorderSide(color: AppColors.border),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        selectedPlan.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.metadata.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.space2),
                    Text(
                      learnerMentorPriceLabel(selectedPlan.price, context),
                      style: AppTypography.cardTitle.copyWith(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space2),
                RikiPrimaryButton(
                  key: const Key('learner_mentor_continue_to_mentor_button'),
                  label: 'Tiếp tục chọn Mentor',
                  trailingIcon: Icons.arrow_forward,
                  onPressed: () => context.push(
                    AppRoutes.learnerMentorDiscovery(selectedPlan.id),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
