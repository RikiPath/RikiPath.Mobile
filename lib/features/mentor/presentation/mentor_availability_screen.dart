import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/router/navigation_helpers.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/sakura_app_header.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_schedule_v3_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_schedule_v3_section.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

class MentorAvailabilityScreen extends ConsumerStatefulWidget {
  const MentorAvailabilityScreen({super.key});

  @override
  ConsumerState<MentorAvailabilityScreen> createState() =>
      _MentorAvailabilityScreenState();
}

class _MentorAvailabilityScreenState
    extends ConsumerState<MentorAvailabilityScreen> {
  bool _hasScheduleV3DirtyChanges = false;

  void _onScheduleV3DirtyChanged(bool dirty) {
    if (dirty != _hasScheduleV3DirtyChanges && mounted) {
      setState(() => _hasScheduleV3DirtyChanges = dirty);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(mentorAvailabilityControllerProvider);
    final inShell = MentorShellScope.hasShell(context);
    final hasUnsavedChanges = !inShell && _hasScheduleV3DirtyChanges;
    final canPopRoute =
        inShell ||
        (!hasUnsavedChanges &&
            (GoRouter.maybeOf(context)?.canPop() ??
                (ModalRoute.of(context)?.canPop ?? true)));
    final content = Scaffold(
      key: const Key('mentor_availability_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: SakuraAppHeader(
        showStreak: false,
        calendarTooltip: 'Lịch giảng dạy',
        onNotificationsPressed: () =>
            mentorNavigate(context, AppRoutes.notifications),
        onCalendarPressed: () => mentorNavigate(context, AppRoutes.mentorCalendar),
      ),
      bottomNavigationBar: inShell
          ? null
          : const MentorBottomNavigationBar(selectedIndex: 3),
      body: SafeArea(
        top: false,
        child: switch (state) {
          AsyncLoading() => const MentorListSkeleton(
            key: Key('mentor_availability_loading'),
          ),
          AsyncError() => _RefreshableAvailabilityBody(
            key: const Key('mentor_availability_error'),
            onRefresh: ref
                .read(mentorAvailabilityControllerProvider.notifier)
                .retry,
            child: MentorErrorState(
              message: context.l10n.mentorAvailabilityError,
              onRetry: ref
                  .read(mentorAvailabilityControllerProvider.notifier)
                  .retry,
            ),
          ),
          AsyncData(:final value) => _AvailabilityList(
            slots: value,
            onScheduleV3DirtyChanged: _onScheduleV3DirtyChanged,
            onRefresh: () async {
              ref.invalidate(mentorScheduleV3ControllerProvider);
              await ref
                  .read(mentorAvailabilityControllerProvider.notifier)
                  .retry();
            },
          ),
        },
      ),
    );

    if (inShell) {
      return content;
    }

    return PopScope(
      canPop: canPopRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          handleProtectedBackNavigation(
            context: context,
            hasUnsavedChanges: hasUnsavedChanges,
            fallbackRoute: AppRoutes.mentorCalendar,
          );
        }
      },
      child: content,
    );
  }
}

class _AvailabilityList extends ConsumerWidget {
  const _AvailabilityList({
    required this.slots,
    required this.onRefresh,
    required this.onScheduleV3DirtyChanged,
  });

  final List<MentorAvailabilitySlot> slots;
  final Future<void> Function() onRefresh;
  final ValueChanged<bool> onScheduleV3DirtyChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        key: const Key('mentor_availability_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          MentorPageHeader(
            title: context.l10n.mentorAvailabilityTitle,
            subtitle: context.l10n.mentorAvailabilityDescription,
          ),
          const SizedBox(height: AppSpacing.space4),

          // 1. Canonical published slots Section
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              const Expanded(
                child: Text(
                  'Lịch đã công bố',
                  style: AppTypography.sectionTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.space2),
              Text(
                '${slots.length} khung giờ',
                style: AppTypography.metadata.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space1),
          const Text(
            'Các khung giờ giảng dạy đã công bố để học viên và lớp nhóm sử dụng.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.space3),

          if (slots.isEmpty)
            MentorEmptyState(
              key: const Key('mentor_availability_empty'),
              icon: Icons.event_available_outlined,
              title: context.l10n.mentorAvailabilityTitle,
              description: context.l10n.mentorAvailabilityEmpty,
            )
          else
            for (var index = 0; index < slots.length; index++)
              MentorAvailabilitySlotItemCard(
                slot: slots[index],
                index: index,
              ),

          const SizedBox(height: AppSpacing.space5),

          // 2. Canonical Recurring Rules, Preview & Submit for Admin Approval
          MentorScheduleV3Card(onDirtyChanged: onScheduleV3DirtyChanged),
        ],
      ),
    );
  }
}

class _RefreshableAvailabilityBody extends StatelessWidget {
  const _RefreshableAvailabilityBody({
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
