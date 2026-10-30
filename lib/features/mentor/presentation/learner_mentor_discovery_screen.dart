import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

/// Màn hình chọn Mentor hướng dẫn 1-1 (Screen 02 theo chuẩn Neo-Japoniste Sakura).
class LearnerMentorDiscoveryScreen extends ConsumerStatefulWidget {
  const LearnerMentorDiscoveryScreen({required this.planId, super.key});

  final int planId;

  @override
  ConsumerState<LearnerMentorDiscoveryScreen> createState() =>
      _LearnerMentorDiscoveryScreenState();
}

class _LearnerMentorDiscoveryScreenState
    extends ConsumerState<LearnerMentorDiscoveryScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedFilter = 'all';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(learnerMentorListControllerProvider);

    return Scaffold(
      key: const Key('learner_mentor_discovery_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        title: const Text('Chọn Mentor'),
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
            key: Key('learner_mentor_discovery_loading'),
          ),
          AsyncError() => Center(
            child: MentorErrorState(
              key: const Key('learner_mentor_discovery_error'),
              message: 'Không thể tải danh sách Mentor lúc này.',
              onRetry: ref
                  .read(learnerMentorListControllerProvider.notifier)
                  .retry,
            ),
          ),
          AsyncData(:final value) => _buildBody(value),
        },
      ),
    );
  }

  Widget _buildBody(List<BookableMentor> allMentors) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = allMentors.where((mentor) {
      final matchesQuery =
          query.isEmpty ||
          mentor.name.toLowerCase().contains(query) ||
          mentor.jlptLevels.any((l) => l.toLowerCase().contains(query));
      if (!matchesQuery) return false;

      if (_selectedFilter == 'n5_n4') {
        return mentor.jlptLevels.any(
          (l) => l.contains('N5') || l.contains('N4'),
        );
      } else if (_selectedFilter == 'n3') {
        return mentor.jlptLevels.any((l) => l.contains('N3'));
      } else if (_selectedFilter == 'n2_n1') {
        return mentor.jlptLevels.any(
          (l) => l.contains('N2') || l.contains('N1'),
        );
      }
      return true;
    }).toList();

    return Column(
      children: [
        // Thanh tìm kiếm và bộ lọc JLPT
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenHorizontal,
            vertical: AppSpacing.space3,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                key: const Key('learner_mentor_search_field'),
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Tìm theo tên Mentor...',
                  prefixIcon: const Icon(Icons.search, size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {});
                          },
                        )
                      : null,
                ),
              ),
              if (allMentors.any((mentor) => mentor.jlptLevels.isNotEmpty)) ...[
                const SizedBox(height: AppSpacing.space3),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('all', 'Tất cả'),
                      const SizedBox(width: AppSpacing.space2),
                      _buildFilterChip('n5_n4', 'JLPT N5–N4'),
                      const SizedBox(width: AppSpacing.space2),
                      _buildFilterChip('n3', 'JLPT N3'),
                      const SizedBox(width: AppSpacing.space2),
                      _buildFilterChip('n2_n1', 'JLPT N2–N1'),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),

        // Danh sách Mentor
        Expanded(
          child: RefreshIndicator(
            onRefresh: ref
                .read(learnerMentorListControllerProvider.notifier)
                .retry,
            child: filtered.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                    children: [
                      MentorEmptyState(
                        key: const Key('learner_mentor_discovery_empty'),
                        icon: Icons.person_search_outlined,
                        title: 'Chưa tìm thấy Mentor phù hợp',
                        description:
                            'Hãy thử tìm kiếm với từ khóa khác hoặc bỏ chọn bộ lọc.',
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.space4),
                    itemBuilder: (context, index) {
                      final mentor = filtered[index];
                      return _MentorDiscoveryCard(
                        mentor: mentor,
                        onViewProfile: () => context.push(
                          AppRoutes.learnerMentorProfile(
                            widget.planId,
                            mentor.id,
                          ),
                        ),
                        onSelectCalendar: () => context.push(
                          AppRoutes.learnerMentorAvailability(
                            widget.planId,
                            mentorId: mentor.id,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (_) => setState(() => _selectedFilter = value),
      selectedColor: AppColors.brandTint,
      labelStyle: TextStyle(
        color: isSelected ? AppColors.brandPrimary : AppColors.textSecondary,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppColors.brandPrimary : AppColors.border,
      ),
    );
  }
}

class _MentorDiscoveryCard extends StatelessWidget {
  const _MentorDiscoveryCard({
    required this.mentor,
    required this.onViewProfile,
    required this.onSelectCalendar,
  });

  final BookableMentor mentor;
  final VoidCallback onViewProfile;
  final VoidCallback onSelectCalendar;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      boxShadow: AppShadows.cardSoft,
      borderColor: AppColors.border,
      padding: const EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar container
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.brandTint,
                    foregroundImage: mentor.avatarUrl != null
                        ? NetworkImage(mentor.avatarUrl!)
                        : null,
                    child: Text(
                      mentor.name.isNotEmpty
                          ? mentor.name.substring(0, 1).toUpperCase()
                          : 'M',
                      style: AppTypography.sectionTitle.copyWith(
                        color: AppColors.brandPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            mentor.name,
                            style: AppTypography.cardTitle.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.space2,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.brandTint,
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                          child: Text(
                            'Mentor',
                            style: AppTypography.metadata.copyWith(
                              color: AppColors.brandPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space1),
                    if (mentor.headline?.isNotEmpty == true) ...[
                      Text(
                        mentor.headline!,
                        style: AppTypography.metadata.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.space2),
                    ],
                    if (mentor.jlptLevels.isNotEmpty)
                      Wrap(
                        spacing: AppSpacing.space2,
                        runSpacing: AppSpacing.space1,
                        children: [
                          for (final level in mentor.jlptLevels)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.space2,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceContainer,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.pill,
                                ),
                              ),
                              child: Text(
                                level,
                                style: AppTypography.metadata.copyWith(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.space4),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onViewProfile,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  child: const Text('Xem hồ sơ'),
                ),
              ),
              const SizedBox(width: AppSpacing.space3),
              Expanded(
                child: ElevatedButton(
                  onPressed: onSelectCalendar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                  ),
                  child: const Text('Xem lịch học'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
