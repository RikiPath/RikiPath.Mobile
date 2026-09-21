import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_card.dart';
import 'package:rikipath_mobile/core/widgets/riki_loading.dart';

class HomeLoadingView extends StatelessWidget {
  const HomeLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return RikiShimmer(
      semanticsLabel: context.l10n.loading,
      child: ListView(
        key: const ValueKey<String>('home_loading_view'),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space4,
          AppSpacing.space4,
          AppSpacing.space4,
          AppSpacing.space8,
        ),
        children: const [
          _SkeletonLine(widthFactor: 0.5, height: 24),
          SizedBox(height: AppSpacing.space2),
          _SkeletonLine(widthFactor: 0.72),
          SizedBox(height: AppSpacing.space5),
          _SkeletonCard(lines: 4, action: true),
          SizedBox(height: AppSpacing.space4),
          _SkeletonCard(lines: 3, split: true),
          SizedBox(height: AppSpacing.space4),
          _SkeletonRecommendationCard(),
          SizedBox(height: AppSpacing.space5),
          _SkeletonLine(widthFactor: 0.45, height: 20),
          SizedBox(height: AppSpacing.space3),
          Row(
            children: [
              Expanded(child: _SkeletonPracticeCard()),
              SizedBox(width: AppSpacing.space3),
              Expanded(child: _SkeletonPracticeCard()),
              SizedBox(width: AppSpacing.space3),
              Expanded(child: _SkeletonPracticeCard()),
            ],
          ),
          SizedBox(height: AppSpacing.space5),
          _SkeletonLine(widthFactor: 0.52, height: 20),
          SizedBox(height: AppSpacing.space3),
          _SkeletonActivityCard(),
        ],
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard({
    required this.lines,
    this.action = false,
    this.split = false,
  });

  final int lines;
  final bool action;
  final bool split;

  @override
  Widget build(BuildContext context) {
    return RikiCard(
      borderColor: AppColors.learnerOutline,
      boxShadow: const <BoxShadow>[],
      padding: const EdgeInsets.all(AppSpacing.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SkeletonLine(widthFactor: 0.55, height: 20),
          const SizedBox(height: AppSpacing.space4),
          if (split)
            const Row(
              children: [
                Expanded(child: _SkeletonBlock(height: 72)),
                SizedBox(width: AppSpacing.space3),
                Expanded(child: _SkeletonBlock(height: 72)),
              ],
            )
          else
            for (var index = 0; index < lines; index++) ...[
              _SkeletonLine(widthFactor: index.isEven ? 0.9 : 0.68),
              const SizedBox(height: AppSpacing.space2),
            ],
          if (action) ...[
            const SizedBox(height: AppSpacing.space4),
            const _SkeletonBlock(height: 48),
          ],
        ],
      ),
    );
  }
}

class _SkeletonRecommendationCard extends StatelessWidget {
  const _SkeletonRecommendationCard();

  @override
  Widget build(BuildContext context) {
    return const RikiCard(
      backgroundColor: AppColors.learnerSurface,
      borderColor: AppColors.learnerSurfaceHigh,
      boxShadow: <BoxShadow>[],
      padding: EdgeInsets.all(AppSpacing.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonLine(widthFactor: 0.74, height: 20),
          SizedBox(height: AppSpacing.space3),
          _SkeletonBlock(height: 92),
          SizedBox(height: AppSpacing.space3),
          _SkeletonBlock(height: 68),
          SizedBox(height: AppSpacing.space2),
          _SkeletonBlock(height: 68),
          SizedBox(height: AppSpacing.space3),
          Align(
            alignment: Alignment.centerRight,
            child: _SkeletonBlock(width: 124, height: 36),
          ),
        ],
      ),
    );
  }
}

class _SkeletonPracticeCard extends StatelessWidget {
  const _SkeletonPracticeCard();

  @override
  Widget build(BuildContext context) {
    return const RikiCard(
      borderColor: AppColors.learnerOutline,
      padding: EdgeInsets.all(AppSpacing.space3),
      boxShadow: <BoxShadow>[],
      child: Column(
        children: [
          _SkeletonBlock(width: 46, height: 46),
          SizedBox(height: AppSpacing.space3),
          _SkeletonLine(widthFactor: 0.74),
          SizedBox(height: AppSpacing.space2),
          _SkeletonLine(widthFactor: 0.52),
        ],
      ),
    );
  }
}

class _SkeletonActivityCard extends StatelessWidget {
  const _SkeletonActivityCard();

  @override
  Widget build(BuildContext context) {
    return const RikiCard(
      borderColor: AppColors.learnerOutline,
      boxShadow: <BoxShadow>[],
      padding: EdgeInsets.all(AppSpacing.space4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SkeletonBlock(width: 36, height: 36),
              SizedBox(width: AppSpacing.space3),
              Expanded(child: _SkeletonLine(widthFactor: 0.72, height: 18)),
              SizedBox(width: AppSpacing.space3),
              _SkeletonBlock(width: 64, height: 28),
            ],
          ),
          SizedBox(height: AppSpacing.space2),
          _SkeletonLine(widthFactor: 0.58),
          SizedBox(height: AppSpacing.space2),
          _SkeletonBlock(height: 6),
        ],
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.widthFactor, this.height = 14});

  final double widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      widthFactor: widthFactor,
      alignment: Alignment.centerLeft,
      child: _SkeletonBlock(height: height),
    );
  }
}

class _SkeletonBlock extends StatelessWidget {
  const _SkeletonBlock({this.width, required this.height});

  final double? width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return RikiSkeleton(width: width, height: height);
  }
}
