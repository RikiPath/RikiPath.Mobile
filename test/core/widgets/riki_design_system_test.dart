import 'dart:io';
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
      'Đang mở RikiPath...',
    );
    expect(japanese.preparingLearningContent, 'RikiPathを開いています…');
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

  test('learner surfaces keep neutral hierarchy and Sakura accents', () {
    expect(AppColors.background, const Color(0xFFF7F6F7));
    expect(AppColors.learnerBackground, AppColors.backgroundPrimary);
    expect(AppColors.learnerSurface, AppColors.surfacePrimary);
    expect(AppColors.learnerSurfaceLow, AppColors.backgroundSecondary);
    expect(AppColors.learnerSurfaceHigh, AppColors.surfaceMuted);
    expect(AppColors.learnerBackground, isNot(AppColors.learnerSurface));
    expect(AppColors.learnerSurfaceLow, isNot(AppColors.brandTint));
    expect(AppColors.learnerPrimaryFixed, AppColors.surfaceContainer);
  });

  test('feature tones keep Sakura primary and success visibly green', () {
    expect(AppFeatureTones.brand.foreground, AppColors.brandPrimary);
    expect(AppFeatureTones.writing.foreground, AppColors.brandPrimary);
    expect(AppFeatureTones.learning.foreground, AppColors.brandPrimary);
    expect(AppFeatureTones.practice.foreground, AppColors.brandPrimary);
    expect(AppFeatureTones.review.foreground, AppColors.brandPrimary);
    expect(AppFeatureTones.success.foreground, AppColors.success);
    expect(AppFeatureTones.speech.foreground, AppColors.brandPrimary);
    expect(AppFeatureTones.textScan.foreground, AppColors.brandPrimary);
    expect(AppFeatureTones.meeting.foreground, AppColors.brandPrimary);
    expect(AppFeatureTones.neutral.foreground, AppColors.textSecondary);
    expect(AppFeatureTones.success.foreground, isNot(AppColors.brandPrimary));
  });

  testWidgets('feature icon and status pill use their semantic tone', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testHost(
        const Row(
          children: [
            RikiFeatureIcon(
              icon: Icons.mic_none_rounded,
              tone: AppFeatureTones.speech,
            ),
            SizedBox(width: AppSpacing.space2),
            RikiStatusPill(label: 'Listening', tone: AppFeatureTones.speech),
          ],
        ),
      ),
    );

    expect(find.byIcon(Icons.mic_none_rounded), findsOneWidget);
    expect(find.text('Listening'), findsOneWidget);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.mic_none_rounded)).color,
      AppColors.brandPrimary,
    );
  });

  testWidgets('3D feature illustration is not boxed by default', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testHost(
        const RikiFeatureIcon(
          icon: Icons.map_rounded,
          icon3d: Sakura3DIconType.roadmap,
          tone: AppFeatureTones.learning,
        ),
      ),
    );

    final illustration = find.byType(RikiFeatureIcon);
    expect(
      find.descendant(of: illustration, matching: find.byType(Container)),
      findsNothing,
    );
    expect(find.byType(Sakura3DIcon), findsOneWidget);
  });

  testWidgets('feature illustration background stays opt-in', (tester) async {
    await tester.pumpWidget(
      _testHost(
        const RikiFeatureIcon(
          icon: Icons.map_rounded,
          icon3d: Sakura3DIconType.roadmap,
          tone: AppFeatureTones.learning,
          showIllustrationBackground: true,
        ),
      ),
    );

    final illustration = find.byType(RikiFeatureIcon);
    expect(
      find.descendant(of: illustration, matching: find.byType(Container)),
      findsOneWidget,
    );
  });

  testWidgets('3D category shortcut renders a circular white background tile', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      _testHost(
        SakuraCategoryShortcut(
          label: 'Từ vựng',
          icon: Icons.book,
          icon3d: Sakura3DIconType.vocabulary,
          backgroundColor: AppColors.pastelGreenBg,
          foregroundColor: AppColors.pastelGreenFg,
          onTap: () => tapped = true,
        ),
      ),
    );

    final container = tester.widget<Container>(
      find.descendant(
        of: find.byType(SakuraCategoryShortcut),
        matching: find.byType(Container),
      ),
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.shape, BoxShape.circle);
    expect(decoration.color, Colors.white);
    expect(find.byType(Sakura3DIcon), findsOneWidget);
    await tester.tap(find.text('Từ vựng'));
    expect(tapped, isTrue);
  });

  testWidgets('card supports a borderless surface', (tester) async {
    await tester.pumpWidget(
      _testHost(const RikiCard(borderColor: null, child: Text('Bài học'))),
    );

    final box = tester.widget<DecoratedBox>(
      find
          .descendant(
            of: find.byType(RikiCard),
            matching: find.byType(DecoratedBox),
          )
          .first,
    );
    expect((box.decoration as BoxDecoration).border, isNull);
  });

  testWidgets('tappable card uses subtle press motion without layout shift', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testHost(RikiCard(onTap: _noop, child: const Text('Open'))),
    );
    final card = find.byType(RikiCard);
    final initialRect = tester.getRect(card);

    final gesture = await tester.startGesture(tester.getCenter(card));
    await tester.pump();
    expect(
      tester
          .widget<AnimatedScale>(
            find.byKey(const ValueKey<String>('riki_card_press_scale')),
          )
          .scale,
      0.985,
    );
    expect(tester.getRect(card), initialRect);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AnimatedScale>(
            find.byKey(const ValueKey<String>('riki_card_press_scale')),
          )
          .scale,
      1,
    );
    expect(tester.getRect(card), initialRect);
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
    expect(
      find.byKey(const ValueKey<String>('riki_brand_mark')),
      findsNWidgets(2),
    );

    final logoImages = tester.widgetList<Image>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('riki_brand_mark')),
        matching: find.byType(Image),
      ),
    );
    expect(logoImages, hasLength(2));
    for (final img in logoImages) {
      expect(img.image, isA<AssetImage>());
      expect((img.image as AssetImage).assetName, rikiBrandLogoAsset);
    }
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

  testWidgets('primary button uses a subtle press scale without layout shift', (
    tester,
  ) async {
    var presses = 0;
    await tester.pumpWidget(
      _testHost(
        RikiPrimaryButton(label: 'Tiếp tục', onPressed: () => presses += 1),
      ),
    );
    final button = find.byType(FilledButton);
    final initialRect = tester.getRect(button);

    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump();
    expect(
      tester
          .widget<AnimatedScale>(
            find.byKey(const ValueKey<String>('riki_primary_button_scale')),
          )
          .scale,
      0.98,
    );
    expect(tester.getRect(button), initialRect);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<AnimatedScale>(
            find.byKey(const ValueKey<String>('riki_primary_button_scale')),
          )
          .scale,
      1,
    );
    expect(tester.getRect(button), initialRect);
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
    expect(
      find.byKey(const ValueKey<String>('riki_study_loader_logo')),
      findsOneWidget,
    );
    final loaderLogo = tester.widget<Image>(
      find.descendant(
        of: find.byKey(const ValueKey<String>('riki_study_loader_logo')),
        matching: find.byType(Image),
      ),
    );
    expect((loaderLogo.image as AssetImage).assetName, rikiBrandLogoAsset);
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

  testWidgets('focused text field uses a crisp border without an outer glow', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      _testHost(
        RikiTextField(
          label: 'Email học viên',
          focusNode: focusNode,
          prefixIcon: Icons.mail_outline,
        ),
      ),
    );

    focusNode.requestFocus();
    await tester.pump();
    final surface = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey<String>('riki_text_field_focus_surface')),
    );
    final decoration = surface.decoration! as BoxDecoration;

    expect(decoration.boxShadow, isEmpty);
    expect(
      tester.widget<Icon>(find.byIcon(Icons.mail_outline)).color,
      AppColors.brandPrimary,
    );
  });

  testWidgets('text field error motion stays subtle and settles in place', (
    tester,
  ) async {
    String? errorText;
    late StateSetter updateField;
    await tester.pumpWidget(
      _testHost(
        StatefulBuilder(
          builder: (context, setState) {
            updateField = setState;
            return RikiTextField(
              label: 'Email học viên',
              errorText: errorText,
              prefixIcon: Icons.mail_outline,
            );
          },
        ),
      ),
    );

    updateField(() {
      errorText = 'Email không hợp lệ.';
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 55));

    final motion = tester.widget<AnimatedBuilder>(
      find.byKey(const ValueKey<String>('riki_text_field_error_motion')),
    );
    expect((motion.animation as Animation<double>).value.abs(), greaterThan(0));

    await tester.pumpAndSettle();
    expect((motion.animation as Animation<double>).value, 0);
    expect(find.text('Email không hợp lệ.'), findsOneWidget);
    expect(tester.takeException(), isNull);
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

  test(
    'all 18 Sakura3DIconType assets exist on disk and are valid WebP files',
    () {
      expect(Sakura3DIconType.values.length, 18);
      for (final iconType in Sakura3DIconType.values) {
        final file = File(iconType.assetPath);
        expect(
          file.existsSync(),
          isTrue,
          reason: 'Missing 3D icon asset: ${iconType.assetPath}',
        );
        final bytes = file.readAsBytesSync();
        expect(
          bytes.length,
          greaterThan(1024),
          reason: '3D icon asset is unexpectedly small: ${iconType.assetPath}',
        );
        expect(String.fromCharCodes(bytes.sublist(0, 4)), 'RIFF');
        expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WEBP');
      }
    },
  );

  testWidgets('Sakura3DIcon renders all 18 3D icon types cleanly', (
    tester,
  ) async {
    await tester.pumpWidget(
      _testHost(
        Wrap(
          spacing: AppSpacing.space2,
          runSpacing: AppSpacing.space2,
          children: [
            for (final type in Sakura3DIconType.values)
              Sakura3DIcon(type: type, size: 32),
          ],
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(Sakura3DIcon), findsNWidgets(18));
    expect(tester.takeException(), isNull);
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
