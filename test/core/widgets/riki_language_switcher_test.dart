import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/localization/locale_preference_store.dart';
import 'package:rikipath_mobile/core/widgets/riki_language_switcher.dart';
import 'package:rikipath_mobile/features/auth/application/auth_session_controller.dart';
import 'package:rikipath_mobile/l10n/generated/app_localizations.dart';

import '../../support/test_auth_session.dart';

void main() {
  testWidgets('popover opens, shows selection, and outside tap dismisses it', (
    tester,
  ) async {
    final store = _MemoryLocalePreferenceStore('vi');
    await _pumpSwitcher(tester, store: store);

    expect(find.text('VI'), findsOneWidget);
    await tester.tap(find.byKey(const Key('language_switcher_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('language_switcher_popover')), findsOneWidget);
    expect(find.text('Tiếng Việt'), findsOneWidget);
    expect(find.text('日本語'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('assets/flags/vi.svg')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('assets/flags/ja.svg')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('language_selected_indicator')),
      findsOneWidget,
    );
    expect(
      tester
          .widget<Icon>(find.byKey(const Key('language_selected_indicator')))
          .color,
      AppColors.brandPrimary,
    );

    final flagRect = tester.getRect(
      find.byKey(const ValueKey<String>('assets/flags/vi.svg')),
    );
    final labelRect = tester.getRect(find.text('Tiếng Việt'));
    final checkRect = tester.getRect(
      find.byKey(const Key('language_selected_indicator')),
    );
    expect(flagRect.right, lessThan(labelRect.left));
    expect(labelRect.right, lessThan(checkRect.left));

    await tester.tapAt(const Offset(12, 500));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('language_switcher_popover')), findsNothing);
  });

  testWidgets(
    'switching vi to ja and back preserves route, form, and auth session',
    (tester) async {
      final store = _MemoryLocalePreferenceStore('vi');
      final session = createTestAuthSession();
      addTearDown(session.dispose);
      await _pumpSwitcher(tester, store: store, session: session);

      await tester.enterText(
        find.byKey(const Key('locale_test_field')),
        'draft value',
      );
      await tester.tap(find.byKey(const Key('language_switcher_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('language_option_ja')));
      await tester.pumpAndSettle();

      expect(find.text('JA'), findsOneWidget);
      expect(find.text('current-route:/profile'), findsOneWidget);
      expect(find.text('draft value'), findsOneWidget);
      expect(session.value, AuthSessionState.authenticated);
      expect(session.currentUserId, 42);
      expect(store.languageCode, 'ja');

      await tester.tap(find.byKey(const Key('language_switcher_button')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('language_option_vi')));
      await tester.pumpAndSettle();

      expect(find.text('VI'), findsOneWidget);
      expect(find.text('current-route:/profile'), findsOneWidget);
      expect(find.text('draft value'), findsOneWidget);
      expect(store.writes, <String>['ja', 'vi']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('popover fits a narrow phone without overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpSwitcher(tester, store: _MemoryLocalePreferenceStore('ja'));
    await tester.tap(find.byKey(const Key('language_switcher_button')));
    await tester.pumpAndSettle();

    final popoverRect = tester.getRect(
      find.byKey(const Key('language_switcher_popover')),
    );
    expect(popoverRect.left, greaterThanOrEqualTo(0));
    expect(popoverRect.right, lessThanOrEqualTo(320));
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpSwitcher(
  WidgetTester tester, {
  required _MemoryLocalePreferenceStore store,
  AuthSessionController? session,
}) async {
  final effectiveSession = session ?? createTestAuthSession();
  if (session == null) addTearDown(effectiveSession.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        localePreferenceStoreProvider.overrideWithValue(store),
        authSessionControllerProvider.overrideWithValue(effectiveSession),
      ],
      child: const _LocaleTestApp(),
    ),
  );
  await tester.pumpAndSettle();
}

class _LocaleTestApp extends ConsumerWidget {
  const _LocaleTestApp();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      theme: AppTheme.light,
      locale: ref.watch(localeControllerProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      initialRoute: '/profile',
      routes: {
        '/profile': (context) => Scaffold(
          appBar: AppBar(actions: const [RikiLanguageSwitcher()]),
          body: Builder(
            builder: (context) => Column(
              children: [
                Text('current-route:${ModalRoute.of(context)!.settings.name}'),
                const TextField(key: Key('locale_test_field')),
              ],
            ),
          ),
        ),
      },
    );
  }
}

class _MemoryLocalePreferenceStore implements LocalePreferenceStore {
  _MemoryLocalePreferenceStore(this.languageCode);

  String? languageCode;
  final List<String> writes = <String>[];

  @override
  Future<String?> readLanguageCode() async => languageCode;

  @override
  Future<void> writeLanguageCode(String languageCode) async {
    this.languageCode = languageCode;
    writes.add(languageCode);
  }
}
