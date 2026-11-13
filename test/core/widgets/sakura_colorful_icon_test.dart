import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/widgets/sakura_colorful_icon.dart';

void main() {
  test('Profile and Settings keep the requested emoji mapping', () {
    expect(SakuraColorfulIconType.streak.glyph, '🔥');
    expect(SakuraColorfulIconType.trophy.glyph, '🏆');
    expect(SakuraColorfulIconType.learningGoal.glyph, '🎯');
    expect(SakuraColorfulIconType.placementTest.glyph, '📋');
    expect(SakuraColorfulIconType.learningProgress.glyph, '📊');
    expect(SakuraColorfulIconType.consultation.glyph, '🧑‍🏫');
    expect(SakuraColorfulIconType.mentorApplication.glyph, '🎓');
    expect(SakuraColorfulIconType.editProfile.glyph, '🪪');
    expect(SakuraColorfulIconType.settings.glyph, '⚙️');
    expect(SakuraColorfulIconType.security.glyph, '🛡️');
    expect(SakuraColorfulIconType.password.glyph, '🔐');
    expect(SakuraColorfulIconType.language.glyph, '🌐');
    expect(SakuraColorfulIconType.notifications.glyph, '🔔');
  });

  testWidgets('utility registry keeps the approved colorful header glyphs', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Row(
          children: [
            SakuraColorfulIcon(
              type: SakuraColorfulIconType.streak,
              useEmoji: true,
            ),
            SakuraColorfulIcon(
              type: SakuraColorfulIconType.notifications,
              useEmoji: true,
            ),
            SakuraColorfulIcon(
              type: SakuraColorfulIconType.calendar,
              useEmoji: true,
            ),
          ],
        ),
      ),
    );

    expect(find.text('🔥'), findsOneWidget);
    expect(find.text('🔔'), findsOneWidget);
    expect(find.text('🗓️'), findsOneWidget);
  });

  testWidgets('decorative glyph remains fixed-size at large text scales', (
    tester,
  ) async {
    for (final scale in [1.0, 1.3, 2.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(scale)),
            child: const Scaffold(
              body: Center(
                child: SakuraColorfulIcon(
                  type: SakuraColorfulIconType.learningGoal,
                  size: 34,
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(SakuraColorfulIcon)),
        const Size(34, 34),
      );
      expect(tester.takeException(), isNull);
    }
  });
}
