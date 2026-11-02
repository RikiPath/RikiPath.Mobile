import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/storage/json_preference_store.dart';
import 'package:rikipath_mobile/features/auth/application/mentor_registration_intent.dart';

class _MemoryPreferenceStore implements JsonPreferenceStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> remove(String key) async => values.remove(key);
}

void main() {
  test('mentor application intent survives restoration and is consumed once', () async {
    final store = _MemoryPreferenceStore();
    final intent = MentorRegistrationIntent(store);

    await intent.mark();
    final restoredIntent = MentorRegistrationIntent(store);

    expect(await restoredIntent.consume(), isTrue);
    expect(await intent.consume(), isFalse);
    expect(store.values, isEmpty);
  });

  test('intent contains no authentication material', () async {
    final store = _MemoryPreferenceStore();
    await MentorRegistrationIntent(store).mark();

    expect(store.values.values, everyElement('1'));
    expect(store.values.keys, everyElement('auth.mentor_application_intent'));
  });
}
