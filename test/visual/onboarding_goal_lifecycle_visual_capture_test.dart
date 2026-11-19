// Deterministic visual capture harness for the Onboarding & Learning Goal Lifecycle.
//
// Renders all 15 required Create / Edit / Summary / Toast / Error states with
// real fonts and writes PNG screenshots when RIKI_CAPTURE_DIR is set.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/router/app_router.dart';
import 'package:rikipath_mobile/app/router/app_routes.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/errors/api_error.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/widgets/riki_toast_host.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/features/catalog/application/jlpt_catalog_controller.dart';
import 'package:rikipath_mobile/features/onboarding/domain/jlpt_exam_session.dart';
import 'package:rikipath_mobile/features/placement_test/application/placement_test_controller.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test.dart';
import 'package:rikipath_mobile/features/placement_test/domain/placement_test_repository.dart';
import 'package:rikipath_mobile/features/profile/application/user_profile_controller.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile.dart';
import 'package:rikipath_mobile/features/profile/domain/user_profile_repository.dart';

import '../support/test_auth_session.dart';
import '../support/test_jlpt_catalog.dart';

final String? _outputDirectory = Platform.environment['RIKI_CAPTURE_DIR'];

void main() {
  final skip = _outputDirectory == null || _outputDirectory!.isEmpty;

  setUpAll(() async {
    if (skip) return;
    await _loadFonts();
  });

  testWidgets(
    'capture all 15 onboarding and learning goal lifecycle states',
    (tester) async {
      const size = Size(393, 873);
      tester.view.physicalSize = size * 2;
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.reset);

      final profileRepository = _CaptureProfileRepository();
      final placementRepository = _CapturePlacementRepository();
      final session = createTestAuthSession();
      final container = ProviderContainer(
        overrides: [
          authSessionControllerProvider.overrideWithValue(session),
          jlptCatalogRepositoryProvider.overrideWithValue(
            TestJlptCatalogRepository(),
          ),
          userProfileRepositoryProvider.overrideWithValue(profileRepository),
          placementTestRepositoryProvider.overrideWithValue(
            placementRepository,
          ),
        ],
      );
      final router = createAppRouter(
        authSession: session,
        initialLocation: AppRoutes.onboarding,
      );
      addTearDown(container.dispose);
      addTearDown(session.dispose);
      addTearDown(router.dispose);

      const boundaryKey = ValueKey<String>('goal_lifecycle_capture_boundary');
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light.copyWith(
                textTheme: AppTheme.light.textTheme.apply(fontFamily: 'Roboto'),
                filledButtonTheme: FilledButtonThemeData(
                  style: AppTheme.light.filledButtonTheme.style?.copyWith(
                    textStyle: WidgetStatePropertyAll<TextStyle>(
                      AppTypography.buttonLabel.copyWith(fontFamily: 'Roboto'),
                    ),
                  ),
                ),
                outlinedButtonTheme: OutlinedButtonThemeData(
                  style: AppTheme.light.outlinedButtonTheme.style?.copyWith(
                    textStyle: WidgetStatePropertyAll<TextStyle>(
                      AppTypography.buttonLabel.copyWith(fontFamily: 'Roboto'),
                    ),
                  ),
                ),
                textButtonTheme: TextButtonThemeData(
                  style: AppTheme.light.textButtonTheme.style?.copyWith(
                    textStyle: WidgetStatePropertyAll<TextStyle>(
                      AppTypography.buttonLabel.copyWith(fontFamily: 'Roboto'),
                    ),
                  ),
                ),
              ),
              locale: const Locale('vi'),
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              routerConfig: router,
              builder: (context, child) =>
                  RikiToastHost(child: child ?? const SizedBox.shrink()),
            ),
          ),
        ),
      );
      await _settleAndPrecache(tester);

      // 1. Create Step 1
      await tester.tap(find.byKey(const ValueKey<String>('current_level_n5')));
      await _settleAndPrecache(tester);
      await _writeBoundary(tester, boundaryKey, '01_create_step1');

      // 2. Create Step 2
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_continue_button')),
      );
      await _settleAndPrecache(tester);
      await tester.tap(find.byKey(const ValueKey<String>('jlpt_n3')));
      await _settleAndPrecache(tester);
      await _writeBoundary(tester, boundaryKey, '02_create_step2');

      // 3. Certificate checkbox expanded
      tester.view.physicalSize = const Size(393, 1020) * 2;
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_has_certificate')),
      );
      await _settleAndPrecache(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('certified_level_n4')),
      );
      await _settleAndPrecache(tester);
      await _writeBoundary(tester, boundaryKey, '03_certificate_expanded');
      tester.view.physicalSize = size * 2;
      await tester.pumpAndSettle();

      // 4. Create Step 3
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_continue_button')),
      );
      await _settleAndPrecache(tester);
      await tester.tap(find.byKey(const ValueKey<String>('study_time_45')));
      await _settleAndPrecache(tester);
      await _writeBoundary(tester, boundaryKey, '04_create_step3');

      // 5. Custom minutes
      await tester.ensureVisible(
        find.byKey(const ValueKey<String>('study_time_custom')),
      );
      await tester.tap(find.byKey(const ValueKey<String>('study_time_custom')));
      await _settleAndPrecache(tester);
      final customField = find.byType(TextFormField);
      await tester.ensureVisible(customField);
      await tester.enterText(customField, '75');
      await _settleAndPrecache(tester);
      await _writeBoundary(tester, boundaryKey, '05_custom_minutes');

      // 6. Exam July/December selector
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_study_continue_button')),
      );
      await _settleAndPrecache(tester);
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_exam_date_button')),
      );
      await _settleAndPrecache(tester);
      final now = DateTime.now().toUtc();
      final year = JlptExamCalendar.availableYears(now).first;
      final sessionChoice = JlptExamCalendar.futureSessions(year, now).first;
      await tester.tap(
        find.byKey(ValueKey<String>('exam_session_${sessionChoice.month}')),
      );
      await _settleAndPrecache(tester);
      await _writeBoundary(tester, boundaryKey, '06_exam_session_selector');

      // 7. Create Step 4
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_confirm_exam_session')),
      );
      await _settleAndPrecache(tester);
      await _writeBoundary(tester, boundaryKey, '07_create_step4');

      // 15. Save error with preserved form (capture before succeeding)
      profileRepository.failNextSave = true;
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_complete_button')),
      );
      await _settleAndPrecache(tester);
      await _writeBoundary(tester, boundaryKey, '15_save_error_preserved_form');

      // 8. Completion screen
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_complete_button')),
      );
      await _settleAndPrecache(tester);
      await _writeBoundary(tester, boundaryKey, '08_completion_screen');

      // 9. Goal Summary
      router.go(AppRoutes.profileJlptGoal);
      await _settleAndPrecache(tester);
      await _writeBoundary(tester, boundaryKey, '09_goal_summary');

      // 10. Edit Step 1 prefilled
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey<String>('jlpt_goal_edit_button')),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('jlpt_goal_edit_button')),
      );
      await _settleAndPrecache(tester);
      await _writeBoundary(tester, boundaryKey, '10_edit_step1_prefilled');

      // 11. Edit Step 2 certificate prefilled
      tester.view.physicalSize = const Size(393, 1020) * 2;
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_continue_button')),
      );
      await _settleAndPrecache(tester);
      await _writeBoundary(
        tester,
        boundaryKey,
        '11_edit_step2_certificate_prefilled',
      );
      tester.view.physicalSize = size * 2;
      await tester.pumpAndSettle();

      // 12. Edit Step 3 minutes prefilled
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_continue_button')),
      );
      await _settleAndPrecache(tester);
      await _writeBoundary(
        tester,
        boundaryKey,
        '12_edit_step3_minutes_prefilled',
      );

      // 13. Edit Step 4 exam prefilled
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_study_continue_button')),
      );
      await _settleAndPrecache(tester);
      await _writeBoundary(tester, boundaryKey, '13_edit_step4_exam_prefilled');

      // 14. Save success notification on Goal Summary
      await tester.tap(
        find.byKey(const ValueKey<String>('onboarding_complete_button')),
      );
      for (var frame = 0; frame < 4; frame++) {
        await tester.pump(const Duration(milliseconds: 80));
      }
      await _writeBoundary(tester, boundaryKey, '14_edit_save_success_toast');
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
    },
    skip: skip,
  );
}

