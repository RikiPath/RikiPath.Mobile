import 'package:file_picker/file_picker.dart';
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
import 'package:rikipath_mobile/features/analytics/application/analytics_controller.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/subscriptions/domain/subscription_models.dart';
import 'package:rikipath_mobile/features/writing_practice/application/essay_writing_controller.dart';
import 'package:rikipath_mobile/features/writing_practice/data/learner_essay_draft_repository.dart';
import 'package:rikipath_mobile/features/writing_practice/domain/essay_writing.dart';

class EssayWritingScreen extends ConsumerStatefulWidget {
  const EssayWritingScreen({super.key});

  @override
  ConsumerState<EssayWritingScreen> createState() => _EssayWritingScreenState();
}

class _EssayWritingScreenState extends ConsumerState<EssayWritingScreen> {
  late final TextEditingController _controller;
  int? _selectedLevelId;
  int? _activeDraftId;
  bool _submitting = false;
  bool _savingDraft = false;
  String? _error;
  bool _subscriptionRequired = false;
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
      _subscriptionRequired = false;
    });
    try {
      final result = await ref
          .read(essayWritingRepositoryProvider)
          .submit(certificateLevelId: levelId, textContent: _controller.text);
      if (!mounted) return;
      ref.invalidate(learnerAnalyticsControllerProvider);
      ref.invalidate(learnerStudyHistoryProvider);
      setState(() => _result = result);
      ref.read(essayWritingDraftProvider.notifier).state = '';
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _subscriptionRequired = isSubscriptionOrAiGateError(error);
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

  Future<void> _saveDraft() async {
    final text = _controller.text.trim();
    if (_savingDraft || text.isEmpty) return;
    setState(() {
      _savingDraft = true;
      _error = null;
    });
    try {
      final repo = ref.read(learnerEssayDraftRepositoryProvider);
      final saved = _activeDraftId == null
          ? await repo.createDraft(contentText: text)
          : await repo.updateDraftContent(_activeDraftId!, text);
      if (!mounted) return;
      ref.invalidate(learnerEssayDraftsProvider);
      setState(() => _activeDraftId = saved.id);
      ref
          .read(rikiToastServiceProvider.notifier)
          .success(title: 'Đã lưu bản nháp bài viết');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _subscriptionRequired = isSubscriptionOrAiGateError(error);
        _error = appErrorMessage(
          error,
          context.l10n,
          fallback: 'Không thể lưu bản nháp lúc này.',
        );
      });
    } finally {
      if (mounted) setState(() => _savingDraft = false);
    }
  }

  Future<void> _rescanActiveDraft() async {
    final draftId = _activeDraftId;
    if (draftId == null || _savingDraft) return;
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    final ext = picked.name.split('.').last.toLowerCase();
    final contentType = switch (ext) {
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      _ => 'image/png',
    };
    setState(() {
      _savingDraft = true;
      _error = null;
      _subscriptionRequired = false;
    });
    try {
      final text = await ref
          .read(learnerEssayDraftRepositoryProvider)
          .rescanDraft(
            draftId,
            imageBytes: bytes,
            fileName: picked.name,
            contentType: contentType,
          );
      if (!mounted) return;
      if (text.isNotEmpty) {
        _controller.text = text;
      }
      ref.invalidate(learnerEssayDraftsProvider);
      ref
          .read(rikiToastServiceProvider.notifier)
          .success(title: 'Đã quét lại văn bản từ ảnh vào bản nháp');
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _subscriptionRequired = isSubscriptionOrAiGateError(error);
        _error = appErrorMessage(
          error,
          context.l10n,
          fallback: 'Không quét lại được ảnh cho bản nháp.',
        );
      });
    } finally {
      if (mounted) setState(() => _savingDraft = false);
    }
  }

  void _openDraftsSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.learnerBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => _EssayDraftsSheet(
        onOpenDraft: (detail) {
          Navigator.of(sheetCtx).pop();
          setState(() {
            _activeDraftId = detail.id;
            _result = null;
            _error = null;
            _controller.text = detail.contentText;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final levels = ref.watch(jlptCatalogControllerProvider);
    final profile = ref.watch(userProfileControllerProvider).value?.profile;
    return Stack(
      fit: StackFit.expand,
      children: [
        Scaffold(
          backgroundColor: AppColors.learnerBackground,
          appBar: AppBar(
            title: Text(context.l10n.essayWritingTitle),
            actions: [
              IconButton(
                key: const ValueKey<String>('essay_drafts_button'),
                tooltip: 'Bản nháp bài viết',
                icon: const Icon(Icons.folder_open_rounded),
                onPressed: _openDraftsSheet,
              ),
            ],
          ),
      body: levels.when(
        loading: () => const Center(child: SakuraLoadingIndicator()),
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
                if (_subscriptionRequired) ...[
                  const SizedBox(height: AppSpacing.space2),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      key: const ValueKey<String>('essay_upgrade_button'),
                      onPressed: () =>
                          context.push(AppRoutes.profileSubscriptions),
                      icon: const Icon(Icons.workspace_premium_outlined),
                      label: const Text('Xem gói luyện tập / AI'),
                    ),
                  ),
                ],
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
              if (_result == null) ...[
                const SizedBox(height: AppSpacing.space2),
                Wrap(
                  spacing: AppSpacing.space2,
                  runSpacing: AppSpacing.space2,
                  children: [
                    OutlinedButton.icon(
                      key: const ValueKey<String>('essay_save_draft_button'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 42),
                      ),
                      onPressed:
                          _submitting ||
                              _savingDraft ||
                              _controller.text.trim().isEmpty
                          ? null
                          : _saveDraft,
                      icon: const Icon(Icons.save_outlined, size: 18),
                      label: Text(
                        _activeDraftId == null
                            ? 'Lưu bản nháp'
                            : 'Cập nhật bản nháp',
                      ),
                    ),
                    if (_activeDraftId != null)
                      OutlinedButton.icon(
                        key: const ValueKey<String>('essay_rescan_draft_button'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(0, 42),
                        ),
                        onPressed: _savingDraft ? null : _rescanActiveDraft,
                        icon: const Icon(Icons.document_scanner_outlined, size: 18),
                        label: const Text('Quét lại ảnh'),
                      ),
                  ],
                ),
              ],
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
                    setState(() {
                      _result = null;
                      _activeDraftId = null;
                    });
                  },
                  child: Text(context.l10n.essayWritingNew),
                ),
              ],
            ],
          );
        },
      ),
        ),
        AppLoadingOverlay(
          visible: _submitting,
          title: context.l10n.loadingOverlaySubmittingTitle,
          subtitle: context.l10n.loadingOverlayCompletingSubtitle,
        ),
      ],
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

