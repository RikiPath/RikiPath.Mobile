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

class _MeetingList extends StatefulWidget {
  const _MeetingList({required this.meetings, required this.onRefresh});

  final List<MentorMeetingSummary> meetings;
  final Future<void> Function() onRefresh;

  @override
  State<_MeetingList> createState() => _MeetingListState();
}

class _MeetingListState extends State<_MeetingList> {
  int _selectedTabIndex = 0; // 0: Tất cả, 1: Chờ xác nhận, 2: Đã xác nhận, 3: Đã hoàn thành

  @override
  Widget build(BuildContext context) {
    final assignedCount = widget.meetings
        .where((m) => m.status == MentorMeetingStatus.assigned)
        .length;
    final acceptedCount = widget.meetings
        .where((m) => m.status == MentorMeetingStatus.accepted)
        .length;
    final completedCount = widget.meetings
        .where((m) => m.status == MentorMeetingStatus.completed)
        .length;

    final filteredMeetings = switch (_selectedTabIndex) {
      1 => widget.meetings.where((m) => m.status == MentorMeetingStatus.assigned).toList(),
      2 => widget.meetings.where((m) => m.status == MentorMeetingStatus.accepted).toList(),
      3 => widget.meetings.where((m) => m.status == MentorMeetingStatus.completed).toList(),
      _ => widget.meetings,
    };

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        key: const Key('mentor_meetings_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          MentorPageHeader(
            title: context.l10n.mentorMeetingsTitle,
            subtitle: context.l10n.mentorMeetingsDescription,
          ),
          const SizedBox(height: AppSpacing.space3),

          // Tabs lọc trạng thái theo chuẩn Screen 16
          if (widget.meetings.isNotEmpty) ...[
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterTab(0, 'Tất cả (${widget.meetings.length})'),
                  const SizedBox(width: AppSpacing.space2),
                  _buildFilterTab(1, 'Chờ xác nhận ($assignedCount)'),
                  const SizedBox(width: AppSpacing.space2),
                  _buildFilterTab(2, 'Đã xác nhận ($acceptedCount)'),
                  const SizedBox(width: AppSpacing.space2),
                  _buildFilterTab(3, 'Đã học ($completedCount)'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.space4),
          ] else ...[
            const SizedBox(height: AppSpacing.space2),
          ],

          if (widget.meetings.isEmpty)
            MentorEmptyState(
              key: const Key('mentor_meetings_empty'),
              icon: Icons.video_call_outlined,
              title: context.l10n.mentorMeetingsTitle,
              description: context.l10n.mentorMeetingsEmpty,
            )
          else if (filteredMeetings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space5),
              child: Center(
                child: Text(
                  'Không có lịch học nào trong mục này.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            )
          else
            for (var index = 0; index < filteredMeetings.length; index++) ...[
              MentorMeetingCard(
                key: ValueKey<String>('mentor_meeting_${filteredMeetings[index].id}'),
                meeting: filteredMeetings[index],
                onTap: () => context.push(
                  AppRoutes.mentorMeetingDetail(filteredMeetings[index].id),
                ),
              ),
              if (index < filteredMeetings.length - 1)
                const SizedBox(height: AppSpacing.space3),
            ],
        ],
      ),
    );
  }

  Widget _buildFilterTab(int index, String label) {
    final isSelected = _selectedTabIndex == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: AppColors.brandTint,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.brandPrimary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        fontSize: 12,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.brandPrimary : AppColors.border,
      ),
      onSelected: (_) => setState(() => _selectedTabIndex = index),
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
