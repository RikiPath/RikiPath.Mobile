import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/catalog/data/jlpt_catalog_dtos.dart';
import 'package:rikipath_mobile/features/catalog/domain/jlpt_level_catalog.dart';

abstract final class JlptCatalogMapper {
  static JlptLevelCatalogItem fromRemote(JlptLevelCatalogDto dto) {
    final code = dto.code.trim().toUpperCase();
    final level = JlptLevel.tryParse(code);
    if (dto.id <= 0 || dto.sortOrder < 0 || level == null) {
      throw const FormatException('Invalid JLPT catalog item.');
    }
    final description = dto.description?.trim();
    return JlptLevelCatalogItem(
      id: dto.id,
      code: code,
      level: level,
      description: description == null || description.isEmpty
          ? null
          : description,
      sortOrder: dto.sortOrder,
    );
  }
}
