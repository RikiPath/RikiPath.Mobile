import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/features/notebook/presentation/widgets/notebook_empty_hero_banner.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

void main() {
  Widget buildTestWidget({
    Locale locale = const Locale('vi'),
    double width = 393.0,
    double textScale = 1.0,
    VoidCallback? onTap,
  }) {
    return MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: locale,
      home: MediaQuery(
        data: MediaQueryData(
          size: Size(width, 852.0),
          textScaler: TextScaler.linear(textScale),
        ),
        child: Scaffold(
          body: Center(
            child: SizedBox(
              width: width,
              child: SakuraNotebookEmptyBanner(onTap: onTap),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('SakuraNotebookEmptyBanner renders Vietnamese copy by default', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('がんばろう！'), findsOneWidget);
    expect(find.text('Bắt đầu sổ từ của bạn!'), findsOneWidget);
    expect(
      find.text('Lưu lại những từ vựng và mẫu câu yêu thích.'),
      findsOneWidget,
    );
  });

  testWidgets('SakuraNotebookEmptyBanner renders Japanese copy when locale is ja', (
    tester,
  ) async {
    await tester.pumpWidget(buildTestWidget(locale: const Locale('ja')));
    await tester.pumpAndSettle();

    expect(find.text('がんばろう！'), findsOneWidget);
    expect(find.text('単語帳を始めましょう！'), findsOneWidget);
    expect(
      find.text('お気に入りの単語や文型を保存しましょう。'),
      findsOneWidget,
    );
  });

  testWidgets('SakuraNotebookEmptyBanner responds to tap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(buildTestWidget(onTap: () => tapped = true));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SakuraNotebookEmptyBanner));
    expect(tapped, isTrue);
  });

  for (final width in [360.0, 393.0, 412.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('Banner fits ${width}dp width at ${scale}x text scale without overflow', (
        tester,
      ) async {
        await tester.pumpWidget(buildTestWidget(width: width, textScale: scale));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.byType(SakuraNotebookEmptyBanner), findsOneWidget);
      });
    }
  }
}