Future<void> _settleAndPrecache(WidgetTester tester) async {
  for (var frame = 0; frame < 5; frame++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
  await tester.runAsync(() async {
    for (final element in find.byType(Image).evaluate()) {
      final widget = element.widget as Image;
      await precacheImage(widget.image, element);
    }
  });
  for (var frame = 0; frame < 5; frame++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
  expect(tester.takeException(), isNull);
}

Future<void> _writeBoundary(
  WidgetTester tester,
  Key boundaryKey,
  String fileName,
) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(boundaryKey),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    final directory = Directory(_outputDirectory!)..createSync(recursive: true);
    File(
      '${directory.path}${Platform.pathSeparator}$fileName.png',
    ).writeAsBytesSync(bytes!.buffer.asUint8List());
  });
}

Future<void> _loadFonts() async {
  final envRoot = Platform.environment['FLUTTER_ROOT'] ?? r'D:\flutter';
  final sdkFonts = '$envRoot/bin/cache/artifacts/material_fonts';

  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    var added = false;
    for (final path in paths) {
      final file = File(path);
      if (!file.existsSync()) continue;
      final bytes = file.readAsBytesSync();
      loader.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
      added = true;
    }
    if (added) await loader.load();
  }

  final roboto = <String>[
    '$sdkFonts/roboto-regular.ttf',
    '$sdkFonts/roboto-medium.ttf',
    '$sdkFonts/roboto-bold.ttf',
    '$sdkFonts/roboto-black.ttf',
  ];
  await load('Roboto', roboto);
  await load('FlutterTest', roboto);
  await load('Noto Sans', roboto);
  await load('MaterialIcons', <String>[
    '$sdkFonts/materialicons-regular.otf',
  ]);
  await load('Noto Sans JP', <String>[
    r'C:\Windows\Fonts\YuGothM.ttc',
    r'C:\Windows\Fonts\msgothic.ttc',
  ]);
}

