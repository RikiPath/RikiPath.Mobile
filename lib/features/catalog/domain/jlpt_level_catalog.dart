import 'package:flutter/foundation.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';

@immutable
class JlptLevelCatalogItem {
  const JlptLevelCatalogItem({
    required this.id,
    required this.code,
    required this.level,
    required this.sortOrder,
    this.description,
  });

  final int id;
  final String code;
  final JlptLevel level;
  final String? description;
  final int sortOrder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is JlptLevelCatalogItem &&
          id == other.id &&
          code == other.code &&
          level == other.level &&
          description == other.description &&
          sortOrder == other.sortOrder;

  @override
  int get hashCode => Object.hash(id, code, level, description, sortOrder);
}
