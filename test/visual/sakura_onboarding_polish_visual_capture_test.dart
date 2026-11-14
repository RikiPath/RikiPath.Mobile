import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/onboarding/presentation/onboarding_screen.dart';
import 'package:rikipath_mobile/features/placement_test/application/placement_test_controller.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test_repository.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

import '../support/test_jlpt_catalog.dart';

class _VisualPlacementRepo implements PlacementTestRepository, PlacementSkipRepository {
  @override
  Future<PlacementTestStatus> loadStatus() async => const PlacementTestStatus(
    hasCompletedPlacementTest: false,
  );

  @override
  Future<PlacementTestStatus> skip() async => const PlacementTestStatus(
    hasCompletedPlacementTest: false,
    placementDecision: PlacementDecision.skipped,
  );

  @override
  Future<PlacementTestAttempt?> loadActiveAttempt() async => null;

  @override
  Future<PlacementTestAttempt> start() => throw UnimplementedError();

  @override
  Future<PlacementTestResult> submit(
    int attemptId,
    List<PlacementTestAnswerSubmission> answers,
  ) => throw UnimplementedError();

  @override
  Future<PlacementTestResult> loadResult(int attemptId) =>
      throw UnimplementedError();
}

Future<void> _loadSystemFontsForVisualCapture() async {
  Future<ByteData?> readFont(String path) async {
    final file = File(path);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    return ByteData.sublistView(bytes);
  }

  final segoeRegular = await readFont(r'C:\Windows\Fonts\segoeui.ttf');
  final segoeSemiBold = await readFont(r'C:\Windows\Fonts\seguisb.ttf');
  final segoeBold = await readFont(r'C:\Windows\Fonts\segoeuib.ttf');
  final yuGothic = await readFont(r'C:\Windows\Fonts\YuGothM.ttc');

  for (final family in <String>[
    'Roboto',
    'Noto Sans',
    'Noto Sans JP',
    'FlutterTest',
    'sans-serif',
  ]) {
    final loader = FontLoader(family);
    if (segoeRegular != null) loader.addFont(Future.value(segoeRegular));
    if (segoeSemiBold != null) loader.addFont(Future.value(segoeSemiBold));
    if (segoeBold != null) loader.addFont(Future.value(segoeBold));
    if (yuGothic != null) loader.addFont(Future.value(yuGothic));
    await loader.load();
  }

  final sdkRoot = Platform.environment['FLUTTER_ROOT'];
  final materialCandidates = <String>[
    if (sdkRoot != null)
      '$sdkRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    r'C:\src\flutter\bin\cache\artifacts\material_fonts\MaterialIcons-Regular.otf',
    r'C:\flutter\bin\cache\artifacts\material_fonts\MaterialIcons-Regular.otf',
  ];
  for (final path in materialCandidates) {
    final data = await readFont(path);
    if (data != null) {
      final iconLoader = FontLoader('MaterialIcons')
        ..addFont(Future.value(data));
      await iconLoader.load();
      break;
    }
  }
}

ThemeData _visualTheme() {
  final base = AppTheme.light;
  const fontFallback = <String>['Roboto', 'Noto Sans', 'Noto Sans JP'];
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: 'Roboto',
      fontFamilyFallback: fontFallback,
    ),
    primaryTextTheme: base.primaryTextTheme.apply(
      fontFamily: 'Roboto',
      fontFamilyFallback: fontFallback,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: base.filledButtonTheme.style?.copyWith(
        textStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(
            fontFamily: 'Roboto',
            fontFamilyFallback: fontFallback,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: base.outlinedButtonTheme.style?.copyWith(
        textStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(
            fontFamily: 'Roboto',
            fontFamilyFallback: fontFallback,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: base.textButtonTheme.style?.copyWith(
        textStyle: const WidgetStatePropertyAll<TextStyle>(
          TextStyle(
            fontFamily: 'Roboto',
            fontFamilyFallback: fontFallback,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ),
  );
}

Future<void> _capturePng(
  WidgetTester tester,
  GlobalKey boundaryKey,
  String outPath,
) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 220));
  final boundary =
      boundaryKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
  final bytes = await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 2.5);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  });
  final file = File(outPath);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes!);
}

void main() {
  const artifactDir =
      r'C:\Users\ADMIN\.gemini\antigravity\brain\e3992171-3ce2-4736-abc5-aba1234129ce';

  setUpAll(() async {
    await _loadSystemFontsForVisualCapture();
  });

  testWidgets('Capture 6 Sakura Onboarding Polish Screenshots', (tester) async {
    tester.view.physicalSize = const Size(393, 852);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final boundaryKey = GlobalKey();
    final container = ProviderContainer(
      overrides: [
        jlptCatalogRepositoryProvider.overrideWithValue(
          TestJlptCatalogRepository(),
        ),
        placementTestRepositoryProvider.overrideWithValue(
          _VisualPlacementRepo(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: _visualTheme(),
            locale: const Locale('vi'),
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: const OnboardingScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Step 1 with Placement guidance
    await tester.tap(find.byKey(const ValueKey<String>('current_level_n5')));
    await tester.pumpAndSettle();
    await _capturePng(
      tester,
      boundaryKey,
      '$artifactDir\\sakura_onboarding_step1_placement.png',
    );

    // 2. Step 2 without Placement guidance
    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding_continue_button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('jlpt_n4')));
    await tester.pumpAndSettle();
    await _capturePng(
      tester,
      boundaryKey,
      '$artifactDir\\sakura_onboarding_step2_clean.png',
    );

    // 3. Step 3 with all contextual colored icons (unselected initial state)
    await tester.tap(
      find.byKey(const ValueKey<String>('onboarding_continue_button')),
    );
    await tester.pumpAndSettle();
    await _capturePng(
      tester,
      boundaryKey,
      '$artifactDir\\sakura_onboarding_step3_colored_icons.png',
    );

    // 4. Step 3 selected 15 minutes
    await tester.tap(find.byKey(const ValueKey<String>('study_time_15')));
    await tester.pumpAndSettle();
    await _capturePng(
      tester,
      boundaryKey,
      '$artifactDir\\sakura_onboarding_step3_selected_15m.png',
    );

    // 5. Step 3 selected 90 minutes
    await tester.tap(find.byKey(const ValueKey<String>('study_time_90')));
    await tester.pumpAndSettle();
    await _capturePng(
      tester,
      boundaryKey,
      '$artifactDir\\sakura_onboarding_step3_selected_90m.png',
    );

    // 6. Custom minutes input expanded
    final customCard = find.byKey(const ValueKey<String>('study_time_custom'));
    await tester.ensureVisible(customCard);
    await tester.tap(customCard);
    await tester.pumpAndSettle();
    final field = find.byType(TextFormField);
    await tester.ensureVisible(field);
    await tester.enterText(field, '75');
    await tester.pumpAndSettle();
    await _capturePng(
      tester,
      boundaryKey,
      '$artifactDir\\sakura_onboarding_step3_custom_expanded.png',
    );
  });
}
