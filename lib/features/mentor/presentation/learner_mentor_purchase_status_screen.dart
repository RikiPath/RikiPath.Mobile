import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/learner_mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/learner_mentor_meeting.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/learner_mentor_shared_widgets.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

class LearnerMentorPurchaseStatusScreen extends ConsumerStatefulWidget {
  const LearnerMentorPurchaseStatusScreen({
    required this.subscriptionId,
    super.key,
  });

  final int? subscriptionId;

  @override
  ConsumerState<LearnerMentorPurchaseStatusScreen> createState() =>
      _LearnerMentorPurchaseStatusScreenState();
}

class _LearnerMentorPurchaseStatusScreenState
    extends ConsumerState<LearnerMentorPurchaseStatusScreen> {
  Timer? _pollTimer;

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  void _syncPolling(bool shouldPoll) {
    if (!shouldPoll) {
      _pollTimer?.cancel();
      _pollTimer = null;
      return;
    }
    _pollTimer ??= Timer.periodic(const Duration(seconds: 8), (_) {
      final id = widget.subscriptionId;
      if (id == null || id <= 0 || !mounted) return;
      ref
          .read(learnerMentorPurchaseStatusControllerProvider(id).notifier)
          .poll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final id = widget.subscriptionId;
    if (id == null || id <= 0) {
      return _PurchaseStatusScaffold(
        child: MentorEmptyState(
          icon: Icons.receipt_long_outlined,
          title: context.l10n.learnerMentorPurchaseStatus,
          description: context.l10n.learnerMentorMeetingNotFound,
        ),
      );
    }
    final provider = learnerMentorPurchaseStatusControllerProvider(id);
    final state = ref.watch(provider);
    ref.listen(provider, (_, next) {
      _syncPolling(next.value?.paymentStatus == MentorPaymentStatus.pending);
    });
    return _PurchaseStatusScaffold(
      child: switch (state) {
        AsyncLoading() => const MentorListSkeleton(
          key: Key('learner_mentor_purchase_status_loading'),
        ),
        AsyncError() => Center(
          child: MentorErrorState(
            key: const Key('learner_mentor_purchase_status_error'),
            message: context.l10n.learnerMentorPurchaseStatusError,
            onRetry: ref.read(provider.notifier).refreshStatus,
          ),
        ),
        AsyncData(:final value) => _PurchaseStatusBody(
          status: value,
          onRefresh: ref.read(provider.notifier).refreshStatus,
        ),
      },
    );
  }
}

class _PurchaseStatusScaffold extends StatelessWidget {
  const _PurchaseStatusScaffold({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const Key('learner_mentor_purchase_status_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(title: Text(context.l10n.learnerMentorPurchaseStatus)),
      body: SafeArea(top: false, child: child),
    );
  }
}

class _PurchaseStatusBody extends StatelessWidget {
  const _PurchaseStatusBody({required this.status, required this.onRefresh});

  final MentorMeetingPurchaseStatus status;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const Key('learner_mentor_purchase_status_content'),
      padding: const EdgeInsets.all(AppSpacing.screenHorizontal),
      children: [
        RikiInfoBanner(message: context.l10n.learnerMentorStatusPolling),
        const SizedBox(height: AppSpacing.space4),
        RikiCard(
          boxShadow: AppShadows.cardSoft,
          borderColor: AppColors.border,
          child: Column(
            children: [
              LearnerMentorDetailRow(
                icon: Icons.workspace_premium_outlined,
                label: context.l10n.learnerMentorPlansTitle,
                value: status.planName,
              ),
              const Divider(),
              LearnerMentorDetailRow(
                icon: Icons.payments_outlined,
                label: context.l10n.learnerMentorPaymentLabel,
                value: learnerMentorPaymentStatusLabel(
                  status.paymentStatus,
                  context,
                ),
              ),
              const Divider(),
              LearnerMentorDetailRow(
                key: const Key('learner_mentor_sessions_usage'),
                icon: Icons.video_call_outlined,
                label: context.l10n.learnerMentorPlanSessions(
                  status.meetingSessionsIncluded,
                ),
                value: context.l10n.learnerMentorSessionsUsage(
                  status.meetingSessionsUsed,
                  status.meetingSessionsIncluded,
                ),
              ),
            ],
          ),
        ),
        if (status.isCheckoutExpired) ...[
          const SizedBox(height: AppSpacing.space4),
          RikiWarningBanner(message: context.l10n.learnerMentorCheckoutExpired),
        ],
        const SizedBox(height: AppSpacing.space4),
        RikiSecondaryButton(
          key: const Key('learner_mentor_refresh_purchase_status'),
          label: context.l10n.learnerMentorRefreshStatus,
          leadingIcon: Icons.refresh,
          onPressed: onRefresh,
        ),
      ],
    );
  }
}
