import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_brand_lockup.dart';
import 'package:rikipath_mobile/core/widgets/riki_loading.dart';
import 'package:rikipath_mobile/features/auth/presentation/splash_screen.dart';
import 'package:rikipath_mobile/features/onboarding/application/learner_startup_controller.dart';
import 'package:rikipath_mobile/features/onboarding/presentation/learner_startup_screen.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

Widget _app(Widget screen) => MaterialApp(
  theme: AppTheme.light,
  locale: const Locale('vi'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: screen,
);

void main() {
  testWidgets('Splash restores the session without a duplicate brand header', (
    tester,
  ) async {
    await tester.pumpWidget(_app(const SplashScreen()));
    await tester.pump();

    expect(find.byType(RikiBrandLockup), findsNothing);
    expect(
      find.byKey(const ValueKey('riki_study_loader_logo')),
      findsOneWidget,
    );
    expect(find.text('Đang mở RikiPath...'), findsOneWidget);
    expect(
      find.text(
        'Đang kiểm tra phiên đăng nhập để đưa bạn vào không gian học tập.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('post-login loading describes learner startup, not a lesson', (
    tester,
  ) async {
    final pending = Completer<LearnerStartupDestination>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          learnerStartupDestinationProvider.overrideWith(
            (ref) => pending.future,
          ),
        ],
        child: _app(const LearnerStartupScreen()),
      ),
    );
    await tester.pump();

    expect(find.byType(RikiBrandLockup), findsNothing);
    expect(find.byType(RikiAnimatedStudyLoader), findsOneWidget);
    expect(find.text('Đang xác định bước học tiếp theo...'), findsOneWidget);
    expect(
      find.text('RikiPath đang kiểm tra hồ sơ và mục tiêu JLPT của bạn.'),
      findsOneWidget,
    );
    expect(find.textContaining('chuẩn bị bài học'), findsNothing);
  });

  test(
    'destination titles match the next learning screen in both locales',
    () async {
      final vi = await AppLocalizations.delegate.load(const Locale('vi'));
      final ja = await AppLocalizations.delegate.load(const Locale('ja'));

      expect(vi.learnerStartupOnboardingTitle, contains('thiết lập học tập'));
      expect(vi.learnerStartupPlacementTitle, contains('kiểm tra đầu vào'));
      expect(vi.learnerStartupHomeTitle, contains('trang học tập'));
      expect(ja.learnerStartupOnboardingTitle, isNotEmpty);
      expect(ja.learnerStartupPlacementTitle, isNotEmpty);
      expect(ja.learnerStartupHomeTitle, isNotEmpty);
    },
  );
}
