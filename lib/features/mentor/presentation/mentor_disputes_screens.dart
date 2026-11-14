import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/router/navigation_helpers.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/network/safe_external_http_uri.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_operations_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_operations.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_parity_components.dart';
import 'package:url_launcher/url_launcher.dart';

enum _DisputeFilter { all, awaitingAction, resolvedOrClosed }

/// List of Mentor disputes (`/mentor/disputes`).
class MentorDisputesScreen extends ConsumerStatefulWidget {
  const MentorDisputesScreen({super.key});

  @override
  ConsumerState<MentorDisputesScreen> createState() =>
      _MentorDisputesScreenState();
}

class _MentorDisputesScreenState extends ConsumerState<MentorDisputesScreen> {
  _DisputeFilter _filter = _DisputeFilter.all;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final disputesAsync = ref.watch(mentorDisputesControllerProvider);
    final hasGoRouter = GoRouter.maybeOf(context) != null;
    final canPopRoute =
        GoRouter.maybeOf(context)?.canPop() ??
        (ModalRoute.of(context)?.canPop ?? true);

    return PopScope(
      canPop: canPopRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          popOrGo(context, AppRoutes.mentor);
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.learnerBackground,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          leading: hasGoRouter
              ? BackButton(
                  onPressed: () => popOrGo(context, AppRoutes.mentor),
                )
              : null,
          title: Text(l10n.mentorDisputesTitle),
        ),
      body: disputesAsync.when(
        loading: () => const Center(child: RikiAnimatedStudyLoader()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: RikiErrorState(
              title: l10n.mentorDisputesTitle,
              message: appErrorMessage(err, l10n),
              actionLabel: l10n.mentorCommonRetry,
              onAction: () =>
                  ref.read(mentorDisputesControllerProvider.notifier).refresh(),
            ),
          ),
        ),
        data: (disputes) {
          final filtered = switch (_filter) {
            _DisputeFilter.all => disputes,
            _DisputeFilter.awaitingAction => disputes
                .where((d) => !d.status.isTerminal)
                .toList(growable: false),
            _DisputeFilter.resolvedOrClosed => disputes
                .where((d) => d.status.isTerminal)
                .toList(growable: false),
          };

          return RefreshIndicator(
            color: AppColors.brandPrimary,
            onRefresh: () =>
                ref.read(mentorDisputesControllerProvider.notifier).refresh(),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              children: [
                Wrap(
                  spacing: AppSpacing.space2,
                  children: [
                    ChoiceChip(
                      label: Text(l10n.mentorMeetingsFilterAll),
                      selected: _filter == _DisputeFilter.all,
                      onSelected: (_) =>
                          setState(() => _filter = _DisputeFilter.all),
                    ),
                    ChoiceChip(
                      label: Text(l10n.mentorHomeMetricOpenDisputes),
                      selected: _filter == _DisputeFilter.awaitingAction,
                      onSelected: (_) => setState(
                        () => _filter = _DisputeFilter.awaitingAction,
                      ),
                    ),
                    ChoiceChip(
                      label: Text(l10n.mentorMeetingsFilterCompleted),
                      selected: _filter == _DisputeFilter.resolvedOrClosed,
                      onSelected: (_) => setState(
                        () => _filter = _DisputeFilter.resolvedOrClosed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.space3),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.space6),
                    child: RikiEmptyState(
                      icon: Icons.gavel_outlined,
                      title: l10n.mentorDisputesTitle,
                      message: l10n.mentorDisputesEmpty,
                    ),
                  )
                else
                  for (final dispute in filtered) ...[
                    _DisputeSummaryCard(
                      dispute: dispute,
                      onTap: () =>
                          context.push(AppRoutes.mentorDisputeDetail(dispute.id)),
                    ),
                    const SizedBox(height: AppSpacing.space3),
                  ],
                const SizedBox(height: AppSpacing.space6),
              ],
            ),
          );
        },
      ),
      ),
    );
  }
}

class _DisputeSummaryCard extends StatelessWidget {
  const _DisputeSummaryCard({required this.dispute, required this.onTap});

