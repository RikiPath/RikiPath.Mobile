import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/mentor/application/mentor_controller.dart';
import 'package:rikipath_mobile/features/mentor/domain/mentor_dashboard.dart';
import 'package:rikipath_mobile/features/mentor/presentation/widgets/mentor_shared_widgets.dart';

class MentorAvailabilityScreen extends ConsumerWidget {
  const MentorAvailabilityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(mentorAvailabilityControllerProvider);
    return Scaffold(
      key: const Key('mentor_availability_screen'),
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(
        title: Text(context.l10n.mentorAvailabilityTitle),
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
            onRefresh: ref
                .read(mentorAvailabilityControllerProvider.notifier)
                .retry,
          ),
        },
      ),
    );
  }
}

class _AvailabilityList extends StatelessWidget {
  const _AvailabilityList({required this.slots, required this.onRefresh});

  final List<MentorAvailabilitySlot> slots;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context) {
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
          RikiInfoBanner(
            title: context.l10n.mentorAvailabilityReadOnlyTitle,
            message: context.l10n.mentorAvailabilityReadOnlyMessage,
          ),
          const SizedBox(height: AppSpacing.space4),
          if (slots.isEmpty)
            MentorEmptyState(
              key: const Key('mentor_availability_empty'),
              icon: Icons.event_available_outlined,
              title: context.l10n.mentorAvailabilityTitle,
              description: context.l10n.mentorAvailabilityEmpty,
            )
          else
            for (var index = 0; index < slots.length; index++) ...[
              MentorAvailabilityCard(
                key: ValueKey<String>('mentor_availability_$index'),
                slot: slots[index],
              ),
              if (index < slots.length - 1)
                const SizedBox(height: AppSpacing.space3),
            ],
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
