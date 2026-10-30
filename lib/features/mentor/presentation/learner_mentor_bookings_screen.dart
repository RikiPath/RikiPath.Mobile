import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/learner_mentor_shared_widgets.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

class LearnerMentorBookingsScreen extends ConsumerWidget {
  const LearnerMentorBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(learnerMentorBookingsControllerProvider);
    return Scaffold(
      key: const Key('learner_mentor_bookings_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(title: Text(context.l10n.learnerMentorMyMeetings)),
      body: SafeArea(
        top: false,
        child: switch (state) {
          AsyncLoading() => const MentorListSkeleton(
            key: Key('learner_mentor_bookings_loading'),
          ),
          AsyncError() => Center(
            child: MentorErrorState(
              key: const Key('learner_mentor_bookings_error'),
              message: context.l10n.learnerMentorBookingsError,
              onRetry: ref
                  .read(learnerMentorBookingsControllerProvider.notifier)
                  .retry,
            ),
          ),
          AsyncData(:final value) => _BookingsBody(
            bookings: value,
            onRefresh: ref
                .read(learnerMentorBookingsControllerProvider.notifier)
                .retry,
          ),
        },
      ),
    );
  }
}

class _BookingsBody extends StatelessWidget {
  const _BookingsBody({required this.bookings, required this.onRefresh});

  final List<LearnerMentorBooking> bookings;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const Key('learner_mentor_bookings_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          if (bookings.isEmpty)
            MentorEmptyState(
              key: const Key('learner_mentor_bookings_empty'),
              icon: Icons.event_note_outlined,
              title: context.l10n.learnerMentorMyMeetings,
              description: context.l10n.learnerMentorBookingsEmpty,
            )
          else
            for (var index = 0; index < bookings.length; index++) ...[
              LearnerMentorBookingCard(
                key: ValueKey<String>(
                  'learner_mentor_booking_${bookings[index].id}',
                ),
                booking: bookings[index],
                onTap: () => context.push(
                  AppRoutes.learnerMentorBookingDetail(bookings[index].id),
                ),
              ),
              if (index < bookings.length - 1)
                const SizedBox(height: AppSpacing.space3),
            ],
        ],
      ),
    );
  }
}