  final MentorDisputeItem dispute;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: RikiCard(
          backgroundColor: AppColors.cardWarmWhite,
          borderColor: AppColors.cardBorderMuted,
          boxShadow: AppShadows.sakuraSubtle,
          padding: const EdgeInsets.all(AppSpacing.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${dispute.id} · ${dispute.learnerName}',
                      style: AppTypography.cardTitle,
                    ),
                  ),
                  MentorStatusBadge(
                    label: mentorDisputeStatusLabel(dispute.status),
                    color: mentorDisputeStatusColor(dispute.status),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: AppSpacing.space2,
                runSpacing: 4,
                children: [
                  MentorStatusBadge(
                    label: mentorDisputeCategoryLabel(dispute.category),
                    color: AppColors.textSecondary,
                  ),
                  MentorStatusBadge(
                    label: 'Buổi tư vấn #${dispute.mentorBookingId}',
                    color: AppColors.brandPrimary,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(
                dispute.reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.space2),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      formatShortDateTime(dispute.createdAtUtc),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  if (dispute.canSubmitResponse) ...[
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        l10n.mentorMeetingRespondDisputeButton,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.brandPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Detailed Dispute inspection, attendance telemetry, evidence links, history
/// timeline, and one-time Mentor response submission (`/mentor/disputes/:disputeId`).
class MentorDisputeDetailScreen extends ConsumerStatefulWidget {
  const MentorDisputeDetailScreen({required this.disputeId, super.key});

  final int? disputeId;

  @override
  ConsumerState<MentorDisputeDetailScreen> createState() =>
      _MentorDisputeDetailScreenState();
}

class _MentorDisputeDetailScreenState
    extends ConsumerState<MentorDisputeDetailScreen> {
  final TextEditingController _responseController = TextEditingController();
  static const int _maxResponseLength = 2000;
  bool _hasDraftResponse = false;

  @override
  void initState() {
    super.initState();
    _responseController.addListener(_syncDraftResponse);
  }

  void _syncDraftResponse() {
    final dirty = _responseController.text.trim().isNotEmpty;
    if (dirty != _hasDraftResponse && mounted) {
      setState(() => _hasDraftResponse = dirty);
    }
  }

  @override
  void dispose() {
    _responseController.removeListener(_syncDraftResponse);
    _responseController.dispose();
    super.dispose();
  }

  Future<void> _openEvidenceUrl(String rawUrl) async {
    final l10n = context.l10n;
    final uri = parseSafeExternalHttpUri(rawUrl);
    if (uri == null) {
      ref.read(rikiToastServiceProvider.notifier).warning(
        title: l10n.toastActionFailedTitle,
        description: rawUrl,
      );
      return;
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && mounted) {
      ref.read(rikiToastServiceProvider.notifier).error(
        title: l10n.toastActionFailedTitle,
        description: rawUrl,
      );
    }
  }

  Future<void> _submitResponse(int disputeId) async {
    final l10n = context.l10n;
    final trimmed = _responseController.text.trim();
    if (trimmed.isEmpty || trimmed.length > _maxResponseLength) return;

    final ok = await runWithAppLoadingOverlay<bool>(
      context,
      title: l10n.loadingOverlaySubmittingTitle,
      action: () => ref
          .read(mentorMeetingsControllerProvider.notifier)
          .respondDispute(disputeId, trimmed),
    );
    if (!mounted) return;
    if (ok) {
      _responseController.clear();
      ref.invalidate(mentorDisputeDetailProvider(disputeId));
      ref.invalidate(mentorDisputesControllerProvider);
      ref.read(rikiToastServiceProvider.notifier).success(
        title: l10n.mentorDisputesTitle,
        description: l10n.mentorDisputeYourResponse,
      );
    } else {
      ref.read(rikiToastServiceProvider.notifier).error(
        title: l10n.toastActionFailedTitle,
        description: l10n.commonErrorServer,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final id = widget.disputeId;
    final hasGoRouter = GoRouter.maybeOf(context) != null;
    if (id == null || id <= 0) {
      final canPopInvalid =
          GoRouter.maybeOf(context)?.canPop() ??
          (ModalRoute.of(context)?.canPop ?? true);
      return PopScope(
        canPop: canPopInvalid,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) {
            popOrGo(context, AppRoutes.mentorDisputes);
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.learnerBackground,
          appBar: AppBar(
            leading: hasGoRouter
                ? BackButton(
                    onPressed: () => popOrGo(context, AppRoutes.mentorDisputes),
                  )
                : null,
            title: Text(l10n.mentorDisputesTitle),
          ),
          body: Center(
            child: RikiEmptyState(
              icon: Icons.gavel_outlined,
              title: l10n.mentorDisputesTitle,
              message: l10n.mentorDisputesEmpty,
            ),
          ),
        ),
      );
    }

    final detailAsync = ref.watch(mentorDisputeDetailProvider(id));
    final canSubmitResponse =
        detailAsync.value?.dispute.canSubmitResponse ?? false;
    final hasUnsavedChanges = _hasDraftResponse && canSubmitResponse;
    final canPopRoute =
        !hasUnsavedChanges &&
        (GoRouter.maybeOf(context)?.canPop() ??
            (ModalRoute.of(context)?.canPop ?? true));

    return PopScope(
      canPop: canPopRoute,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          handleProtectedBackNavigation(
            context: context,
            hasUnsavedChanges: hasUnsavedChanges,
            fallbackRoute: AppRoutes.mentorDisputes,
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.learnerBackground,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          leading: (hasGoRouter || hasUnsavedChanges)
              ? BackButton(
                  onPressed: () => handleProtectedBackNavigation(
                    context: context,
                    hasUnsavedChanges: hasUnsavedChanges,
                    fallbackRoute: AppRoutes.mentorDisputes,
                  ),
                )
              : null,
          title: Text(l10n.mentorDisputeDetailTitle(id)),
        ),
      body: detailAsync.when(
        loading: () => const Center(child: RikiAnimatedStudyLoader()),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
            child: RikiErrorState(
              title: l10n.mentorDisputeDetailTitle(id),
              message: appErrorMessage(err, l10n),
              actionLabel: l10n.mentorCommonRetry,
              onAction: () => ref.invalidate(mentorDisputeDetailProvider(id)),
            ),
          ),
        ),
        data: (detail) {
          final dispute = detail.dispute;
          final attendanceAsync = ref.watch(
            mentorBookingAttendanceProvider(dispute.mentorBookingId),
          );
          final evidenceUrls = dispute.evidenceUrlList;
          final trimmedResponse = _responseController.text.trim();
          final canSend =
              trimmedResponse.isNotEmpty &&
              trimmedResponse.length <= _maxResponseLength;

          return RefreshIndicator(
            color: AppColors.brandPrimary,
            onRefresh: () async {
              ref.invalidate(mentorDisputeDetailProvider(id));
              await ref.read(mentorDisputeDetailProvider(id).future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
              children: [
                RikiCard(
                  backgroundColor: AppColors.surface,
                  borderColor: AppColors.cardBorderMuted,
                  boxShadow: AppShadows.sakuraSubtle,
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${dispute.learnerName} · #${dispute.mentorBookingId}',
                              style: AppTypography.cardTitle,
                            ),
                          ),
                          MentorStatusBadge(
                            label: mentorDisputeStatusLabel(dispute.status),
                            color: mentorDisputeStatusColor(dispute.status),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      MentorStatusBadge(
                        label: mentorDisputeCategoryLabel(dispute.category),
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: AppSpacing.space3),
                      Text(
                        l10n.mentorDisputeLearnerReason,
                        style: AppTypography.caption.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(dispute.reason, style: AppTypography.bodyMedium),
                      const SizedBox(height: AppSpacing.space3),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${l10n.mentorStartTimeLabel}: '
                              '${formatShortDateTime(detail.bookingScheduledAt)}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          TextButton(
                            onPressed: () => context.push(
                              AppRoutes.mentorMeetingDetail(
                                dispute.mentorBookingId,
                              ),
                            ),
                            child: Text(l10n.detail),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
                if (evidenceUrls.isNotEmpty) ...[
                  RikiCard(
                    backgroundColor: AppColors.cardWarmWhite,
                    borderColor: AppColors.cardBorderMuted,
                    padding: const EdgeInsets.all(AppSpacing.space4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.mentorDisputeEvidenceTitle,
                          style: AppTypography.cardTitle,
                        ),
                        const SizedBox(height: AppSpacing.space2),
                        for (final url in evidenceUrls)
                          Material(
                            type: MaterialType.transparency,
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              leading: const Icon(
                                Icons.link_rounded,
                                color: AppColors.brandPrimary,
                              ),
                              title: Text(
                                url,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.brandPrimary,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                              onTap: () => _openEvidenceUrl(url),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                ],
                RikiCard(
                  backgroundColor: AppColors.cardWarmWhite,
                  borderColor: AppColors.cardBorderMuted,
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.mentorDisputeAttendanceEvidence,
                        style: AppTypography.cardTitle,
                      ),
                      const SizedBox(height: AppSpacing.space2),
                      Wrap(
                        spacing: AppSpacing.space3,
                        runSpacing: 6,
                        children: [
                          Text(
                            formatDurationCompact(
                              detail.attendanceTotalDurationSeconds,
                            ),
                            style: AppTypography.bodySmall.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Reconnects: ${detail.attendanceReconnectionCount}',
                            style: AppTypography.bodySmall,
                          ),
                          if (detail.attendanceFirstJoinedAtUtc != null)
                            Text(
                              formatShortDateTime(
                                detail.attendanceFirstJoinedAtUtc,
                              ),
                              style: AppTypography.bodySmall,
                            ),
                        ],
                      ),
                      if (detail.isCancelled &&
                          (detail.cancellationReason?.trim().isNotEmpty ??
                              false)) ...[
                        const SizedBox(height: AppSpacing.space2),
                        Text(
                          '${detail.cancelledByRole ?? ''}: ${detail.cancellationReason}',
                          style: AppTypography.caption.copyWith(
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.space3),
                attendanceAsync.when(
                  data: (records) => MentorAttendanceListCard(records: records),
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                if (attendanceAsync.hasValue)
                  const SizedBox(height: AppSpacing.space3),
                if ((dispute.adminDecision?.trim().isNotEmpty ?? false) ||
                    (dispute.adminNotes?.trim().isNotEmpty ?? false)) ...[
                  RikiCard(
                    backgroundColor: AppColors.surface,
                    borderColor: AppColors.cardBorderMuted,
                    padding: const EdgeInsets.all(AppSpacing.space4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.mentorDisputeAdminDecision,
                          style: AppTypography.cardTitle,
                        ),
                        if (dispute.adminDecision?.trim().isNotEmpty ?? false) ...[
                          const SizedBox(height: AppSpacing.space2),
                          Text(
                            dispute.adminDecision!,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (dispute.adminNotes?.trim().isNotEmpty ?? false) ...[
                          const SizedBox(height: 4),
                          Text(
                            dispute.adminNotes!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.space3),
                ],
                RikiCard(
                  backgroundColor: AppColors.surface,
                  borderColor: AppColors.cardBorderMuted,
                  padding: const EdgeInsets.all(AppSpacing.space4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.mentorDisputeYourResponse,
                        style: AppTypography.cardTitle,
                      ),
                      const SizedBox(height: AppSpacing.space3),
                      if (dispute.hasMentorResponded) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppSpacing.space3),
                          decoration: BoxDecoration(
                            color: AppColors.brandTint,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dispute.mentorResponse!,
                                style: AppTypography.bodyMedium,
                              ),
                              if (dispute.mentorRespondedAtUtc != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  formatShortDateTime(
                                    dispute.mentorRespondedAtUtc,
                                  ),
                                  style: AppTypography.caption.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space2),
                        RikiInfoBanner(message: l10n.mentorDisputeLockedNotice),
                      ] else if (!dispute.canSubmitResponse) ...[
                        RikiInfoBanner(message: l10n.mentorDisputeLockedNotice),
                      ] else ...[
                        TextField(
                          controller: _responseController,
                          minLines: 4,
                          maxLines: 6,
                          maxLength: _maxResponseLength,
                          onChanged: (_) => setState(() {}),
                          decoration: InputDecoration(
                            hintText: l10n.mentorDisputeResponseHint,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(AppRadius.md),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.space3),
                        SizedBox(
                          width: double.infinity,
                          child: RikiPrimaryButton(
                            label: l10n.mentorDisputeSubmitResponse,
                            onPressed: canSend
                                ? () => _submitResponse(dispute.id)
                                : null,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (detail.histories.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.space3),
                  RikiCard(
                    backgroundColor: AppColors.cardWarmWhite,
                    borderColor: AppColors.cardBorderMuted,
                    padding: const EdgeInsets.all(AppSpacing.space4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.mentorDisputeTimelineTitle,
                          style: AppTypography.cardTitle,
                        ),
                        const SizedBox(height: AppSpacing.space3),
                        for (final entry in detail.histories) ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.circle,
                                size: 10,
                                color: AppColors.brandPrimary,
                              ),
                              const SizedBox(width: AppSpacing.space2),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${mentorDisputeHistoryActionLabel(entry.action, entry.newStatus)} · '
                                      '${mentorDisputeStatusLabel(entry.newStatus)}',
                                      style: AppTypography.bodySmall.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    if (entry.notes?.trim().isNotEmpty ?? false)
                                      Text(
                                        entry.notes!,
                                        style: AppTypography.caption.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    Text(
                                      '${entry.actorRole} · '
                                      '${formatShortDateTime(entry.createdAtUtc)}',
                                      style: AppTypography.caption.copyWith(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.space2),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.space6),
              ],
            ),
          );
        },
      ),
      ),
    );
  }
}
