import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';

void main() {
  test('loading copy is available in Vietnamese and Japanese', () async {
    final vietnamese = await AppLocalizations.delegate.load(const Locale('vi'));
    final japanese = await AppLocalizations.delegate.load(const Locale('ja'));

    expect(
      vietnamese.preparingLearningContent,
      'RikiPath đang chuẩn bị bài học cho bạn...',
    );
    expect(japanese.preparingLearningContent, '学習内容を準備しています…');
  });

  test('theme exposes the canonical brand and focused input tokens', () {
    final theme = AppTheme.light;
    final focusedBorder = theme.inputDecorationTheme.focusedBorder;

    expect(AppColors.brandPrimary, const Color(0xFFE05A7A));
    expect(AppColors.brandSecondary, const Color(0xFFF8BBD0));
    expect(AppColors.success, const Color(0xFF079D47));
    expect(AppColors.textPrimary, const Color(0xFF2D282A));
    expect(AppColors.error, const Color(0xFFD32F2F));
    expect(AppColors.error, isNot(AppColors.brandPrimary));
    expect(theme.colorScheme.primary, AppColors.brandPrimary);
    expect(theme.colorScheme.secondary, AppColors.brandSecondary);
    expect(
      theme.progressIndicatorTheme.linearTrackColor,
      AppColors.progressTrack,
    );
    expect(focusedBorder, isA<OutlineInputBorder>());
    expect(
      (focusedBorder! as OutlineInputBorder).borderSide,
      AppBorders.focused,
    );
  });

  testWidgets('brand lockup is shared across normal and compact headers', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testHost(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RikiBrandLockup(level: JlptLevel.n4),
            SizedBox(height: AppSpacing.space4),
            RikiAuthHeader(onBack: _noop),
          ],
        ),
      ),
    );

    expect(find.text('RikiPath'), findsNWidgets(2));
    expect(find.text('文'), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey<String>('riki_brand_mark')),
      findsNWidgets(2),
    );

    final marks = tester.widgetList<Container>(
      find.byKey(const ValueKey<String>('riki_brand_mark')),
    );
    expect(
      marks.map((mark) => mark.decoration),
      everyElement(isA<BoxDecoration>()),
    );
    expect(
      marks.map((mark) => (mark.decoration! as BoxDecoration).gradient),
      everyElement(isA<LinearGradient>()),
    );
  });

  testWidgets('primary button renders its label and invokes its action', (
    tester,
  ) async {
    var presses = 0;

    await tester.pumpWidget(
      _testHost(
        RikiPrimaryButton(label: 'Đăng nhập', onPressed: () => presses += 1),
      ),
    );

    expect(find.text('Đăng nhập'), findsOneWidget);
    await tester.tap(find.text('Đăng nhập'));
    await tester.pump();
    expect(presses, 1);
  });

  testWidgets('primary button loading state blocks repeated action', (
    tester,
  ) async {
    var presses = 0;

    await tester.pumpWidget(
      _testHost(
        RikiPrimaryButton(
          label: 'Đăng nhập',
          loadingLabel: 'Đang đăng nhập...',
          isLoading: true,
          onPressed: () => presses += 1,
        ),
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);
    expect(find.byType(RikiInlineLoader), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Đang đăng nhập...'), findsOneWidget);
    expect(presses, 0);
  });

  testWidgets('full-screen study loader has a reduced-motion fallback', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localeControllerProvider.overrideWith(
            () => _VietnameseLocaleController(),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('vi'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Scaffold(
              body: RikiFullScreenLoader(
                title: 'RikiPath đang chuẩn bị bài học cho bạn...',
                subtitle: 'Nội dung sẽ sẵn sàng trong giây lát.',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('riki_animated_study_loader')),
      findsOneWidget,
    );
    expect(find.text('文'), findsOneWidget);
    expect(
      find.text('RikiPath đang chuẩn bị bài học cho bạn...'),
      findsOneWidget,
    );
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'section skeleton preserves content structure without a spinner',
    (tester) async {
      await tester.pumpWidget(
        _testHost(
          const SizedBox(
            height: 520,
            child: RikiSectionSkeleton(itemCount: 2, cardHeight: 96),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(RikiShimmer), findsOneWidget);
      expect(find.byType(RikiSkeletonCard), findsNWidgets(2));
      expect(find.byType(RikiSkeleton), findsWidgets);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('text field displays validation treatment and message', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testHost(
        const RikiTextField(
          label: 'Email học viên',
          hintText: 'nhap.email@example.com',
          errorText: 'Email không hợp lệ. Vui lòng kiểm tra lại định dạng.',
          prefixIcon: Icons.mail_outline,
        ),
      ),
    );

    expect(find.text('Email học viên'), findsOneWidget);
    expect(
      find.text('Email không hợp lệ. Vui lòng kiểm tra lại định dạng.'),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.error), findsOneWidget);
    expect(find.byIcon(Icons.info_outline), findsOneWidget);
  });

  testWidgets('password visibility toggle updates obscure state', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testHost(const RikiPasswordField(label: 'Mật khẩu')),
    );

    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isTrue,
    );

    await tester.tap(find.byTooltip('Hiện mật khẩu'));
    await tester.pump();

    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isFalse,
    );
    expect(find.byTooltip('Ẩn mật khẩu'), findsOneWidget);
  });

  testWidgets('JLPT badge supports only N5, N4, and N3 typed values', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testHost(
        const Wrap(
          spacing: AppSpacing.space2,
          children: [
            JlptBadge(JlptLevel.n5),
            JlptBadge(JlptLevel.n4),
            JlptBadge(JlptLevel.n3),
          ],
        ),
      ),
    );

    expect(find.text('N5'), findsOneWidget);
    expect(find.text('N4'), findsOneWidget);
    expect(find.text('N3'), findsOneWidget);
  });

  testWidgets('semantic banners render their expected content', (tester) async {
    await tester.pumpWidget(
      _testHost(
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RikiInfoBanner(message: 'Thông tin lộ trình'),
            SizedBox(height: AppSpacing.space3),
            RikiWarningBanner(message: 'Kiểm tra hộp thư rác'),
            SizedBox(height: AppSpacing.space3),
            RikiSuccessBanner(message: 'Tài khoản đã sẵn sàng'),
          ],
        ),
      ),
    );

    expect(find.text('Thông tin lộ trình'), findsOneWidget);
    expect(find.text('Kiểm tra hộp thư rác'), findsOneWidget);
    expect(find.text('Tài khoản đã sẵn sàng'), findsOneWidget);
  });

  testWidgets(
    'system typography preserves mixed Japanese and Vietnamese text',
    (tester) async {
      const sample = '日本語・漢字・ひらがな・カタカナ — Tiếng Việt';

      await tester.pumpWidget(
        _testHost(
          const RikiCard(child: Text(sample, style: AppTypography.body)),
        ),
      );

      expect(find.text(sample), findsOneWidget);
    },
  );

  testWidgets('language switcher exposes the approved compact VI state', (
    tester,
  ) async {
    await tester.pumpWidget(_testHost(const RikiLanguageSwitcher()));

    expect(find.text('VI'), findsOneWidget);
    expect(find.byIcon(Icons.language), findsOneWidget);
  });

  testWidgets('selection card exposes selected state and handles action', (
    tester,
  ) async {
    var selections = 0;

    await tester.pumpWidget(
      _testHost(
        RikiSelectionCard(
          title: 'N3 - Trung cấp',
          description: 'Hướng tới trình độ trung cấp',
          badge: 'Phổ biến',
          selected: true,
          onPressed: () => selections += 1,
          leading: const SizedBox.square(
            dimension: 44,
            child: Center(child: Text('N3')),
          ),
        ),
      ),
    );

    expect(find.text('N3 - Trung cấp'), findsOneWidget);
    expect(find.text('Phổ biến'), findsOneWidget);
    await tester.tap(find.text('N3 - Trung cấp'));
    await tester.pump();
    expect(selections, 1);
  });
}

Widget _testHost(Widget child) {
  return ProviderScope(
    overrides: [
      localeControllerProvider.overrideWith(
        () => _VietnameseLocaleController(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('vi'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.space6),
          child: child,
        ),
      ),
    ),
  );
}

class _VietnameseLocaleController extends LocaleController {
  @override
  Locale build() => const Locale('vi');
}

void _noop() {}
