import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_loading.dart';

class RikiPrimaryButton extends StatefulWidget {
  const RikiPrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.loadingLabel,
    this.leadingIcon,
    this.trailingIcon,
    this.backgroundColor = AppColors.brandPrimary,
    this.pressedColor = AppColors.brandPrimaryPressed,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? loadingLabel;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Color backgroundColor;
  final Color pressedColor;

  @override
  State<RikiPrimaryButton> createState() => _RikiPrimaryButtonState();
}

class _RikiPrimaryButtonState extends State<RikiPrimaryButton> {
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value || !mounted) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = widget.isLoading ? null : widget.onPressed;
    final mediaQuery = MediaQuery.maybeOf(context);
    final reduceMotion =
        (mediaQuery?.disableAnimations ?? false) ||
        (mediaQuery?.accessibleNavigation ?? false);

    return Listener(
      behavior: HitTestBehavior.opaque,
      onPointerDown: effectiveOnPressed == null
          ? null
          : (_) => _setPressed(true),
      onPointerUp: effectiveOnPressed == null
          ? null
          : (_) => _setPressed(false),
      onPointerCancel: effectiveOnPressed == null
          ? null
          : (_) => _setPressed(false),
      child: AnimatedScale(
        key: const ValueKey<String>('riki_primary_button_scale'),
        scale: _isPressed && effectiveOnPressed != null ? 0.98 : 1,
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 110),
        curve: Curves.easeOutCubic,
        child: FilledButton(
          onPressed: effectiveOnPressed,
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (widget.isLoading) return widget.backgroundColor;
              if (states.contains(WidgetState.disabled)) {
                return AppColors.brandPrimaryDisabled;
              }
              if (states.contains(WidgetState.pressed)) {
                return widget.pressedColor;
              }
              return widget.backgroundColor;
            }),
            foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
              if (widget.isLoading) return Colors.white;
              return states.contains(WidgetState.disabled)
                  ? AppColors.textDisabled
                  : Colors.white;
            }),
            elevation: WidgetStateProperty.resolveWith<double>((states) {
              if (widget.isLoading) return 4;
              if (states.contains(WidgetState.disabled)) return 0;
              if (states.contains(WidgetState.pressed)) return 1;
              return 3;
            }),
            shadowColor: WidgetStatePropertyAll<Color>(
              widget.backgroundColor.withValues(alpha: 0.24),
            ),
          ),
          child: AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 180),
            child: widget.isLoading
                ? _LoadingButtonContent(
                    key: const ValueKey<String>('loading'),
                    label: widget.loadingLabel ?? widget.label,
                  )
                : _ButtonContent(
                    key: const ValueKey<String>('label'),
                    label: widget.label,
                    leadingIcon: widget.leadingIcon,
                    trailingIcon: widget.trailingIcon,
                  ),
          ),
        ),
      ),
    );
  }
}

class RikiSecondaryButton extends StatelessWidget {
  const RikiSecondaryButton({
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      child: _ButtonContent(
        label: label,
        leadingIcon: leadingIcon,
        trailingIcon: trailingIcon,
      ),
    );
  }
}

class RikiTextButton extends StatelessWidget {
  const RikiTextButton({
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.trailingIcon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: _ButtonContent(
        label: label,
        leadingIcon: leadingIcon,
        trailingIcon: trailingIcon,
      ),
    );
  }
}

class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    this.leadingIcon,
    this.trailingIcon,
    super.key,
  });

  final String label;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 18),
          const SizedBox(width: AppSpacing.space2),
        ],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
        if (trailingIcon != null) ...[
          const SizedBox(width: AppSpacing.space2),
          Icon(trailingIcon, size: 18),
        ],
      ],
    );
  }
}

class _LoadingButtonContent extends StatelessWidget {
  const _LoadingButtonContent({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        RikiInlineLoader(
          size: 16,
          color: Colors.white,
          semanticsLabel: context.l10n.processingSemantics,
        ),
        const SizedBox(width: AppSpacing.space2),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
  }
}
