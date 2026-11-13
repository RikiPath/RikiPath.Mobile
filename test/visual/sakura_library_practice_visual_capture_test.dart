import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/sakura_app_header.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_library_home.dart';
import 'package:rikipath_mobile/features/mock_test/presentation/practice_screen.dart';
import 'package:rikipath_mobile/features/notebook/application/notebook_controller.dart';
import 'package:rikipath_mobile/features/notebook/domain/notebook.dart';
import 'package:rikipath_mobile/features/notebook/presentation/widgets/notebook_view.dart';
import 'package:rikipath_mobile/features/shared_bank/presentation/shared_bank_screen.dart';
import 'package:rikipath_mobile/features/practice/application/daily_review_controller.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

class _FakeDailyReviewController extends DailyReviewController {
  _FakeDailyReviewController(this._state);

  final DailyReviewState _state;

  @override
  Future<DailyReviewState> build() async => _state;
}

void main() {
  final targetDir = Directory(
    r'C:\Users\ADMIN\.gemini\antigravity\brain\e3992171-3ce2-4736-abc5-aba1234129ce',
  );

  Future<void> captureScreen(
    WidgetTester tester, {
    required String fileName,
    required Widget child,
    double width = 393.0,
    double height = 852.0,
  }) async {
    final boundaryKey = GlobalKey();

    tester.view.physicalSize = Size(width * 2, height * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dailyReviewControllerProvider.overrideWith(
            () => _FakeDailyReviewController(
              const DailyReviewState(
                cards: [],
                currentIndex: 0,
              ),
            ),
          ),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [Locale('vi'), Locale('ja')],
          locale: const Locale('vi'),
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, height),
              textScaler: TextScaler.noScaling,
            ),
            child: RepaintBoundary(
              key: boundaryKey,
              child: SizedBox(
                width: width,
                height: height,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final boundary =
        boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      final bytes = byteData!.buffer.asUint8List();

      final file = File(
        '${targetDir.path}${Platform.pathSeparator}$fileName.png',
      );
      file.writeAsBytesSync(bytes);
      // ignore: avoid_print
      print('Saved visual capture: ${file.path} (${bytes.length} bytes)');
    });

    await tester.pumpWidget(const SizedBox());
  }

  testWidgets('Visual Capture 01: Library Home with edge-to-edge compact banner and 3D icons', (
    tester,
  ) async {
    await captureScreen(
      tester,
      fileName: 'sakura_library_home_aligned',
      child: Scaffold(
        backgroundColor: AppColors.learnerBackground,
        appBar: AppBar(
          title: const Text('Thư viện học tập'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF302B33),
          elevation: 0,
        ),
        body: const LearningLibraryHome(),
      ),
    );
  });

  testWidgets('Visual Capture 02: Practice Home with edge-to-edge banner and distinct 3D icons', (
    tester,
  ) async {
    await captureScreen(
      tester,
      fileName: 'sakura_practice_home_aligned',
      child: const PracticeScreen(),
    );
  });

  testWidgets('Visual Capture 03: Shared Bank with 3D contextual icons', (
    tester,
  ) async {
    await captureScreen(
      tester,
      fileName: 'sakura_shared_bank_aligned',
      child: const SharedBankScreen(),
    );
  });

  testWidgets('Visual Capture 04: Learning Screen with Compact Tab Switcher and Library Banner', (
    tester,
  ) async {
    await captureScreen(
      tester,
      fileName: 'sakura_learning_tab_switcher_compact',
      child: Scaffold(
        backgroundColor: AppColors.learnerBackground,
        appBar: AppBar(
          title: const Text('RikiPath'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF302B33),
          elevation: 0,
        ),
        body: const SafeArea(
          top: false,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: _StaticTabSwitcherPreview(),
              ),
              Expanded(child: LearningLibraryHome()),
            ],
          ),
        ),
      ),
    );
  });

  testWidgets(
    'Visual Capture 05: Notebook Home with edge-to-edge compact banner flush against header',
    (tester) async {
      await captureScreen(
        tester,
        fileName: 'sakura_notebook_banner_full_width',
        child: Scaffold(
          backgroundColor: AppColors.learnerBackground,
          appBar: const SakuraAppHeader(),
          body: NotebookView(
            state: const NotebookLibraryState(
              collections: [],
              localEntries: [],
              liveEntries: [],
              isCreatingCollection: false,
            ),
            onCreateCollection: () {},
            onOpenCollection: (_) {},
            onDismissMutationError: () {},
          ),
        ),
      );
    },
  );
}

class _StaticTabSwitcherPreview extends StatelessWidget {
  const _StaticTabSwitcherPreview();

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final halfWidth = constraints.maxWidth / 2;
      return Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF1EDEF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 3,
              bottom: 3,
              left: halfWidth,
              width: halfWidth - 3,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 1.5),
                    ),
                  ],
                ),
              ),
            ),
            const Row(
              children: [
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 17,
                          color: AppColors.textSecondary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Lộ trình',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 17,
                          color: AppColors.brandPrimary,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Thư viện',
                          style: TextStyle(
                            color: AppColors.brandPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: -0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}
