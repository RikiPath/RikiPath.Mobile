import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';

class RikiPrimaryButton extends StatelessWidget {
  const RikiPrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.loadingLabel,
    this.leadingIcon,
    this.trailingIcon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final String? loadingLabel;
  final IconData? leadingIcon;
  final IconData? trailingIcon;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    return FilledButton(
      onPressed: effectiveOnPressed,
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (isLoading) return AppColors.brandPrimary;
          if (states.contains(WidgetState.disabled)) {
            return AppColors.brandPrimaryDisabled;
          }
          if (states.contains(WidgetState.pressed)) {
            return AppColors.brandPrimaryPressed;
          }
          return AppColors.brandPrimary;
        }),
        foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (isLoading) return Colors.white;
          return states.contains(WidgetState.disabled)
              ? AppColors.textDisabled
              : Colors.white;
        }),
        elevation: WidgetStateProperty.resolveWith<double>((states) {
          if (isLoading) return 4;
          if (states.contains(WidgetState.disabled)) return 0;
          if (states.contains(WidgetState.pressed)) return 1;
          return 3;
        }),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        child: isLoading
            ? _LoadingButtonContent(
                key: const ValueKey<String>('loading'),
                label: loadingLabel ?? label,
              )
            : _ButtonContent(
                key: const ValueKey<String>('label'),
                label: label,
                leadingIcon: leadingIcon,
                trailingIcon: trailingIcon,
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
        const SizedBox.square(
          dimension: 16,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
            semanticsLabel: 'Đang xử lý',
          ),
        ),
        const SizedBox(width: AppSpacing.space2),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
  }
}
