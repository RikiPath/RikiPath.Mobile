/// Keeps server IDs and raw titles intact while hiding known QA seed labels
/// and normalizing technical names into elegant, learner-friendly display titles.
///
/// When [compact] is true (e.g. in the JLPT Exam Hub where the level is already
/// selected and displayed prominently at the top), redundant level prefixes
/// like "JLPT N5" are omitted so titles read cleanly: "Đề thi thử 01", "Đề thi thử 02".
///
/// When [compact] is false, titles preserve the level: "JLPT N5 — Đề thi thử 01".
String mockTestDisplayTitle(
  String rawTitle, {
  bool japanese = false,
  bool compact = false,
}) {
  final title = rawTitle.trim();

  // 1. Seed pattern: [MOCK-SEED-v1] JLPT N5 – Đề kiểm thử 01
  final seed = RegExp(
    r'^\[MOCK-SEED-v\d+\]\s*JLPT\s*(N[1-5])\s*[–—-]\s*Đề kiểm thử\s*(\d+)\s*$',
    caseSensitive: false,
  ).firstMatch(title);
  if (seed != null) {
    final lvl = seed.group(1)!.toUpperCase();
    final num = seed.group(2)!.padLeft(2, '0');
    if (compact) {
      return japanese ? '模擬試験 $num' : 'Đề thi thử $num';
    }
    return japanese ? 'JLPT $lvl — 模擬試験 $num' : 'JLPT $lvl — Đề thi thử $num';
  }

  // 2. Pattern: Đề thi thử JLPT N5 - Đề số 1 / Đề thi thử JLPT N5 - Đề 1
  final p2 = RegExp(
    r'^Đề\s*thi\s*thử\s*JLPT\s*(N[1-5])\s*[-–—:]\s*(?:Đề\s*(?:số\s*)?)?(\d+)\s*$',
    caseSensitive: false,
  ).firstMatch(title);
  if (p2 != null) {
    final lvl = p2.group(1)!.toUpperCase();
    final num = p2.group(2)!.padLeft(2, '0');
    if (compact) {
      return japanese ? '模擬試験 $num' : 'Đề thi thử $num';
    }
    return japanese ? 'JLPT $lvl — 模擬試験 $num' : 'JLPT $lvl — Đề thi thử $num';
  }

  // 3. Pattern: JLPT N5 — Đề thi thử 01 / JLPT N5 - Đề 01
  final p3 = RegExp(
    r'^JLPT\s*(N[1-5])\s*[-–—:]\s*(?:Đề\s*(?:thi\s*thử|kiểm\s*thử)?\s*(?:số\s*)?)?(\d+)\s*$',
    caseSensitive: false,
  ).firstMatch(title);
  if (p3 != null) {
    final lvl = p3.group(1)!.toUpperCase();
    final num = p3.group(2)!.padLeft(2, '0');
    if (compact) {
      return japanese ? '模擬試験 $num' : 'Đề thi thử $num';
    }
    return japanese ? 'JLPT $lvl — 模擬試験 $num' : 'JLPT $lvl — Đề thi thử $num';
  }

  // If compact is requested, strip any redundant leading "JLPT N[1-5] -" prefix
  if (compact) {
    final prefixMatch = RegExp(
      r'^(?:JLPT\s*N[1-5]|N[1-5])\s*[-–—:]\s*(.+)$',
      caseSensitive: false,
    ).firstMatch(title);
    if (prefixMatch != null) {
      return prefixMatch.group(1)!.trim();
    }
  }

  return title;
}
