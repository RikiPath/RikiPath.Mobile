import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';

class RikiTextField extends StatelessWidget {
  const RikiTextField({
    required this.label,
    this.controller,
    this.focusNode,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.labelTrailing,
    this.errorText,
    this.enabled = true,
    this.readOnly = false,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.autofillHints,
    this.inputFormatters,
    this.autofocus = false,
    this.enableSuggestions = true,
    this.autocorrect = true,
    this.onChanged,
    this.onSubmitted,
    this.semanticLabel,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final Widget? labelTrailing;
  final String? errorText;
  final bool enabled;
  final bool readOnly;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final bool autofocus;
  final bool enableSuggestions;
  final bool autocorrect;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    final resolvedSuffix = _buildSuffix(hasError);
    final isProcessing = !enabled || readOnly;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (labelTrailing == null)
          Text(label, style: AppTypography.inputLabel)
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(child: Text(label, style: AppTypography.inputLabel)),
              const SizedBox(width: AppSpacing.space2),
              labelTrailing!,
            ],
          ),
        const SizedBox(height: AppSpacing.fieldLabelGap),
        Semantics(
          label: semanticLabel ?? label,
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            enabled: enabled,
            readOnly: readOnly,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            textCapitalization: textCapitalization,
            autofillHints: autofillHints,
            inputFormatters: inputFormatters,
            autofocus: autofocus,
            enableSuggestions: enableSuggestions,
            autocorrect: autocorrect,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            style: AppTypography.inputText.copyWith(
              color: isProcessing
                  ? AppColors.textSecondary
                  : AppColors.textPrimary,
            ),
            cursorColor: AppColors.brandPrimary,
            decoration: InputDecoration(
              hintText: hintText,
              prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
              suffixIcon: resolvedSuffix,
              fillColor: isProcessing
                  ? AppColors.inputProcessing
                  : hasError
                  ? AppColors.errorBackground
                  : AppColors.input,
              error: hasError ? _ValidationMessage(errorText!) : null,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffix(bool hasError) {
    if (!hasError) return suffixIcon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ExcludeSemantics(
          child: Icon(Icons.error, size: 18, color: AppColors.error),
        ),
        ?suffixIcon,
      ],
    );
  }
}

class RikiPasswordField extends StatefulWidget {
  const RikiPasswordField({
    required this.label,
    this.controller,
    this.focusNode,
    this.hintText,
    this.errorText,
    this.labelTrailing,
    this.enabled = true,
    this.readOnly = false,
    this.initiallyObscured = true,
    this.textInputAction,
    this.onChanged,
    this.onSubmitted,
    super.key,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hintText;
  final String? errorText;
  final Widget? labelTrailing;
  final bool enabled;
  final bool readOnly;
  final bool initiallyObscured;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;

  @override
  State<RikiPasswordField> createState() => _RikiPasswordFieldState();
}

class _RikiPasswordFieldState extends State<RikiPasswordField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.initiallyObscured;
  }

  @override
  void didUpdateWidget(RikiPasswordField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyObscured != widget.initiallyObscured) {
      _obscured = widget.initiallyObscured;
    }
  }

  @override
  Widget build(BuildContext context) {
    final canToggle = widget.enabled && !widget.readOnly;

    return RikiTextField(
      label: widget.label,
      controller: widget.controller,
      focusNode: widget.focusNode,
      hintText: widget.hintText,
      prefixIcon: Icons.lock_outline,
      errorText: widget.errorText,
      labelTrailing: widget.labelTrailing,
      enabled: widget.enabled,
      readOnly: widget.readOnly,
      obscureText: _obscured,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: widget.textInputAction,
      enableSuggestions: false,
      autocorrect: false,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      suffixIcon: IconButton(
        onPressed: canToggle
            ? () => setState(() {
                _obscured = !_obscured;
              })
            : null,
        tooltip: _obscured
            ? context.l10n.showPassword
            : context.l10n.hidePassword,
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
        ),
      ),
    );
  }
}

class _ValidationMessage extends StatelessWidget {
  const _ValidationMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: AppSpacing.space1),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.info_outline,
                size: 14,
                color: AppColors.errorText,
              ),
            ),
            const SizedBox(width: AppSpacing.space1),
            Expanded(child: Text(message, style: AppTypography.validationText)),
          ],
        ),
      ),
    );
  }
}
