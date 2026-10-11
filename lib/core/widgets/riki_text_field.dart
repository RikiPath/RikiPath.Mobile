import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';

class RikiTextField extends StatefulWidget {
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
  State<RikiTextField> createState() => _RikiTextFieldState();
}

class _RikiTextFieldState extends State<RikiTextField>
    with SingleTickerProviderStateMixin {
  late FocusNode _effectiveFocusNode;
  late bool _ownsFocusNode;
  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _shakeOffset = TweenSequence<double>([
    TweenSequenceItem(tween: Tween<double>(begin: 0, end: -3), weight: 20),
    TweenSequenceItem(tween: Tween<double>(begin: -3, end: 3), weight: 25),
    TweenSequenceItem(tween: Tween<double>(begin: 3, end: -2), weight: 25),
    TweenSequenceItem(tween: Tween<double>(begin: -2, end: 0), weight: 30),
  ]).animate(CurvedAnimation(parent: _shakeController, curve: Curves.easeOut));
  bool _reduceMotion = false;

  bool get _hasError =>
      widget.errorText != null && widget.errorText!.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _attachFocusNode(widget.focusNode);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final mediaQuery = MediaQuery.maybeOf(context);
    _reduceMotion =
        (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);
    if (_reduceMotion) _shakeController.reset();
  }

  @override
  void didUpdateWidget(RikiTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      _detachFocusNode();
      _attachFocusNode(widget.focusNode);
    }
    if (!_reduceMotion &&
        _hasError &&
        oldWidget.errorText != widget.errorText) {
      _shakeController.forward(from: 0);
    }
  }

  void _attachFocusNode(FocusNode? focusNode) {
    _ownsFocusNode = focusNode == null;
    _effectiveFocusNode = focusNode ?? FocusNode();
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  void _detachFocusNode() {
    _effectiveFocusNode.removeListener(_handleFocusChange);
    if (_ownsFocusNode) _effectiveFocusNode.dispose();
  }

  void _handleFocusChange() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _detachFocusNode();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resolvedSuffix = _buildSuffix(_hasError);
    final isProcessing = !widget.enabled || widget.readOnly;
    final isFocused =
        _effectiveFocusNode.hasFocus && widget.enabled && !_hasError;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelTrailing == null)
          Text(widget.label, style: AppTypography.inputLabel)
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(widget.label, style: AppTypography.inputLabel),
              ),
              const SizedBox(width: AppSpacing.space2),
              widget.labelTrailing!,
            ],
          ),
        const SizedBox(height: AppSpacing.fieldLabelGap),
        AnimatedBuilder(
          key: const ValueKey<String>('riki_text_field_error_motion'),
          animation: _shakeOffset,
          child: AnimatedContainer(
            key: const ValueKey<String>('riki_text_field_focus_surface'),
            duration: _reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.input),
              boxShadow: const <BoxShadow>[],
            ),
            child: Semantics(
              label: widget.semanticLabel ?? widget.label,
              child: TextField(
                controller: widget.controller,
                focusNode: _effectiveFocusNode,
                enabled: widget.enabled,
                readOnly: widget.readOnly,
                obscureText: widget.obscureText,
                keyboardType: widget.keyboardType,
                textInputAction: widget.textInputAction,
                textCapitalization: widget.textCapitalization,
                autofillHints: widget.autofillHints,
                inputFormatters: widget.inputFormatters,
                autofocus: widget.autofocus,
                enableSuggestions: widget.enableSuggestions,
                autocorrect: widget.autocorrect,
                onChanged: widget.onChanged,
                onSubmitted: widget.onSubmitted,
                style: AppTypography.inputText.copyWith(
                  color: isProcessing
                      ? AppColors.textSecondary
                      : AppColors.textPrimary,
                ),
                cursorColor: AppColors.brandPrimary,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  prefixIcon: widget.prefixIcon == null
                      ? null
                      : Icon(
                          widget.prefixIcon,
                          color: _hasError
                              ? AppColors.error
                              : isFocused
                              ? AppColors.brandPrimary
                              : AppColors.textMuted,
                        ),
                  suffixIcon: resolvedSuffix,
                  fillColor: isProcessing
                      ? AppColors.inputProcessing
                      : _hasError
                      ? AppColors.errorBackground
                      : AppColors.input,
                  error: _hasError
                      ? _ValidationMessage(widget.errorText!)
                      : null,
                ),
              ),
            ),
          ),
          builder: (context, child) => Transform.translate(
            offset: Offset(_reduceMotion ? 0 : _shakeOffset.value, 0),
            child: child,
          ),
        ),
      ],
    );
  }

  Widget? _buildSuffix(bool hasError) {
    if (!hasError) return widget.suffixIcon;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const ExcludeSemantics(
          child: Icon(Icons.error, size: 18, color: AppColors.error),
        ),
        ?widget.suffixIcon,
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
