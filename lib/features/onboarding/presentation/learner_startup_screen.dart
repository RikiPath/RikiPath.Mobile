import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_brand_lockup.dart';
import 'package:rikipath_mobile/core/widgets/riki_loading.dart';
import 'package:rikipath_mobile/core/widgets/riki_state_view.dart';
import 'package:rikipath_mobile/features/onboarding/application/learner_startup_controller.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_error_message.dart';

class LearnerStartupScreen extends ConsumerWidget {
  const LearnerStartupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destination = ref.watch(learnerStartupDestinationProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: destination.when(
        loading: () => RikiFullScreenLoader(
          key: const ValueKey<String>('learner_startup_loading'),
          title: context.l10n.preparingLearningContent,
          subtitle: context.l10n.preparingLearningSubtext,
          semanticsLabel: context.l10n.loading,
          header: const RikiBrandLockup(),
        ),
        error: (error, _) => SafeArea(
          child: RikiErrorState(
            key: const ValueKey<String>('learner_startup_error'),
            title: context.l10n.profileLoadFailedTitle,
            message: userProfileErrorMessage(error, context.l10n),
            actionLabel: context.l10n.retry,
            actionKey: const ValueKey<String>('learner_startup_retry'),
            onAction: () => ref.invalidate(learnerStartupDestinationProvider),
          ),
        ),
        data: (target) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            context.go(switch (target) {
              LearnerStartupDestination.onboarding => AppRoutes.onboarding,
              LearnerStartupDestination.placementTest =>
                AppRoutes.placementTest,
              LearnerStartupDestination.home => AppRoutes.home,
            });
          });
          return RikiFullScreenLoader(
            key: const ValueKey<String>('learner_startup_resolved'),
            title: context.l10n.preparingLearningContent,
            semanticsLabel: context.l10n.loading,
          );
        },
      ),
    );
  }
}
