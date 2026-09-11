import 'package:flutter/material.dart';

/// Low-elevation shadows observed in the Stitch exports.
abstract final class AppShadows {
  static const List<BoxShadow> cardSoft = <BoxShadow>[
    BoxShadow(
      color: Color(0x05000000),
      offset: Offset(0, 2),
      blurRadius: 10,
    ),
  ];

  static const List<BoxShadow> selectedCard = <BoxShadow>[
    BoxShadow(
      color: Color(0x14B7131A),
      offset: Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  static const List<BoxShadow> primaryButton = <BoxShadow>[
    BoxShadow(
      color: Color(0x40B7131A),
      offset: Offset(0, 4),
      blurRadius: 6,
      spreadRadius: -1,
    ),
  ];

  static const List<BoxShadow> loadingButton = <BoxShadow>[
    BoxShadow(
      color: Color(0x73B91C1C),
      offset: Offset(0, 8),
      blurRadius: 24,
      spreadRadius: -4,
    ),
  ];

  static const List<BoxShadow> learnerHeader = <BoxShadow>[
    BoxShadow(
      color: Color(0x0A000000),
      offset: Offset(0, 1),
      blurRadius: 8,
    ),
  ];

  static const List<BoxShadow> learnerBottomNavigation = <BoxShadow>[
    BoxShadow(
      color: Color(0x0D000000),
      offset: Offset(0, -2),
      blurRadius: 10,
    ),
  ];
}
