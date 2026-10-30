import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/widgets/jlpt_badge.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/auth/domain/backend_user_role.dart';
import 'package:rikipath_mobile/features/home/application/home_controller.dart';
import 'package:rikipath_mobile/features/home/data/profile_home_repository.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';

import '../../support/test_auth_session.dart';

void main() {
  test(
    'authenticated Home greeting uses the owner profile, never fixture data',
    () async {
      final repository = ProfileHomeRepository(() async => _profile());

      final dashboard = await repository.loadDashboard();

      expect(dashboard.learnerName, 'Linh Nguyen');
      expect(dashboard.initials, 'L');
      expect(dashboard.jlptTarget, JlptLevel.n4);
      expect(dashboard.streakDays, isNull);
      expect(dashboard.firstLesson, isNull);
      expect(dashboard.tools, isEmpty);
    },
  );

  test(
    'unknown Home goal stays absent instead of assuming an N5 target',
    () async {
      final repository = ProfileHomeRepository(
        () async => _profile(firstName: '', lastName: '', target: null),
      );

      final dashboard = await repository.loadDashboard();

      expect(dashboard.learnerName, 'qa@example.test');
      expect(dashboard.jlptTarget, isNull);
      expect(dashboard.streakDays, isNull);
    },
  );

  test('Home refreshes owner greeting when another learner signs in', () async {
    final session = createTestAuthSession(userId: 900007);
    final container = ProviderContainer(
      overrides: [
        authSessionControllerProvider.overrideWithValue(session),
        homeRepositoryProvider.overrideWith(
          (ref) => ProfileHomeRepository(() async {
            final userId = ref
                .read(authSessionControllerProvider)
                .currentUserId;
            return userId == 900008
                ? _profile(firstName: 'Minh', lastName: 'Tran')
                : _profile();
          }),
        ),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(homeControllerProvider, (_, _) {});
    addTearDown(subscription.close);

    expect(
      (await container.read(homeControllerProvider.future)).learnerName,
      'Linh Nguyen',
    );
    session.markAuthenticated(userId: 900008, role: BackendUserRole.learner);
    await Future<void>.delayed(Duration.zero);
    expect(
      (await container.read(homeControllerProvider.future)).learnerName,
      'Minh Tran',
    );
  });
}

UserProfile _profile({
  String firstName = 'Linh',
  String lastName = 'Nguyen',
  String? target = 'N4',
}) => UserProfile(
  userId: 900007,
  email: 'qa@example.test',
  firstName: firstName,
  lastName: lastName,
  avatarUrl: null,
  role: 'Learner',
  isEmailVerified: true,
  targetJlptLevelId: target == null ? null : 2,
  targetJlptLevelName: target,
  dailyStudyMinutes: 30,
  emailNotificationsEnabled: false,
  systemNotificationsEnabled: false,
);
