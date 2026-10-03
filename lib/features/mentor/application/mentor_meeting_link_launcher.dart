import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

final mentorMeetingLinkLauncherProvider = Provider<MentorMeetingLinkLauncher>(
  (ref) => const UrlLauncherMentorMeetingLinkLauncher(),
);

abstract interface class MentorMeetingLinkLauncher {
  Future<bool> open(Uri uri);
}

class UrlLauncherMentorMeetingLinkLauncher
    implements MentorMeetingLinkLauncher {
  const UrlLauncherMentorMeetingLinkLauncher();

  @override
  Future<bool> open(Uri uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
