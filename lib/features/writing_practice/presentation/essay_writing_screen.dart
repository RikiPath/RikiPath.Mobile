import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/app_error_message.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/writing_practice/application/essay_writing_controller.dart';
import 'package:rikipath_mobile/features/writing_practice/domain/essay_writing.dart';

class EssayWritingScreen extends ConsumerStatefulWidget {
  const EssayWritingScreen({super.key});

  @override
  ConsumerState<EssayWritingScreen> createState() => _EssayWritingScreenState();
}

class _EssayWritingScreenState extends ConsumerState<EssayWritingScreen> {
  late final TextEditingController _controller;
  int? _selectedLevelId;
  bool _submitting = false;
  String? _error;
  EssayWritingResult? _result;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(essayWritingDraftProvider),
    );
    _controller.addListener(() {
      ref.read(essayWritingDraftProvider.notifier).state = _controller.text;
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit(int levelId) async {
    if (_submitting || _controller.text.trim().isEmpty) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(essayWritingRepositoryProvider)
          .submit(certificateLevelId: levelId, textContent: _controller.text);
      if (!mounted) return;
      setState(() => _result = result);
      ref.read(essayWritingDraftProvider.notifier).state = '';
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = appErrorMessage(
          error,
          context.l10n,
          fallback: context.l10n.essayWritingSubmitUncertain,
        );
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final levels = ref.watch(jlptCatalogControllerProvider);
    final profile = ref.watch(userProfileControllerProvider).value?.profile;
    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(title: Text(context.l10n.essayWritingTitle)),
      body: levels.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: TextButton(
            onPressed: () =>
                ref.read(jlptCatalogControllerProvider.notifier).retry(),
            child: Text(context.l10n.essayWritingLevelLoadError),
          ),
        ),
        data: (rawCatalog) {
          final catalog = rawCatalog
              .where((item) => item.level != JlptLevel.n1)
              .toList(growable: false);
          if (catalog.isEmpty) {
            return Center(child: Text(context.l10n.essayWritingNoLevel));
          }
          final preferredId =
              profile?.targetJlptLevelId ?? profile?.currentStudyLevelId;
          final levelId = catalog.any((item) => item.id == _selectedLevelId)
              ? _selectedLevelId!
              : catalog.any((item) => item.id == preferredId)
              ? preferredId!
              : catalog.first.id;
          return ListView(
            key: const ValueKey<String>('essay_writing_detail'),
            padding: const EdgeInsets.all(AppSpacing.space4),
            children: [
              Text(
                context.l10n.essayWritingDescription,
                style: AppTypography.sectionTitle,
              ),
              const SizedBox(height: AppSpacing.space2),
              Text(context.l10n.essayWritingIntro),
              const SizedBox(height: AppSpacing.space4),
              DropdownButtonFormField<int>(
                key: const ValueKey<String>('essay_level_picker'),
                initialValue: levelId,
                decoration: InputDecoration(
                  labelText: context.l10n.essayWritingLevelLabel,
                ),
                items: [
                  for (final item in catalog)
                    DropdownMenuItem(value: item.id, child: Text(item.code)),
                ],
                onChanged: _submitting
                    ? null
                    : (value) => setState(() => _selectedLevelId = value),
              ),
              const SizedBox(height: AppSpacing.space3),
              TextField(
                key: const ValueKey<String>('essay_writing_input'),
                controller: _controller,
                maxLines: 8,
                maxLength: 4000,
                enabled: !_submitting && _result == null,
                decoration: InputDecoration(
                  hintText: context.l10n.essayWritingInputHint,
                  alignLabelWithHint: true,
                ),
              ),
              if (_error case final error?) ...[
                const SizedBox(height: AppSpacing.space2),
                Text(error, style: TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: AppSpacing.space3),
              FilledButton(
                key: const ValueKey<String>('essay_writing_submit'),
                onPressed:
                    _submitting ||
                        _result != null ||
                        _controller.text.trim().isEmpty
                    ? null
                    : () => _submit(levelId),
                child: Text(
                  _submitting
                      ? context.l10n.essayWritingSubmitting
                      : context.l10n.essayWritingSubmit,
                ),
              ),
              if (_result case final result?) ...[
                const SizedBox(height: AppSpacing.space4),
                Text(
                  context.l10n.essayWritingSaved(result.submissionId),
                  style: AppTypography.cardTitle,
                ),
                if (result.gradingNote case final note?) Text(note),
                if (result.grading case final grading?)
                  _GradingView(grading: grading),
                TextButton(
                  onPressed: () {
                    _controller.clear();
                    setState(() => _result = null);
                  },
                  child: Text(context.l10n.essayWritingNew),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _GradingView extends StatelessWidget {
  const _GradingView({required this.grading});

  final EssayGrading grading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.space2),
        Text(
          context.l10n.essayWritingScore(
            grading.overallScore.toStringAsFixed(0),
          ),
          style: AppTypography.sectionTitle,
        ),
        for (final criterion in grading.criteria)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${criterion.name}: ${criterion.score.toStringAsFixed(1)}/10',
            ),
            subtitle: Text(criterion.comment),
          ),
        if (grading.strengths.isNotEmpty) ...[
          Text(
            context.l10n.essayWritingStrengths,
            style: AppTypography.cardTitle,
          ),
          for (final item in grading.strengths) Text('• $item'),
        ],
        if (grading.improvements.isNotEmpty) ...[
          Text(
            context.l10n.essayWritingImprovements,
            style: AppTypography.cardTitle,
          ),
          for (final item in grading.improvements) Text('• $item'),
        ],
        if (grading.corrections.isNotEmpty) ...[
          Text(
            context.l10n.essayWritingCorrections,
            style: AppTypography.cardTitle,
          ),
          for (final item in grading.corrections)
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('${item.original} → ${item.suggestion}'),
              subtitle: Text(item.reason),
            ),
        ],
      ],
    );
  }
}
