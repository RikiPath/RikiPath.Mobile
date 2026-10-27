import 'package:flutter/material.dart';
import 'package:rikipath_mobile/app/theme/app_colors.dart';

/// Low-elevation shadows observed in the Stitch exports.
abstract final class AppShadows {
  static const List<BoxShadow> cardSoft = <BoxShadow>[
    BoxShadow(
      color: AppColors.neutralShadowSoft,
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  static const List<BoxShadow> selectedCard = <BoxShadow>[
    BoxShadow(
      color: AppColors.brandShadowSoft,
      offset: Offset(0, 4),
      blurRadius: 16,
    ),
  ];

  static const List<BoxShadow> primaryButton = <BoxShadow>[
    BoxShadow(
      color: AppColors.brandShadow,
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
  ];

  static const List<BoxShadow> loadingButton = <BoxShadow>[
    BoxShadow(
      color: AppColors.brandShadowStrong,
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];

  static const List<BoxShadow> learnerHeader = <BoxShadow>[
    BoxShadow(
      color: AppColors.neutralShadowSoft,
      offset: Offset(0, 1),
      blurRadius: 8,
    ),
  ];

  static const List<BoxShadow> learnerBottomNavigation = <BoxShadow>[
    BoxShadow(
      color: AppColors.neutralShadow,
      offset: Offset(0, -2),
      blurRadius: 12,
    ),
  ];
}
