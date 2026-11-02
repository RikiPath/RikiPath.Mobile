import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:rikipath_mobile/core/storage/json_preference_store.dart';

const _mentorRegistrationIntentKey = 'auth.mentor_application_intent';

final mentorRegistrationIntentProvider = Provider<MentorRegistrationIntent>((ref) {
  return MentorRegistrationIntent(ref.watch(jsonPreferenceStoreProvider));
});

/// Lưu ý định điều hướng ứng tuyển; không lưu thông tin xác thực.
class MentorRegistrationIntent {
  MentorRegistrationIntent(this._store);

  final JsonPreferenceStore _store;

  Future<void> mark() => _store.write(_mentorRegistrationIntentKey, '1');

  Future<bool> consume() async {
    final pending = await _store.read(_mentorRegistrationIntentKey) == '1';
    if (pending) await _store.remove(_mentorRegistrationIntentKey);
    return pending;
  }
}
