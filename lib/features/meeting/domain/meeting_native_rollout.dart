abstract final class MeetingNativeRollout {
  // Native is the verified demo path. Keep the compile-time switch as an
  // emergency rollback to the existing browser-first flow.
  static const bool isEnabled = bool.fromEnvironment(
    'ENABLE_NATIVE_MEETING',
    defaultValue: true,
  );
}
