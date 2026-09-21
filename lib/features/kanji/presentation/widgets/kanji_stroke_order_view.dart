import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/kanji/application/kanji_controller.dart';
import 'package:rikipath_mobile/features/kanji/domain/kanji.dart';

class KanjiStrokeOrderView extends StatelessWidget {
  const KanjiStrokeOrderView({
    required this.state,
    required this.onClose,
    required this.onSelectStroke,
    required this.onPrevious,
    required this.onNext,
    required this.onRestart,
    super.key,
  });

  final KanjiDetailState state;
  final VoidCallback onClose;
  final ValueChanged<int> onSelectStroke;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final entry = state.entry;
    final steps = entry.enrichment?.strokeSteps ?? const <KanjiStrokeStep>[];
    final rules = entry.enrichment?.strokeRules ?? const <String>[];
    final totalStrokes = entry.strokeCount < 1 ? 1 : entry.strokeCount;

    return ListView(
      key: const ValueKey<String>('kanji_stroke_order_view'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space4,
        AppSpacing.space6,
      ),
      children: [
        RikiCard(
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: Container(
                  key: const ValueKey<String>('kanji_stroke_canvas'),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                  ),
                  child: entry.strokeOrderUrl != null
                      ? Image.network(
                          entry.strokeOrderUrl.toString(),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.broken_image_outlined,
                            size: 42,
                            color: AppColors.textMuted,
                          ),
                        )
                      : Text(
                          _previewFor(steps, state.currentStroke, entry),
                          style: AppTypography.heroTitle.copyWith(
                            fontSize: 92,
                            height: 1,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              Text(
                context.l10n.strokeProgress(state.currentStroke, totalStrokes),
                style: AppTypography.sectionTitle.copyWith(
                  color: AppColors.brandPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.space3),
              LinearProgressIndicator(
                value: state.currentStroke / totalStrokes,
                minHeight: 7,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                backgroundColor: AppColors.learnerSurfaceHigh,
                color: AppColors.brandPrimary,
              ),
              const SizedBox(height: AppSpacing.space4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton.filledTonal(
                    key: const ValueKey<String>('kanji_stroke_restart'),
                    tooltip: context.l10n.restartStroke,
                    onPressed: onRestart,
                    icon: const Icon(Icons.replay),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  IconButton.filledTonal(
                    key: const ValueKey<String>('kanji_stroke_previous'),
                    tooltip: context.l10n.previousStroke,
                    onPressed: state.currentStroke <= 1 ? null : onPrevious,
                    icon: const Icon(Icons.skip_previous),
                  ),
                  const SizedBox(width: AppSpacing.space3),
                  IconButton.filled(
                    key: const ValueKey<String>('kanji_stroke_next'),
                    tooltip: context.l10n.nextStroke,
                    onPressed: state.currentStroke >= totalStrokes
                        ? null
                        : onNext,
                    icon: const Icon(Icons.skip_next),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (steps.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space4),
          Text(
            context.l10n.strokeProgressTitle,
            style: AppTypography.sectionTitle,
          ),
          const SizedBox(height: AppSpacing.space2),
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: steps.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(width: AppSpacing.space2),
              itemBuilder: (context, index) {
                final step = steps[index];
                final selected = step.number == state.currentStroke;
                return InkWell(
                  key: ValueKey<String>('kanji_stroke_step_${step.number}'),
                  onTap: () => onSelectStroke(step.number),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  child: Container(
                    width: 64,
                    padding: const EdgeInsets.all(AppSpacing.space2),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.brandPrimary
                          : AppColors.surface,
                      border: Border.all(
                        color: selected
                            ? AppColors.brandPrimary
                            : AppColors.border,
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.input),
                    ),
                    child: Column(
                      children: [
                        Text(
                          context.l10n.strokeNumber(step.number),
                          style: AppTypography.badgeText.copyWith(
                            color: selected
                                ? Colors.white
                                : AppColors.textSecondary,
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Text(
                              step.preview,
                              style: AppTypography.sectionTitle.copyWith(
                                color: selected
                                    ? Colors.white
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        if (rules.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.space4),
          RikiCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.strokeRules,
                  style: AppTypography.sectionTitle,
                ),
                const SizedBox(height: AppSpacing.space3),
                for (final (index, rule) in rules.indexed) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: AppColors.learnerPrimaryFixed,
                        child: Text(
                          '${index + 1}',
                          style: AppTypography.badgeText.copyWith(
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.space2),
                      Expanded(child: Text(rule, style: AppTypography.body)),
                    ],
                  ),
                  if (index != rules.length - 1)
                    const SizedBox(height: AppSpacing.space3),
                ],
                const SizedBox(height: AppSpacing.space2),
                Text(
                  context.l10n.strokeFixtureWarning,
                  style: AppTypography.metadata.copyWith(
                    color: AppColors.warningText,
                  ),
                ),
              ],
            ),
          ),
        ] else if (entry.strokeOrderUrl != null) ...[
          const SizedBox(height: AppSpacing.space3),
          Text(
            context.l10n.strokeImageOnlyWarning,
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall,
          ),
        ],
        const SizedBox(height: AppSpacing.space4),
        RikiPrimaryButton(
          key: const ValueKey<String>('kanji_close_strokes_button'),
          label: context.l10n.backToKanjiDetail(entry.character),
          leadingIcon: Icons.arrow_back,
          onPressed: onClose,
        ),
      ],
    );
  }

  String _previewFor(
    List<KanjiStrokeStep> steps,
    int currentStroke,
    KanjiEntry entry,
  ) {
    for (final step in steps) {
      if (step.number == currentStroke) return step.preview;
    }
    return entry.character;
  }
}
