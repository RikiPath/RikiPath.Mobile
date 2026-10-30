import 'package:rikipath_mobile/features/home/domain/home_dashboard.dart';
import 'package:rikipath_mobile/features/home/domain/home_repository.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';

/// Supplies the authenticated greeting from the server-owned learner profile.
///
/// The remaining Home sections have their own live providers; unknown values
/// stay absent instead of inheriting the visual-development fixture.
class ProfileHomeRepository implements HomeRepository {
  const ProfileHomeRepository(this._loadProfile);

  final Future<UserProfile> Function() _loadProfile;

  @override
  Future<HomeDashboard> loadDashboard() async {
    final profile = await _loadProfile();
    final name = profile.fullName.isNotEmpty ? profile.fullName : profile.email;
    return HomeDashboard(
      learnerName: name,
      initials: name.trim().isEmpty ? '' : name.trim()[0].toUpperCase(),
      jlptTarget: profile.supportedJlptLevel,
    );
  }
}
