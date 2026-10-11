import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/locale_preference_store.dart';
import 'package:rikipath_mobile/features/learning/presentation/widgets/learning_header.dart';

void main() {
  testWidgets('learning headers keep the shared 64 pixel geometry', (
    tester,
  ) async {
    const rootHeader = LearningHeader.root(
      streakDays: 7,
      hasUnreadNotifications: true,
    );

    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(rootHeader));
    await tester.pump();

    expect(rootHeader.preferredSize.height, 64);
    expect(tester.getSize(find.byType(AppBar)).height, 64);
    expect(find.text('RikiPath'), findsOneWidget);
    expect(find.text('N4'), findsNothing);
    expect(find.byKey(const Key('language_switcher_button')), findsOneWidget);
    expect(tester.takeException(), isNull);

    const detailHeader = LearningHeader.detail(
      title: 'Chi tiết ngữ pháp với tiêu đề rất dài',
      subtitle: 'NGỮ PHÁP',
      onBack: _noop,
    );

    await tester.pumpWidget(_host(detailHeader));
    await tester.pump();

    expect(detailHeader.preferredSize.height, 64);
    expect(tester.getSize(find.byType(AppBar)).height, 64);

    final backButton = find.byKey(const Key('learning_detail_back_button'));
    final detailTitle = find.byKey(const Key('learning_detail_title'));

    expect(tester.getSize(backButton), const Size.square(40));
    expect(
      tester.getTopRight(backButton).dx,
      lessThan(tester.getTopLeft(detailTitle).dx),
    );

    expect(find.text('N4'), findsNothing);
    expect(find.byKey(const Key('language_switcher_button')), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(find.text('NGỮ PHÁP'), findsOneWidget);
    expect(find.byTooltip('Quay lại'), findsOneWidget);
  });
}

Widget _host(PreferredSizeWidget header) {
  return ProviderScope(
    overrides: [
      localePreferenceStoreProvider.overrideWithValue(
        const _TestLocalePreferenceStore(),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(appBar: header, body: const SizedBox.expand()),
    ),
  );
}

void _noop() {}

class _TestLocalePreferenceStore implements LocalePreferenceStore {
  const _TestLocalePreferenceStore();

  @override
  Future<String?> readLanguageCode() async => 'vi';

  @override
  Future<void> writeLanguageCode(String languageCode) async {}
}
