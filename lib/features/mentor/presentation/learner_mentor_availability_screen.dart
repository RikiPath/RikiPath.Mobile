import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/learner_mentor_shared_widgets.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

class LearnerMentorAvailabilityScreen extends ConsumerStatefulWidget {
  const LearnerMentorAvailabilityScreen({required this.planId, super.key});

  final int? planId;

  @override
  ConsumerState<LearnerMentorAvailabilityScreen> createState() =>
      _LearnerMentorAvailabilityScreenState();
}

class _LearnerMentorAvailabilityScreenState
    extends ConsumerState<LearnerMentorAvailabilityScreen> {
  DateTime? _selectedDate;
  int? _selectedSlotId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(learnerMentorAvailabilityControllerProvider);
    return Scaffold(
      key: const Key('learner_mentor_availability_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(title: Text(context.l10n.learnerMentorAvailabilityTitle)),
      body: SafeArea(
        top: false,
        child: switch (state) {
          AsyncLoading() => const MentorListSkeleton(
            key: Key('learner_mentor_availability_loading'),
          ),
          AsyncError() => Center(
            child: MentorErrorState(
              key: const Key('learner_mentor_availability_error'),
              message: context.l10n.learnerMentorAvailabilityError,
              onRetry: ref
                  .read(learnerMentorAvailabilityControllerProvider.notifier)
                  .retry,
            ),
          ),
          AsyncData(:final value) => _buildContent(value),
        },
      ),
    );
  }

  Widget _buildContent(List<LearnerMentorAvailability> allSlots) {
    final availableSlots = allSlots
        .where((slot) => !slot.isBooked)
        .toList(growable: false);
    final dates = <DateTime>[];
    for (final slot in availableSlots) {
      final date = DateUtils.dateOnly(slot.startTime.displayValue);
      if (!dates.any((value) => DateUtils.isSameDay(value, date))) {
        dates.add(date);
      }
    }
    dates.sort();
    final activeDate =
        dates.any((date) => DateUtils.isSameDay(date, _selectedDate))
        ? _selectedDate
        : dates.firstOrNull;
    final visibleSlots = activeDate == null
        ? const <LearnerMentorAvailability>[]
        : availableSlots
              .where(
                (slot) => DateUtils.isSameDay(
                  slot.startTime.displayValue,
                  activeDate,
                ),
              )
              .toList(growable: false);

    return ListView(
      key: const Key('learner_mentor_availability_list'),
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      children: [
        MentorPageHeader(
          title: context.l10n.learnerMentorAvailabilityTitle,
          subtitle: context.l10n.learnerMentorAvailabilitySubtitle,
        ),
        const SizedBox(height: AppSpacing.space4),
        if (dates.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final date in dates) ...[
                  ChoiceChip(
                    key: ValueKey<String>(
                      'learner_mentor_date_${date.toIso8601String()}',
                    ),
                    label: Text(
                      DateFormat.MMMd(
                        Localizations.localeOf(context).toLanguageTag(),
                      ).format(date),
                    ),
                    selected: DateUtils.isSameDay(date, activeDate),
                    onSelected: (_) {
                      setState(() {
                        _selectedDate = date;
                        _selectedSlotId = null;
                      });
                    },
                  ),
                  const SizedBox(width: AppSpacing.space2),
                ],
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.space4),
        if (visibleSlots.isEmpty)
          MentorEmptyState(
            key: const Key('learner_mentor_availability_empty'),
            icon: Icons.event_busy_outlined,
            title: context.l10n.learnerMentorAvailabilityTitle,
            description: context.l10n.learnerMentorAvailabilityEmpty,
          )
        else
          for (var index = 0; index < visibleSlots.length; index++) ...[
            LearnerMentorAvailabilityCard(
              key: ValueKey<String>(
                'learner_mentor_slot_${visibleSlots[index].id}',
              ),
              slot: visibleSlots[index],
              selected: _selectedSlotId == visibleSlots[index].id,
              onTap: () =>
                  setState(() => _selectedSlotId = visibleSlots[index].id),
            ),
            if (index < visibleSlots.length - 1)
              const SizedBox(height: AppSpacing.space3),
          ],
        const SizedBox(height: AppSpacing.space5),
        RikiWarningBanner(
          key: const Key('learner_mentor_purchase_blocked'),
          title: context.l10n.learnerMentorPurchaseBlockedTitle,
          message: context.l10n.learnerMentorPurchaseBlocked,
        ),
        const SizedBox(height: AppSpacing.space4),
        RikiPrimaryButton(
          key: const Key('learner_mentor_purchase_button'),
          label: context.l10n.learnerMentorPurchase,
          leadingIcon: Icons.lock_outline,
          onPressed: null,
        ),
      ],
    );
  }
}
