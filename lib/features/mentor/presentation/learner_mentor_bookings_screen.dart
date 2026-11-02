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

class LearnerMentorBookingsScreen extends ConsumerWidget {
  const LearnerMentorBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(learnerMentorBookingsControllerProvider);
    final balanceState = ref.watch(learnerCreditBalanceControllerProvider);

    return Scaffold(
      key: const Key('learner_mentor_bookings_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        title: Text(context.l10n.learnerMentorMyMeetings),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: () => context.push(AppRoutes.notifications),
          ),
        ],
      ),
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
              onRetry: () {
                ref
                    .read(learnerMentorBookingsControllerProvider.notifier)
                    .retry();
                ref
                    .read(learnerCreditBalanceControllerProvider.notifier)
                    .retry();
              },
            ),
          ),
          AsyncData(:final value) => _BookingsBody(
            bookings: value,
            balance: balanceState.value,
            onRefresh: () async {
              await ref
                  .read(learnerMentorBookingsControllerProvider.notifier)
                  .retry();
              await ref
                  .read(learnerCreditBalanceControllerProvider.notifier)
                  .retry();
            },
          ),
        },
      ),
    );
  }
}

class _BookingsBody extends StatelessWidget {
  const _BookingsBody({
    required this.bookings,
    required this.balance,
    required this.onRefresh,
  });

  final List<LearnerMentorBooking> bookings;
  final LearnerCreditBalance? balance;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    final remaining = balance?.availableBalance ?? 0;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const Key('learner_mentor_bookings_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          // Credit Balance Card
          RikiCard(
            key: const Key('learner_credit_balance_card'),
            backgroundColor: AppColors.surface,
            borderColor: AppColors.brandPrimary.withValues(alpha: 0.35),
            padding: const EdgeInsets.all(AppSpacing.space4),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.brandTint,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: const Icon(
                    Icons.confirmation_number_outlined,
                    color: AppColors.brandPrimary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vé tư vấn khả dụng',
                        style: AppTypography.metadata.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        '$remaining vé (1-1)',
                        style: AppTypography.cardTitle.copyWith(
                          fontWeight: FontWeight.bold,
                          color: remaining > 0
                              ? AppColors.brandPrimary
                              : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  key: const Key('book_or_buy_ticket_button'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                  ),
                  onPressed: () =>
                      context.push(AppRoutes.learnerMentorMeetings),
                  child: Text(
                    remaining > 0 ? 'Đặt lịch' : 'Mua thêm',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.space4),

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
