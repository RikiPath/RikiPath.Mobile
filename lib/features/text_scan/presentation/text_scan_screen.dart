import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/features/text_scan/application/text_scan_controller.dart';
import 'package:rikipath_mobile/features/text_scan/domain/text_scan.dart';

class TextScanScreen extends ConsumerStatefulWidget {
  const TextScanScreen({super.key});

  @override
  ConsumerState<TextScanScreen> createState() => _TextScanScreenState();
}

class _TextScanScreenState extends ConsumerState<TextScanScreen> {
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(textScanControllerProvider);
    final controller = ref.read(textScanControllerProvider.notifier);
    ref.listen(textScanControllerProvider, (previous, next) {
      if (next.status == TextScanStatus.completed &&
          next.recognizedText != _textController.text) {
        _textController.value = TextEditingValue(
          text: next.recognizedText,
          selection: TextSelection.collapsed(
            offset: next.recognizedText.length,
          ),
        );
      }
      if (next.status == TextScanStatus.idle &&
          _textController.text.isNotEmpty) {
        _textController.clear();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.learnerBackground,
      appBar: AppBar(title: Text(context.l10n.textScanTitle)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.space4,
            AppSpacing.space3,
            AppSpacing.space4,
            AppSpacing.space8,
          ),
          children: [
            Text(context.l10n.textScanHeading, style: AppTypography.pageTitle),
            const SizedBox(height: AppSpacing.space2),
            Text(
              context.l10n.textScanSubtitle,
              style: AppTypography.body.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.space5),
            _ImagePickerCard(state: state, onPick: controller.pickImage),
            const SizedBox(height: AppSpacing.space3),
            _TextScanFeedback(state: state),
            if (state.status == TextScanStatus.completed) ...[
              const SizedBox(height: AppSpacing.space4),
              RikiCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.l10n.textScanResultLabel,
                            style: AppTypography.cardTitle,
                          ),
                        ),
                        IconButton(
                          key: const ValueKey<String>('text_scan_copy_button'),
                          tooltip: context.l10n.textScanCopy,
                          onPressed: _textController.text.trim().isEmpty
                              ? null
                              : _copyText,
                          icon: const Icon(Icons.copy_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    TextField(
                      key: const ValueKey<String>('text_scan_result_field'),
                      controller: _textController,
                      minLines: 7,
                      maxLines: 14,
                      onChanged: controller.updateRecognizedText,
                      decoration: InputDecoration(
                        hintText: context.l10n.textScanResultHint,
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.space2),
                    Text(
                      context.l10n.textScanLocalEditNote,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.space5),
            SizedBox(
              width: double.infinity,
              child: state.image == null
                  ? RikiPrimaryButton(
                      key: const ValueKey<String>('text_scan_choose_button'),
                      label: context.l10n.textScanChooseImage,
                      leadingIcon: Icons.photo_library_outlined,
                      isLoading: state.status == TextScanStatus.selecting,
                      loadingLabel: context.l10n.textScanSelecting,
                      onPressed: state.isBusy ? null : controller.pickImage,
                    )
                  : RikiPrimaryButton(
                      key: const ValueKey<String>('text_scan_submit_button'),
                      label: context.l10n.textScanAction,
                      leadingIcon: Icons.document_scanner_outlined,
                      isLoading: state.status == TextScanStatus.scanning,
                      loadingLabel: context.l10n.textScanScanning,
                      onPressed: state.isBusy ? null : controller.scan,
                    ),
            ),
            if (state.image != null && !state.isBusy) ...[
              const SizedBox(height: AppSpacing.space2),
              RikiTextButton(
                key: const ValueKey<String>('text_scan_another_button'),
                label: context.l10n.textScanChooseAnother,
                leadingIcon: Icons.image_outlined,
                onPressed: controller.pickImage,
              ),
              RikiTextButton(
                key: const ValueKey<String>('text_scan_clear_button'),
                label: context.l10n.textScanClear,
                leadingIcon: Icons.delete_outline,
                onPressed: controller.clear,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _copyText() async {
    await Clipboard.setData(ClipboardData(text: _textController.text.trim()));
    if (!mounted) return;
    ref
        .read(rikiToastServiceProvider.notifier)
        .success(title: context.l10n.textScanCopied);
  }
}

class _ImagePickerCard extends StatelessWidget {
  const _ImagePickerCard({required this.state, required this.onPick});

  final TextScanState state;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final image = state.image;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: state.isBusy ? null : onPick,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: RikiCard(
          padding: EdgeInsets.zero,
          child: image == null
              ? SizedBox(
                  height: 210,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.space5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const RikiFeatureIcon(
                            icon: Icons.document_scanner_outlined,
                            tone: AppFeatureTones.textScan,
                            extent: 64,
                            iconSize: 32,
                          ),
                          const SizedBox(height: AppSpacing.space3),
                          Text(
                            context.l10n.textScanDropTitle,
                            textAlign: TextAlign.center,
                            style: AppTypography.cardTitle,
                          ),
                          const SizedBox(height: AppSpacing.space1),
                          Text(
                            context.l10n.textScanRequirements,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card - 1),
                  child: AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Image.memory(
                      image.bytes,
                      key: const ValueKey<String>('text_scan_preview'),
                      fit: BoxFit.contain,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _TextScanFeedback extends StatelessWidget {
  const _TextScanFeedback({required this.state});

  final TextScanState state;

  @override
  Widget build(BuildContext context) {
    if (state.inputError == TextScanInputError.unsupportedType) {
      return RikiErrorBanner(message: context.l10n.textScanUnsupportedType);
    }
    if (state.inputError == TextScanInputError.tooLarge) {
      return RikiErrorBanner(message: context.l10n.textScanTooLarge);
    }
    return switch (state.status) {
      TextScanStatus.pickerError => RikiErrorBanner(
        title: context.l10n.textScanPickerFailedTitle,
        message: context.l10n.textScanPickerError,
      ),
      TextScanStatus.networkError => RikiErrorBanner(
        title: context.l10n.textScanFailedTitle,
        message: context.l10n.textScanNetworkError,
      ),
      TextScanStatus.providerError => RikiErrorBanner(
        title: context.l10n.textScanFailedTitle,
        message: context.l10n.textScanProviderError,
      ),
      TextScanStatus.completed => RikiSuccessBanner(
        message: context.l10n.textScanCompleted,
      ),
      _ => RikiInfoBanner(
        message: context.l10n.textScanPrivacyNote,
        icon: Icons.auto_awesome_outlined,
      ),
    };
  }
}
