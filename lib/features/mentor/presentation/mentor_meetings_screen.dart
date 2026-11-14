import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/core/widgets/sakura_app_header.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_parity_components.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

enum _MeetingFilterTab { all, upcoming, completed, cancelled }

enum _MeetingSortMode { schedule, newest }

class MentorMeetingsScreen extends ConsumerWidget {
  const MentorMeetingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingsState = ref.watch(mentorMeetingsControllerProvider);

    return Scaffold(
      key: const Key('mentor_meetings_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: SakuraAppHeader(
        showStreak: false,
        calendarTooltip: 'Lịch giảng dạy',
        onNotificationsPressed: () =>
            mentorNavigate(context, AppRoutes.notifications),
        onCalendarPressed: () =>
            mentorNavigate(context, AppRoutes.mentorCalendar),
      ),
      bottomNavigationBar: MentorShellScope.hasShell(context)
          ? null
          : const MentorBottomNavigationBar(selectedIndex: 2),
      body: SafeArea(
        top: false,
        child: switch (meetingsState) {
          AsyncLoading() => const Padding(
            padding: EdgeInsets.all(AppSpacing.screenHorizontal),
            child: MentorListSkeleton(key: Key('mentor_meetings_loading')),
          ),
          AsyncError() => _RefreshableMeetingBody(
            onRefresh: () =>
                ref.read(mentorMeetingsControllerProvider.notifier).retry(),
            child: MentorErrorState(
              key: const Key('mentor_meetings_error'),
              message: context.l10n.mentorMeetingsError,
              onRetry: ref
                  .read(mentorMeetingsControllerProvider.notifier)
                  .retry,
            ),
          ),
          AsyncData(:final value) => _MeetingList(
            meetings: value,
            onRefresh: () =>
                ref.read(mentorMeetingsControllerProvider.notifier).retry(),
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
  final TextEditingController _searchController = TextEditingController();
  _MeetingFilterTab _selectedTab = _MeetingFilterTab.all;
  _MeetingSortMode _sortMode = _MeetingSortMode.schedule;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MentorMeetingSummary> _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    final tabFiltered = switch (_selectedTab) {
      _MeetingFilterTab.all => widget.meetings,
      _MeetingFilterTab.upcoming => widget.meetings.where(
          (m) =>
              m.status == MentorMeetingStatus.assigned ||
              m.status == MentorMeetingStatus.accepted ||
              m.status == MentorMeetingStatus.pendingAssignment,
        ),
      _MeetingFilterTab.completed => widget.meetings.where(
          (m) => m.status == MentorMeetingStatus.completed,
        ),
      _MeetingFilterTab.cancelled => widget.meetings.where(
          (m) => m.status == MentorMeetingStatus.cancelled,
        ),
    };

    final searched = tabFiltered.where((m) {
      if (query.isEmpty) return true;
      final hay = [
        m.learnerName ?? '',
        '#${m.id}',
        '${m.id}',
        m.jlptLevel ?? '',
        m.question ?? '',
      ].join(' ').toLowerCase();
      return hay.contains(query);
    }).toList();

    searched.sort((a, b) {
      if (_sortMode == _MeetingSortMode.newest) {
        return b.id.compareTo(a.id);
      }
      final aTime = a.scheduledAt?.value;
      final bTime = b.scheduledAt?.value;
      if (aTime == null && bTime == null) return b.id.compareTo(a.id);
      if (aTime == null) return 1;
      if (bTime == null) return -1;
      return aTime.compareTo(bTime);
    });

    return searched;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final upcomingCount = widget.meetings
        .where(
          (m) =>
              m.status == MentorMeetingStatus.assigned ||
              m.status == MentorMeetingStatus.accepted ||
              m.status == MentorMeetingStatus.pendingAssignment,
        )
        .length;
    final completedCount = widget.meetings
        .where((m) => m.status == MentorMeetingStatus.completed)
        .length;
    final cancelledCount = widget.meetings
        .where((m) => m.status == MentorMeetingStatus.cancelled)
        .length;

    final filteredMeetings = _applyFilters();

    return RefreshIndicator(
      color: AppColors.brandPrimary,
      onRefresh: widget.onRefresh,
      child: ListView(
        key: const Key('mentor_meetings_list'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
        children: [
          MentorPageHeader(
            title: l10n.mentorMeetingsTitle,
            subtitle: l10n.mentorMeetingsDescription,
          ),
          const SizedBox(height: AppSpacing.space3),
          if (widget.meetings.isNotEmpty) ...[
            TextField(
              key: const Key('mentor_meetings_search_input'),
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                isDense: true,
                hintText: l10n.mentorMeetingsSearchHint,
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () => setState(_searchController.clear),
                        icon: const Icon(Icons.close),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.space3),
            Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterTab(
                          _MeetingFilterTab.all,
                          '${l10n.mentorMeetingsFilterAll} (${widget.meetings.length})',
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        _buildFilterTab(
                          _MeetingFilterTab.upcoming,
                          '${l10n.mentorMeetingsFilterUpcoming} ($upcomingCount)',
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        _buildFilterTab(
                          _MeetingFilterTab.completed,
                          '${l10n.mentorMeetingsFilterCompleted} ($completedCount)',
                        ),
                        const SizedBox(width: AppSpacing.space2),
                        _buildFilterTab(
                          _MeetingFilterTab.cancelled,
                          '${l10n.mentorMeetingsFilterCancelled} ($cancelledCount)',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.space2),
                ActionChip(
                  avatar: const Icon(
                    Icons.swap_vert_rounded,
                    size: 16,
                    color: AppColors.brandPrimary,
                  ),
                  label: Text(
                    _sortMode == _MeetingSortMode.schedule
                        ? l10n.mentorMeetingsSortSchedule
                        : l10n.mentorMeetingsSortNewest,
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _sortMode = _sortMode == _MeetingSortMode.schedule
                          ? _MeetingSortMode.newest
                          : _MeetingSortMode.schedule;
                    });
                  },
                ),
              ],
            ),
            if (_selectedTab == _MeetingFilterTab.cancelled &&
                cancelledCount == 0) ...[
              const SizedBox(height: AppSpacing.space3),
              RikiInfoBanner(message: l10n.mentorMeetingsCancelledApiNotice),
            ],
            const SizedBox(height: AppSpacing.space4),
          ] else ...[
            const SizedBox(height: AppSpacing.space2),
          ],
          if (widget.meetings.isEmpty)
            MentorEmptyState(
              key: const Key('mentor_meetings_empty'),
              icon: Icons.video_call_outlined,
              title: l10n.mentorMeetingsTitle,
              description: l10n.mentorMeetingsEmpty,
            )
          else if (filteredMeetings.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.space5),
              child: Center(
                child: Text(
                  l10n.mentorMeetingsFilterEmpty,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            )
          else
            for (var index = 0; index < filteredMeetings.length; index++) ...[
              _EnhancedMeetingListTile(
                key: ValueKey<String>(
                  'mentor_meeting_${filteredMeetings[index].id}',
                ),
                meeting: filteredMeetings[index],
                onTap: () => context.push(
                  AppRoutes.mentorMeetingDetail(filteredMeetings[index].id),
                ),
                onOpenPrep: () => context.push(
                  AppRoutes.mentorMeetingPrep(filteredMeetings[index].id),
                ),
              ),
              if (index < filteredMeetings.length - 1)
                const SizedBox(height: AppSpacing.space3),
            ],
        ],
      ),
    );
  }

  Widget _buildFilterTab(_MeetingFilterTab tab, String label) {
    final isSelected = _selectedTab == tab;
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
      onSelected: (_) => setState(() => _selectedTab = tab),
    );
  }
}

class _EnhancedMeetingListTile extends StatelessWidget {
  const _EnhancedMeetingListTile({
    required this.meeting,
    required this.onTap,
    required this.onOpenPrep,
    super.key,
  });

  final MentorMeetingSummary meeting;
  final VoidCallback onTap;
  final VoidCallback onOpenPrep;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasExtraContext =
        meeting.jlptLevel != null ||
        (meeting.question?.trim().isNotEmpty ?? false) ||
        meeting.status == MentorMeetingStatus.accepted ||
        meeting.status == MentorMeetingStatus.assigned;

    if (!hasExtraContext) {
      return MentorMeetingCard(meeting: meeting, onTap: onTap);
    }

    return MentorMeetingCard(
      meeting: meeting,
      onTap: onTap,
      footer: Row(
        children: [
          if (meeting.jlptLevel != null) ...[
            MentorStatusBadge(
              label: meeting.jlptLevel!,
              color: AppColors.brandPrimary,
            ),
            const SizedBox(width: AppSpacing.space2),
          ],
          if (meeting.question?.trim().isNotEmpty ?? false)
            Expanded(
              child: Text(
                meeting.question!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.caption.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            )
          else
            const Spacer(),
          if (meeting.status == MentorMeetingStatus.accepted ||
              meeting.status == MentorMeetingStatus.assigned)
            TextButton.icon(
              style: TextButton.styleFrom(
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.space2,
                  vertical: 4,
                ),
                minimumSize: Size.zero,
              ),
              onPressed: onOpenPrep,
              icon: const Icon(Icons.checklist_rtl_rounded, size: 16),
              label: Text(l10n.mentorActionSessionPrep),
            ),
        ],
      ),
    );
  }
}

class _RefreshableMeetingBody extends StatelessWidget {
  const _RefreshableMeetingBody({
    required this.onRefresh,
    required this.child,
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