class _EssayDraftsSheet extends ConsumerWidget {
  const _EssayDraftsSheet({required this.onOpenDraft});

  final ValueChanged<LearnerEssayDetail> onOpenDraft;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draftsAsync = ref.watch(learnerEssayDraftsProvider);
    final df = DateFormat('dd/MM HH:mm');

    return FractionallySizedBox(
      heightFactor: 0.78,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.space4,
          AppSpacing.space3,
          AppSpacing.space4,
          AppSpacing.space4,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Bản nháp bài viết',
                    style: AppTypography.sectionTitle,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.space3),
            Expanded(
              child: draftsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => RikiErrorState(
                  title: 'Không tải được bản nháp',
                  message: 'Vui lòng thử lại.',
                  actionLabel: 'Thử lại',
                  onAction: () => ref.invalidate(learnerEssayDraftsProvider),
                ),
                data: (items) {
                  if (items.isEmpty) {
                    return const RikiEmptyState(
                      icon: Icons.edit_note_rounded,
                      title: 'Chưa có bản nháp nào',
                      message:
                          'Lưu bản nháp bài viết hoặc lưu từ màn Quét chữ viết tay để tiếp tục chỉnh sửa tại đây.',
                    );
                  }
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.space2),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return RikiCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title.trim().isNotEmpty
                                        ? item.title
                                        : 'Bản nháp #${item.id}',
                                    style: AppTypography.cardTitle,
                                  ),
                                ),
                                if (item.scannedAt != null)
                                  Text(
                                    df.format(item.scannedAt!.toLocal()),
                                    style: AppTypography.caption.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                              ],
                            ),
                            if (item.previewText.trim().isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                item.previewText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () async {
                                    try {
                                      final detail = await ref
                                          .read(
                                            learnerEssayDraftRepositoryProvider,
                                          )
                                          .getDraft(item.id);
                                      onOpenDraft(detail);
                                    } catch (_) {
                                      ref
                                          .read(
                                            rikiToastServiceProvider.notifier,
                                          )
                                          .error(
                                            title:
                                                'Không tải được nội dung bản nháp',
                                          );
                                    }
                                  },
                                  icon: const Icon(Icons.edit_outlined, size: 16),
                                  label: const Text('Mở viết tiếp'),
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: 'Xóa bản nháp',
                                  onPressed: () async {
                                    try {
                                      await ref
                                          .read(
                                            learnerEssayDraftRepositoryProvider,
                                          )
                                          .deleteDraft(item.id);
                                      ref.invalidate(learnerEssayDraftsProvider);
                                    } catch (_) {
                                      ref
                                          .read(
                                            rikiToastServiceProvider.notifier,
                                          )
                                          .error(title: 'Không xóa được bản nháp');
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.error,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
