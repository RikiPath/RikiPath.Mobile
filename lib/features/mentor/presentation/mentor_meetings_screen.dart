import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

class MentorMeetingsScreen extends ConsumerWidget {
  const MentorMeetingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mentorMeetingsControllerProvider);
    return Scaffold(
      key: const Key('mentor_meetings_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        title: Text(context.l10n.mentorMeetingsTitle),
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
            key: Key('mentor_meetings_loading'),
          ),
          AsyncError() => _RefreshableMeetingBody(
            key: const Key('mentor_meetings_error'),
            onRefresh: ref
                .read(mentorMeetingsControllerProvider.notifier)
                .retry,
            child: MentorErrorState(
              message: context.l10n.mentorMeetingsError,
              onRetry: ref
                  .read(mentorMeetingsControllerProvider.notifier)
                  .retry,
            ),
          ),
          AsyncData(:final value) => _MeetingList(
            meetings: value,
            onRefresh: ref
                .read(mentorMeetingsControllerProvider.notifier)
                .retry,
          ),
        },
      ),
    );
  }
}

class _MeetingList extends StatelessWidget {
  const _MeetingList({required this.meetings, required this.onRefresh});

  final List<MentorMeetingSummary> meetings;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const Key('mentor_meetings_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          MentorPageHeader(
            title: context.l10n.mentorMeetingsTitle,
            subtitle: context.l10n.mentorMeetingsDescription,
          ),
          const SizedBox(height: AppSpacing.space4),
          if (meetings.isEmpty)
            MentorEmptyState(
              key: const Key('mentor_meetings_empty'),
              icon: Icons.video_call_outlined,
              title: context.l10n.mentorMeetingsTitle,
              description: context.l10n.mentorMeetingsEmpty,
            )
          else
            for (var index = 0; index < meetings.length; index++) ...[
              MentorMeetingCard(
                key: ValueKey<String>('mentor_meeting_${meetings[index].id}'),
                meeting: meetings[index],
                onTap: () => context.push(
                  AppRoutes.mentorMeetingDetail(meetings[index].id),
                ),
              ),
              if (index < meetings.length - 1)
                const SizedBox(height: AppSpacing.space3),
            ],
        ],
      ),
    );
  }
}

class _RefreshableMeetingBody extends StatelessWidget {
  const _RefreshableMeetingBody({
    required this.onRefresh,
    required this.child,
    super.key,
  });

  final Future<void> Function() onRefresh;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.65,
            child: Center(child: child),
          ),
        ],
      ),
    );
  }
}
