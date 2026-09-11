import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/features/home/application/home_controller.dart';
import 'package:rikipath_mobile/features/home/presentation/widgets/home_dashboard_view.dart';
import 'package:rikipath_mobile/features/home/presentation/widgets/home_header.dart';
import 'package:rikipath_mobile/features/home/presentation/widgets/home_loading_view.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(homeControllerProvider);
    final dashboard = dashboardState.asData?.value;

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: HomeHeader(
        level: dashboard?.jlptTarget,
        streakDays: dashboard?.streakDays,
        hasUnreadNotifications: dashboard?.hasUnreadNotifications ?? false,
        initials: dashboard?.initials,
        onProfilePressed: () => context.go(AppRoutes.profile),
      ),
      body: SafeArea(
        top: false,
        child: dashboardState.when(
          loading: () => const HomeLoadingView(),
          error: (_, _) => HomeErrorView(
            onRetry: ref.read(homeControllerProvider.notifier).retry,
          ),
          data: (data) => HomeDashboardView(
            dashboard: data,
            onOpenLearning: () => context.go(AppRoutes.learn),
            onOpenNotebook: () => context.go(AppRoutes.notebook),
            onOpenPractice: () => context.go(AppRoutes.practice),
          ),
        ),
      ),
    );
  }
}
