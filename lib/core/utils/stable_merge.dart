List<T> mergeUniqueByKey<T, K>(
  Iterable<T> existing,
  Iterable<T> incoming,
  K Function(T item) keyOf,
) {
  final seen = <K>{};
  return <T>[
    ...existing,
    ...incoming,
  ].where((item) => seen.add(keyOf(item))).toList(growable: false);
}
