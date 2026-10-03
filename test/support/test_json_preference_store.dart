import 'package:rikipath_mobile/core/storage/json_preference_store.dart';

class TestJsonPreferenceStore implements JsonPreferenceStore {
  TestJsonPreferenceStore({
    Map<String, String>? initialValues,
    this.failReads = false,
    this.failWrites = false,
    this.failRemoves = false,
  }) : values = <String, String>{...?initialValues};

  final Map<String, String> values;
  bool failReads;
  bool failWrites;
  bool failRemoves;
  int readCount = 0;
  int writeCount = 0;
  int removeCount = 0;

  @override
  Future<String?> read(String key) async {
    readCount++;
    if (failReads) throw StateError('Preference read failed.');
    return values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    writeCount++;
    if (failWrites) throw StateError('Preference write failed.');
    values[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    removeCount++;
    if (failRemoves) throw StateError('Preference remove failed.');
    values.remove(key);
  }
}
