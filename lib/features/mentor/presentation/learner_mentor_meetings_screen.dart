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

class LearnerMentorMeetingsScreen extends ConsumerWidget {
  const LearnerMentorMeetingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(learnerMentorPlansControllerProvider);
    return Scaffold(
      key: const Key('learner_mentor_meetings_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        title: Text(context.l10n.learnerMentorTitle),
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

class _PlansBody extends StatelessWidget {
  const _PlansBody({required this.plans, required this.onRefresh});

  final List<MentorMeetingPlan> plans;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const Key('learner_mentor_plans_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          MentorPageHeader(
            title: context.l10n.learnerMentorPlansTitle,
            subtitle: context.l10n.learnerMentorSubtitle,
          ),
          const SizedBox(height: AppSpacing.space4),
          RikiSecondaryButton(
            key: const Key('learner_mentor_my_meetings_button'),
            label: context.l10n.learnerMentorMyMeetings,
            leadingIcon: Icons.event_note_outlined,
            onPressed: () => context.push(AppRoutes.learnerMentorBookings),
          ),
          const SizedBox(height: AppSpacing.space5),
          if (plans.isEmpty)
            MentorEmptyState(
              key: const Key('learner_mentor_plans_empty'),
              icon: Icons.support_agent_outlined,
              title: context.l10n.learnerMentorPlansTitle,
              description: context.l10n.learnerMentorPlansEmpty,
            )
          else
            for (var index = 0; index < plans.length; index++) ...[
              LearnerMentorPlanCard(
                key: ValueKey<String>('learner_mentor_plan_${plans[index].id}'),
                plan: plans[index],
                onTap: () => context.push(
                  AppRoutes.learnerMentorAvailability(plans[index].id),
                ),
              ),
              if (index < plans.length - 1)
                const SizedBox(height: AppSpacing.space4),
            ],
        ],
      ),
    );
  }
}
