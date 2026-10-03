import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/widgets/riki_design_system.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

void main() {
  test(
    'learner-facing fallback copy avoids implementation terminology',
    () async {
      for (final locale in const <Locale>[Locale('vi'), Locale('ja')]) {
        final l10n = await AppLocalizations.delegate.load(locale);
        final visibleCopy = <String>[
          l10n.localFixtureNotice,
          l10n.stitchFixtureNotice,
          l10n.strokeFixtureWarning,
          l10n.strokeImageOnlyWarning,
          l10n.grammarFixtureNotice,
          l10n.notebookApiFieldsHint,
          l10n.notificationSettingsSubtitle,
          l10n.jlptGoalMappingUnavailableMessage,
          l10n.jlptSelectionSafeHint,
          l10n.profileConsultationSubtitle,
        ].join(' ').toLowerCase();

        expect(visibleCopy, isNot(contains('fixture')));
        expect(visibleCopy, isNot(contains('stitch')));
        expect(visibleCopy, isNot(contains('backend')));
        expect(visibleCopy, isNot(contains('api')));
        expect(visibleCopy, isNot(contains('バックエンド')));
      }
    },
  );

  testWidgets('empty state remains readable on a 320px phone', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var actions = 0;

    await tester.pumpWidget(
      _host(
        RikiEmptyState(
          icon: Icons.bookmark_border,
          title: 'Danh sách chưa có từ',
          message: 'Thêm từ đầu tiên để bắt đầu ôn tập trong danh sách này.',
          actionLabel: 'Thêm từ mới',
          onAction: () => actions += 1,
        ),
      ),
    );

    expect(find.text('Danh sách chưa có từ'), findsOneWidget);
    expect(find.byType(RikiSecondaryButton), findsOneWidget);
    await tester.tap(find.text('Thêm từ mới'));
    await tester.pump();
    expect(actions, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('error state exposes a clear retry action', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      _host(
        RikiErrorState(
          title: 'Chưa thể tải nội dung',
          message: 'Kiểm tra kết nối rồi thử lại.',
          actionLabel: 'Thử lại',
          onAction: () => retries += 1,
        ),
      ),
    );

    expect(find.byIcon(Icons.cloud_off_outlined), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    await tester.tap(find.text('Thử lại'));
    await tester.pump();
    expect(retries, 1);
  });

  testWidgets('confirmation dialog keeps cancel before destructive action', (
    tester,
  ) async {
    bool? result;
    await tester.pumpWidget(
      _host(
        Builder(
          builder: (context) => FilledButton(
            onPressed: () async {
              result = await showRikiConfirmationDialog(
                context: context,
                title: 'Xóa mục đã lưu?',
                message: 'Mục này sẽ bị xóa khỏi Sổ từ.',
                confirmLabel: 'Xóa',
                cancelLabel: 'Hủy',
                destructive: true,
              );
            },
            child: const Text('Mở'),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Mở'));
    await tester.pumpAndSettle();
    expect(find.byType(RikiConfirmationDialog), findsOneWidget);

    final actionLabels = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byType(RikiConfirmationDialog),
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data)
        .whereType<String>()
        .toList();
    expect(actionLabels.indexOf('Hủy'), lessThan(actionLabels.indexOf('Xóa')));

    await tester.tap(find.text('Xóa'));
    await tester.pumpAndSettle();
    expect(result, isTrue);
  });

  testWidgets('progress indicator supports a stable emphasized height', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const RikiProgressIndicator(
          value: 0.5,
          minHeight: 8,
          semanticsLabel: 'Tiến độ 50 phần trăm',
        ),
      ),
    );

    expect(tester.getSize(find.byType(LinearProgressIndicator)).height, 8);
  });
}

Widget _host(Widget child) {
  return MaterialApp(
    theme: AppTheme.light,
    locale: const Locale('vi'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}