class _CaptureProfileRepository
    implements UserProfileRepository, AtomicLearningGoalProfileRepository {
  int? currentStudyLevelId;
  int? targetJlptLevelId;
  int dailyStudyMinutes = 0;
  DateTime? targetExamDate;
  int? certifiedJlptLevelId;
  int learningGoalVersion = 0;
  bool failNextSave = false;

  String? _codeFor(int? id) =>
      testJlptCatalog.where((item) => item.id == id).firstOrNull?.code;

  @override
  Future<UserProfile> loadProfile() async => _buildProfile();

  @override
  Future<UserProfile> saveLearningGoal({
    required int currentStudyLevelId,
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
    required DateTime? targetExamDate,
    required int? certifiedJlptLevelId,
    required int expectedVersion,
  }) async {
    if (failNextSave) {
      failNextSave = false;
      throw const NetworkError(message: 'Simulated failure');
    }
    this.currentStudyLevelId = currentStudyLevelId;
    this.targetJlptLevelId = targetJlptLevelId;
    this.dailyStudyMinutes = dailyStudyMinutes;
    this.targetExamDate = targetExamDate;
    this.certifiedJlptLevelId = certifiedJlptLevelId;
    learningGoalVersion = expectedVersion + 1;
    return _buildProfile();
  }

  @override
  Future<UserProfile> setJlptGoal({
    required int targetJlptLevelId,
    required int dailyStudyMinutes,
  }) async => _buildProfile();

  @override
  Future<UserProfile> updateNotificationSettings({
    required bool emailNotificationsEnabled,
    required bool systemNotificationsEnabled,
  }) async => _buildProfile();

  @override
  Future<UserProfile> updateProfile({required String fullName}) async =>
      _buildProfile();

  @override
  Future<UserProfile> uploadAvatar(ProfileAvatarUpload upload) async =>
      _buildProfile();

  UserProfile _buildProfile() => UserProfile(
    userId: 42,
    email: 'learner@rikipath.edu.vn',
    firstName: 'Minh Anh',
    lastName: 'Nguyễn',
    avatarUrl: null,
    role: 'Learner',
    isEmailVerified: true,
    targetJlptLevelId: targetJlptLevelId,
    targetJlptLevelName: _codeFor(targetJlptLevelId),
    currentStudyLevelId: currentStudyLevelId,
    currentStudyLevelName: _codeFor(currentStudyLevelId),
    dailyStudyMinutes: dailyStudyMinutes,
    targetExamDate: targetExamDate,
    learningGoalVersion: learningGoalVersion,
    certifiedJlptLevelId: certifiedJlptLevelId,
    certifiedJlptLevelName: _codeFor(certifiedJlptLevelId),
    emailNotificationsEnabled: true,
    systemNotificationsEnabled: true,
  );
}

class _CapturePlacementRepository
    implements PlacementTestRepository, PlacementSkipRepository {
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
