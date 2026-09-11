import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_colors.dart';

abstract final class AppBorders {
  static const double thin = 1;
  static const double emphasized = 2;

  static const BorderSide standard = BorderSide(
    color: AppColors.border,
    width: thin,
  );
  static const BorderSide strong = BorderSide(
    color: AppColors.borderStrong,
    width: emphasized,
  );
  static const BorderSide focused = BorderSide(
    color: AppColors.borderFocused,
    width: emphasized,
  );
  static const BorderSide error = BorderSide(
    color: AppColors.error,
    width: thin,
  );
  static const BorderSide focusedError = BorderSide(
    color: AppColors.error,
    width: emphasized,
  );
}
