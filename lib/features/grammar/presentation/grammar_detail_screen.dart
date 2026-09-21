import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/features/grammar/application/grammar_controller.dart';
import 'package:rikipath_mobile/features/grammar/presentation/widgets/grammar_detail_view.dart';
import 'package:rikipath_mobile/features/grammar/presentation/widgets/grammar_state_views.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_header.dart';

class GrammarDetailScreen extends ConsumerWidget {
  const GrammarDetailScreen({required this.routeKey, super.key});

  final String routeKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = grammarDetailControllerProvider(routeKey);
    final state = ref.watch(provider);
    final controller = ref.read(provider.notifier);

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: LearningHeader.detail(
        title: context.l10n.grammarDetail,
        subtitle: state.value?.title ?? context.l10n.library,
        level: state.value?.level,
        initials: null,
        onBack: context.pop,
        onProfilePressed: () => context.go(AppRoutes.profile),
      ),
      body: SafeArea(
        top: false,
        child: state.when(
          loading: GrammarLoadingView.new,
          error: (_, _) => GrammarErrorView(onRetry: controller.retry),
          data: (entry) => GrammarDetailView(
            entry: entry,
            onOpenRelated: (related) =>
                context.push(AppRoutes.grammarDetail(related.routeKey)),
          ),
        ),
      ),
    );
  }
}
