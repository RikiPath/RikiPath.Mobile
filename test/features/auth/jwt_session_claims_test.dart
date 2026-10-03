import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/auth/domain/backend_user_role.dart';
import 'package:rikipath_mobile/features/auth/domain/jwt_session_claims.dart';

import '../../support/test_jwt.dart';

void main() {
  test('reads the exact identity, role, and expiry claims', () {
    final expiresAt = DateTime.now().toUtc().add(const Duration(hours: 1));
    final claims = JwtSessionClaims.parse(
      createTestJwt(userId: 42, role: 'Learner', expiresAt: expiresAt),
    );

    expect(claims.userId, 42);
    expect(claims.role, BackendUserRole.learner);
    expect(
      claims.expiresAt.millisecondsSinceEpoch,
      expiresAt.millisecondsSinceEpoch ~/ 1000 * 1000,
    );
    expect(claims.isExpiredAt(DateTime.now().toUtc()), isFalse);
  });

  test('rejects malformed, unknown-role, and expired claims safely', () {
    expect(() => JwtSessionClaims.parse('not-a-jwt'), throwsFormatException);
    expect(
      () =>
          JwtSessionClaims.parse(createTestJwt(userId: 42, role: 'FutureRole')),
      throwsFormatException,
    );

    final expired = JwtSessionClaims.parse(
      createTestJwt(
        userId: 42,
        role: 'Learner',
        expiresAt: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      ),
    );
    expect(expired.isExpiredAt(DateTime.now().toUtc()), isTrue);
  });
}
