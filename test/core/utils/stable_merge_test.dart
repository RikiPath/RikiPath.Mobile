import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/utils/stable_merge.dart';

void main() {
  test('keeps stable order and removes overlapping load-more items', () {
    final merged = mergeUniqueByKey(
      const <({int id, String value})>[
        (id: 1, value: 'first'),
        (id: 2, value: 'original second'),
      ],
      const <({int id, String value})>[
        (id: 2, value: 'overlapping second'),
        (id: 3, value: 'third'),
      ],
      (item) => item.id,
    );

    expect(merged.map((item) => item.id), <int>[1, 2, 3]);
    expect(merged[1].value, 'original second');
  });

  test('empty later page leaves existing items unchanged', () {
    final merged = mergeUniqueByKey(
      const <int>[1, 2],
      const <int>[],
      (item) => item,
    );

    expect(merged, const <int>[1, 2]);
  });
}
