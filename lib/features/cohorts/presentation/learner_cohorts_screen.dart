import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/cohorts/presentation/widgets/cohort_summary_facts.dart';
import 'package:rikipath_mobile/features/cohorts/application/cohort_controller.dart';
import 'package:rikipath_mobile/features/cohorts/domain/cohort_operations.dart';
import 'package:rikipath_mobile/features/cohorts/domain/study_cohort.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';
import 'package:url_launcher/url_launcher.dart';

class LearnerCohortsScreen extends ConsumerStatefulWidget {
  const LearnerCohortsScreen({super.key});

  @override
  ConsumerState<LearnerCohortsScreen> createState() =>
      _LearnerCohortsScreenState();
}

class _LearnerCohortsScreenState extends ConsumerState<LearnerCohortsScreen> {
  String _selectedLevel = 'ALL';
  final TextEditingController _searchController = TextEditingController();
  final Map<int, String> _idempotencyKeys = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) => DateFormat('dd/MM/yyyy HH:mm').format(dt);

  String _weekdayLabel(StudyCohortSummary cohort) {
    if (cohort.sessions.isEmpty) return 'Lịch cố định';
    final labels = <String>{
      for (final s in cohort.sessions) DateFormat('EEE').format(s.startTime),
    };
    return labels.join(', ');
  }

  bool _checkoutInFlight = false;

  String _formatPrice(num price) {
    final s = NumberFormat('#,##0', 'en_US').format(price).replaceAll(',', '.');
    return '$s đ';
  }

  Future<void> _confirmAndEnroll(StudyCohortSummary cohort) async {
    if (_checkoutInFlight) return;
    final byEntitlement = cohort.hasApprovedEntitlement;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Xác nhận ghi danh lớp ${cohort.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Cấp độ: ${cohort.level}'),
            const SizedBox(height: 4),
            Text(
              cohortIntensityText(cohort),
              key: const ValueKey('confirm_cohort_intensity'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              '${cohort.sessionMinutes ?? '—'} phút/buổi · ${cohort.totalSessions ?? cohort.sessions.length} buổi',
            ),
            const SizedBox(height: 4),
            Text(
              'Học phí trọn khóa: ${_formatPrice(cohort.price)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text('Số chỗ còn lại: ${cohort.seatsAvailable}/${cohort.capacity}'),
            const SizedBox(height: 4),
            Text('Mentor: ${cohort.mentorName}'),
            const SizedBox(height: 4),
            Text('Khai giảng: ${_formatDate(cohort.startsAt)}'),
            const SizedBox(height: 4),
            Text('Hạn đăng ký: ${_formatDate(cohort.enrollmentClosesAtUtc)}'),
            if (cohort.entitlementReference != null) ...[
              const SizedBox(height: 6),
              Text(
                'Mã quyền lớp nhóm: ${cohort.entitlementReference}',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.brandPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              byEntitlement
                  ? 'Ghi danh bằng quyền học'
                  : 'Thanh toán trọn khóa',
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _checkoutInFlight) return;

    _checkoutInFlight = true;
    final key = _idempotencyKeys[cohort.id] ??= generateClientIdempotencyKey();
    try {
      final result = await runWithAppLoadingOverlay<CohortCheckoutResult>(
        context,
        title: byEntitlement
            ? 'Đang ghi danh lớp nhóm...'
            : 'Đang tạo phiên thanh toán...',
        action: () => ref
            .read(learnerCohortDiscoveryProvider.notifier)
            .checkoutCohort(
              cohortId: cohort.id,
              idempotencyKey: key,
              entitlementReference: byEntitlement
                  ? cohort.entitlementReference
                  : null,
            ),
      );
      if (!mounted) return;
      final toasts = ref.read(rikiToastServiceProvider.notifier);
      if (result.isEnrolled) {
        toasts.success(title: 'Đã ghi danh');
      } else if (result.requiresPayment) {
        toasts.info(title: 'Đang chờ xác nhận thanh toán');
        await launchUrl(
          Uri.parse(result.checkoutUrl!),
          mode: LaunchMode.externalApplication,
        );
      } else {
        toasts.info(title: 'Đang chờ xác nhận thanh toán');
      }
      if (!mounted) return;
      if (result.courseId > 0) {
        await context.push(AppRoutes.learnerCohortDetail(result.courseId));
      } else {
        await context.push(AppRoutes.learnerMyCourses);
      }
    } catch (error) {
      if (!mounted) return;
      ref
          .read(rikiToastServiceProvider.notifier)
          .error(
            title: 'Chưa thể ghi danh',
            description: appErrorMessage(error, context.l10n),
          );
    } finally {
      _checkoutInFlight = false;
    }
  }

  static const List<(String?, String)> _intensityOptions = [
    (null, 'Tất cả'),
    ('Light', 'Nhẹ'),
    ('Standard', 'Tiêu chuẩn'),
    ('Advanced', 'Nâng cao'),
  ];

  // Backend weekday convention: 0 = Sunday … 6 = Saturday.
  static const List<(int?, String)> _weekdayOptions = [
    (null, 'Mọi ngày'),
    (1, 'T2'),
    (2, 'T3'),
    (3, 'T4'),
    (4, 'T5'),
    (5, 'T6'),
    (6, 'T7'),
    (0, 'CN'),
  ];

  static const List<(String?, String?, String)> _timeOptions = [
    (null, null, 'Mọi giờ'),
    ('06:00', '12:00', 'Sáng (6h–12h)'),
    ('12:00', '18:00', 'Chiều (12h–18h)'),
    ('18:00', '23:00', 'Tối (18h–23h)'),
  ];

  /// Mentors seen across every load, so the Mentor chips stay available
  /// after the list is narrowed by a server-side filter.
  final Map<int, String> _knownMentors = {};

  void _setFilter(CohortDiscoveryFilter filter) {
    ref.read(learnerCohortFilterProvider.notifier).setFilter(filter);
  }

  Widget _chipRow({
    required Key key,
    required String label,
    required List<Widget> chips,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: SingleChildScrollView(
        key: key,
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(
              width: 72,
              child: Text(
                label,
                style: AppTypography.metadata.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            for (final chip in chips) ...[chip, const SizedBox(width: 6)],
          ],
        ),
      ),
    );
  }

  Widget _chip({
    Key? key,
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    return ChoiceChip(
      key: key,
      label: Text(label),
      selected: selected,
      visualDensity: VisualDensity.compact,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      onSelected: (_) => onSelected(),
    );
  }

  Widget _buildFilters(CohortDiscoveryFilter filter) {
    final mentors = _knownMentors.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    return Column(
      key: const Key('learner_cohort_filters'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _chipRow(
          key: const Key('cohort_filter_level'),
          label: 'Cấp độ',
          chips: [
            for (final level in ['ALL', 'N5', 'N4', 'N3', 'N2'])
              _chip(
                label: level == 'ALL' ? 'Tất cả' : level,
                selected: _selectedLevel == level,
                onSelected: () {
                  setState(() => _selectedLevel = level);
                  _setFilter(
                    filter.copyWith(level: () => level == 'ALL' ? null : level),
                  );
                },
              ),
          ],
        ),
        _chipRow(
          key: const Key('cohort_filter_intensity'),
          label: 'Cường độ',
          chips: [
            for (final (value, label) in _intensityOptions)
              _chip(
                key: ValueKey('cohort_filter_intensity_${value ?? 'all'}'),
                label: label,
                selected: filter.intensity == value,
                onSelected: () =>
                    _setFilter(filter.copyWith(intensity: () => value)),
              ),
          ],
        ),
        _chipRow(
          key: const Key('cohort_filter_weekday'),
          label: 'Ngày học',
          chips: [
            for (final (value, label) in _weekdayOptions)
              _chip(
                label: label,
                selected: filter.weekday == value,
                onSelected: () =>
                    _setFilter(filter.copyWith(weekday: () => value)),
              ),
          ],
        ),
        _chipRow(
          key: const Key('cohort_filter_time'),
          label: 'Khung giờ',
          chips: [
            for (final (from, to, label) in _timeOptions)
              _chip(
                label: label,
                selected: filter.fromTime == from && filter.toTime == to,
                onSelected: () => _setFilter(
                  filter.copyWith(fromTime: () => from, toTime: () => to),
                ),
              ),
          ],
        ),
        if (mentors.isNotEmpty)
          _chipRow(
            key: const Key('cohort_filter_mentor'),
            label: 'Mentor',
            chips: [
              _chip(
                label: 'Tất cả',
                selected: filter.mentorId == null,
                onSelected: () =>
                    _setFilter(filter.copyWith(mentorId: () => null)),
              ),
              for (final m in mentors)
                _chip(
                  label: m.value,
                  selected: filter.mentorId == m.key,
                  onSelected: () =>
                      _setFilter(filter.copyWith(mentorId: () => m.key)),
                ),
            ],
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(learnerCohortDiscoveryProvider);
    final filter = ref.watch(learnerCohortFilterProvider);
    final query = _searchController.text.trim().toLowerCase();
    final data = state.value;
    for (final c in data?.cohorts ?? const <StudyCohortSummary>[]) {
      if (c.mentorId > 0 && c.mentorName.isNotEmpty) {
        _knownMentors[c.mentorId] = c.mentorName;
      }
    }

    return Scaffold(
      key: const Key('learner_cohorts_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        title: const Text('Lớp ôn JLPT theo nhóm'),
        actions: [
          TextButton.icon(
            key: const Key('learner_cohorts_to_my_courses_btn'),
            onPressed: () => context.push(AppRoutes.learnerMyCourses),
            icon: const Icon(Icons.school_outlined, size: 18),
            label: const Text('Lớp của tôi'),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: switch ((data, state)) {
          (null, AsyncError(:final error)) => Center(
            child: MentorErrorState(
              message: appErrorMessage(error, context.l10n),
              onRetry: ref
                  .read(learnerCohortDiscoveryProvider.notifier)
                  .refresh,
            ),
          ),
          (null, _) => const MentorListSkeleton(
            key: Key('learner_cohorts_loading'),
          ),
          (final CohortDiscoveryData value, _) => RefreshIndicator(
            onRefresh: ref
                .read(learnerCohortDiscoveryProvider.notifier)
                .refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              children: [
                if (state.isLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: LinearProgressIndicator(
                      key: Key('learner_cohorts_reloading'),
                    ),
                  ),
                RikiCard(
                  backgroundColor: AppColors.brandTint.withValues(alpha: 0.45),
                  borderColor: AppColors.brandPrimary.withValues(alpha: 0.2),
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quyền ghi danh lớp nhóm tách biệt hoàn toàn với vé tư vấn 1-1 (${value.entitlements.where((e) => e.isUsable).length} quyền khả dụng).',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (value.entitlements.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        for (final ent in value.entitlements)
                          Text(
                            '• Lớp #${ent.studyCohortId}: ${ent.entitlementReference} (${ent.status})',
                            style: AppTypography.metadata.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
                _buildFilters(filter),
                const SizedBox(height: AppSpacing.space2),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Tìm theo tên lớp, Mentor hoặc lịch học...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.space4),
                Builder(
                  builder: (context) {
                    final filtered = value.cohorts.where((c) {
                      if (_selectedLevel != 'ALL' &&
                          c.level != _selectedLevel) {
                        return false;
                      }
                      if (query.isEmpty) return true;
                      return c.name.toLowerCase().contains(query) ||
                          c.mentorName.toLowerCase().contains(query) ||
                          _weekdayLabel(c).toLowerCase().contains(query);
                    }).toList();

                    if (filtered.isEmpty) {
                      final hasFilters = !filter.isEmpty || query.isNotEmpty;
                      return Column(
                        key: const Key('learner_cohorts_empty'),
                        children: [
                          MentorEmptyState(
                            icon: Icons.groups_outlined,
                            title: hasFilters
                                ? 'Không có lớp khớp bộ lọc'
                                : 'Chưa có lớp ôn phù hợp',
                            description: hasFilters
                                ? 'Thử bỏ bớt điều kiện cường độ, ngày học, khung giờ hoặc Mentor. Lớp mới được mở thường xuyên theo lịch khai giảng.'
                                : 'Hiện chưa có lớp nào mở ghi danh. Hãy quay lại kiểm tra lịch khai giảng mới.',
                          ),
                          if (hasFilters)
                            TextButton.icon(
                              key: const Key('learner_cohorts_clear_filters'),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _selectedLevel = 'ALL');
                                ref
                                    .read(learnerCohortFilterProvider.notifier)
                                    .clear();
                              },
                              icon: const Icon(Icons.filter_alt_off_outlined),
                              label: const Text('Xóa bộ lọc'),
                            ),
                        ],
                      );
                    }

                    return Column(
                      children: [
                        for (final cohort in filtered) ...[
                          RikiCard(
                            key: ValueKey('cohort_card_${cohort.id}'),
                            backgroundColor: AppColors.cardWarmWhite,
                            borderColor: AppColors.cardBorderMuted,
                            padding: const EdgeInsets.all(AppSpacing.space4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CohortSummaryFacts(
                                  cohort: cohort,
                                  reviewLine: _CohortReviewSummaryLine(
                                    key: ValueKey(
                                      'cohort_review_summary_${cohort.id}',
                                    ),
                                    mentorId: cohort.mentorId,
                                  ),
                                ),
                                if (!cohort.hasApprovedEntitlement &&
                                    cohort.entitlementStatusMessage !=
                                        null) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    cohort.entitlementStatusMessage!,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 12),
                                if (cohort.myEnrollmentCourseId != null)
                                  RikiSecondaryButton(
                                    label:
                                        cohort.myEnrollmentPaymentState ==
                                            'AwaitingPayment'
                                        ? 'Tiếp tục thanh toán'
                                        : 'Vào lớp đang học',
                                    onPressed: () => context.push(
                                      AppRoutes.learnerCohortDetail(
                                        cohort.myEnrollmentCourseId!,
                                      ),
                                    ),
                                  )
                                else
                                  RikiPrimaryButton(
                                    key: ValueKey('enroll_cohort_${cohort.id}'),
                                    label: cohort.enrollmentOpen
                                        ? 'Đăng ký vào lớp'
                                        : 'Chưa mở ghi danh',
                                    onPressed: cohort.enrollmentOpen
                                        ? () => _confirmAndEnroll(cohort)
                                        : null,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.space3),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        },
      ),
    );
  }
}

/// "★ 4.6 · 12 đánh giá" from the public cohort review summary, or
/// "Chưa có đánh giá" when the Mentor has none yet. Failures stay silent:
/// the summary is informative only and must not block enrollment.
class _CohortReviewSummaryLine extends ConsumerWidget {
  const _CohortReviewSummaryLine({required this.mentorId, super.key});

  final int mentorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (mentorId <= 0) return const SizedBox.shrink();
    final summary = ref.watch(learnerMentorReviewSummaryProvider(mentorId));
    final style = AppTypography.metadata.copyWith(
      color: AppColors.textSecondary,
    );
    return switch (summary) {
      AsyncData(:final value) when value.hasReviews => Row(
        children: [
          const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
          const SizedBox(width: 2),
          Text(
            '${value.averageRating.toStringAsFixed(1)} · ${value.reviewCount} đánh giá lớp nhóm',
            style: style,
          ),
        ],
      ),
      AsyncData() => Text('Chưa có đánh giá', style: style),
      _ => const SizedBox(height: 16),
    };
  }
}
