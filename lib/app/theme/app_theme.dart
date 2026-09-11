import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_borders.dart';
import 'package:rikipath_mobile/app/theme/app_colors.dart';
import 'package:rikipath_mobile/app/theme/app_radius.dart';
import 'package:rikipath_mobile/app/theme/app_spacing.dart';
import 'package:rikipath_mobile/app/theme/app_typography.dart';

export 'app_borders.dart';
export 'app_colors.dart';
export 'app_radius.dart';
export 'app_shadows.dart';
export 'app_spacing.dart';
export 'app_typography.dart';

abstract final class AppTheme {
  static const ColorScheme _lightScheme = ColorScheme.light(
    primary: AppColors.brandPrimary,
    onPrimary: Colors.white,
    primaryContainer: AppColors.brandTint,
    onPrimaryContainer: AppColors.brandPrimaryPressed,
    secondary: AppColors.info,
    onSecondary: Colors.white,
    secondaryContainer: AppColors.infoBackground,
    onSecondaryContainer: AppColors.info,
    error: AppColors.errorText,
    onError: Colors.white,
    errorContainer: AppColors.errorBackground,
    onErrorContainer: AppColors.errorText,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    onSurfaceVariant: AppColors.textSecondary,
    outline: AppColors.borderStrong,
    outlineVariant: AppColors.border,
  );

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: _lightScheme,
      scaffoldBackgroundColor: AppColors.background,
      canvasColor: AppColors.background,
      disabledColor: AppColors.textDisabled,
      focusColor: AppColors.brandTint,
      fontFamilyFallback: const <String>[
        'Noto Sans',
        'Noto Sans JP',
        'Roboto',
      ],
      textTheme: AppTypography.textTheme,
      iconTheme: const IconThemeData(color: AppColors.textSecondary),
      appBarTheme: const AppBarThemeData(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.sectionTitle,
      ),
      cardTheme: const CardThemeData(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          side: AppBorders.standard,
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.card)),
        ),
      ),
      inputDecorationTheme: const InputDecorationThemeData(
        filled: true,
        fillColor: AppColors.input,
        isDense: true,
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppSpacing.space4,
          vertical: 14,
        ),
        hintStyle: TextStyle(
          color: AppColors.textMuted,
          fontSize: 14,
          height: 1.43,
          fontWeight: FontWeight.w400,
        ),
        labelStyle: AppTypography.inputLabel,
        floatingLabelStyle: AppTypography.inputLabel,
        errorStyle: AppTypography.validationText,
        prefixIconColor: AppColors.textMuted,
        suffixIconColor: AppColors.textSecondary,
        prefixIconConstraints: BoxConstraints(minWidth: 44, minHeight: 44),
        suffixIconConstraints: BoxConstraints(minWidth: 44, minHeight: 44),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.input)),
          borderSide: AppBorders.standard,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.input)),
          borderSide: AppBorders.standard,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.input)),
          borderSide: AppBorders.focused,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.input)),
          borderSide: AppBorders.error,
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.input)),
          borderSide: AppBorders.focusedError,
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.input)),
          borderSide: AppBorders.standard,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size.fromHeight(48),
          ),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.space5,
              vertical: AppSpacing.space3,
            ),
          ),
          backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.brandPrimaryDisabled;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.brandPrimaryPressed;
            }
            return AppColors.brandPrimary;
          }),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textDisabled;
            }
            return Colors.white;
          }),
          overlayColor: const WidgetStatePropertyAll<Color>(
            Colors.transparent,
          ),
          elevation: WidgetStateProperty.resolveWith<double>((states) {
            if (states.contains(WidgetState.disabled)) return 0;
            if (states.contains(WidgetState.pressed)) return 1;
            return 3;
          }),
          shadowColor: const WidgetStatePropertyAll<Color>(
            Color(0x40B7131A),
          ),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(AppRadius.button),
              ),
            ),
          ),
          textStyle: const WidgetStatePropertyAll<TextStyle>(
            AppTypography.buttonLabel,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(
            Size.fromHeight(48),
          ),
          padding: const WidgetStatePropertyAll<EdgeInsetsGeometry>(
            EdgeInsets.symmetric(
              horizontal: AppSpacing.space5,
              vertical: AppSpacing.space3,
            ),
          ),
          backgroundColor: const WidgetStatePropertyAll<Color>(
            AppColors.surface,
          ),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            return states.contains(WidgetState.disabled)
                ? AppColors.textDisabled
                : AppColors.textSecondary;
          }),
          side: WidgetStateProperty.resolveWith<BorderSide>((states) {
            return BorderSide(
              color: states.contains(WidgetState.disabled)
                  ? AppColors.border
                  : AppColors.borderStrong,
            );
          }),
          shape: const WidgetStatePropertyAll<OutlinedBorder>(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.all(
                Radius.circular(AppRadius.button),
              ),
            ),
          ),
          textStyle: const WidgetStatePropertyAll<TextStyle>(
            AppTypography.buttonLabel,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll<Size>(Size(44, 44)),
          foregroundColor: WidgetStateProperty.resolveWith<Color>((states) {
            return states.contains(WidgetState.disabled)
                ? AppColors.textDisabled
                : AppColors.brandPrimary;
          }),
          overlayColor: const WidgetStatePropertyAll<Color>(
            AppColors.brandTint,
          ),
          textStyle: const WidgetStatePropertyAll<TextStyle>(
            AppTypography.buttonLabel,
          ),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith<Color>((states) {
          if (states.contains(WidgetState.disabled)) {
            return AppColors.surfaceSubtle;
          }
          if (states.contains(WidgetState.selected)) {
            return AppColors.brandPrimary;
          }
          return AppColors.surface;
        }),
        checkColor: const WidgetStatePropertyAll<Color>(Colors.white),
        side: AppBorders.standard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.micro)),
        ),
        materialTapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.compact,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: AppBorders.thin,
        space: AppSpacing.space4,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brandPrimary,
        linearTrackColor: AppColors.border,
        linearMinHeight: AppSpacing.space1,
        circularTrackColor: AppColors.brandBorder,
      ),
      navigationBarTheme: const NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.infoBackground,
        height: 68,
      ),
    );
  }
}
