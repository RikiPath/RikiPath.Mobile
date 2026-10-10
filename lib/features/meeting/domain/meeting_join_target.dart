import 'package:flutter/foundation.dart';
import 'package:rikipath_mobile/core/network/safe_external_http_uri.dart';

enum MeetingLinkValidationError { empty, invalid }

@immutable
class MeetingJoinTarget {
  const MeetingJoinTarget._(this.uri);

  final Uri uri;

  static ({MeetingJoinTarget? target, MeetingLinkValidationError? error}) parse(
    String? rawValue,
  ) {
    final normalized = rawValue?.trim();
    if (normalized == null || normalized.isEmpty) {
      return (target: null, error: MeetingLinkValidationError.empty);
    }
    final uri = parseSafeExternalHttpUri(normalized);
    if (uri == null) {
      return (target: null, error: MeetingLinkValidationError.invalid);
    }
    return (target: MeetingJoinTarget._(uri), error: null);
  }
}
