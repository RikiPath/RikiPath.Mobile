import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/app/theme/app_theme.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/localization/localization.dart';
import 'package:rikipath_mobile/core/notifications/riki_toast_service.dart';
import 'package:rikipath_mobile/core/widgets/riki_toast_host.dart';

void main() {
  testWidgets('success toast renders its accessible Sakura treatment', (
    tester,
  ) async {
    final container = await _pumpToastApp(tester);
    final l10n = appLocalizationsFor(const Locale('vi'));

    container
        .read(rikiToastServiceProvider.notifier)
        .success(
          title: l10n.toastProfileUpdateSuccessTitle,
          description: l10n.profileUpdateSuccess,
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(
      find.byKey(const ValueKey<String>('riki_toast_success')),
      findsOneWidget,
    );
    expect(find.text(l10n.toastProfileUpdateSuccessTitle), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('riki_toast_icon_success')),
      findsOneWidget,
    );
  });

  testWidgets('error toast is visually distinct and never exposes raw data', (
    tester,
  ) async {
    final container = await _pumpToastApp(tester);
    final l10n = appLocalizationsFor(const Locale('vi'));

    container
        .read(rikiToastServiceProvider.notifier)
        .error(
          title: l10n.toastActionFailedTitle,
          description: l10n.profileErrorNetwork,
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(
      find.byKey(const ValueKey<String>('riki_toast_error')),
      findsOneWidget,
    );
    expect(find.text(l10n.profileErrorNetwork), findsOneWidget);
    expect(find.textContaining('traceId'), findsNothing);
  });

  testWidgets('toast automatically dismisses and consumes its event', (
    tester,
  ) async {
    final container = await _pumpToastApp(tester);
    final l10n = appLocalizationsFor(const Locale('vi'));

    container
        .read(rikiToastServiceProvider.notifier)
        .info(
          title: l10n.appTitle,
          description: l10n.preparingLearningSubtext,
          duration: const Duration(milliseconds: 300),
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 180));

    expect(find.byKey(const ValueKey<String>('riki_toast_info')), findsNothing);
    expect(container.read(rikiToastServiceProvider), isEmpty);

    await tester.pump();
    expect(find.byKey(const ValueKey<String>('riki_toast_info')), findsNothing);
  });

  testWidgets('toast supports manual dismissal', (tester) async {
    final container = await _pumpToastApp(tester);
    final l10n = appLocalizationsFor(const Locale('vi'));
    final id = container
        .read(rikiToastServiceProvider.notifier)
        .warning(title: l10n.toastActionFailedTitle);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    await tester.tap(find.byKey(ValueKey<String>('riki_toast_close_$id')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('riki_toast_warning')),
      findsNothing,
    );
    expect(container.read(rikiToastServiceProvider), isEmpty);
  });

  testWidgets('toast survives a route replacement', (tester) async {
    await _pumpToastApp(tester, home: const _RouteStart());

    await tester.tap(find.byKey(const ValueKey<String>('show_and_navigate')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(find.text('destination'), findsOneWidget);
    expect(find.text('RikiPath'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('riki_toast_info')),
      findsOneWidget,
    );
  });

  for (final locale in const [Locale('vi'), Locale('ja')]) {
    testWidgets('toast uses ${locale.languageCode} localized resources', (
      tester,
    ) async {
      final container = await _pumpToastApp(tester, locale: locale);
      final l10n = appLocalizationsFor(locale);

      container
          .read(rikiToastServiceProvider.notifier)
          .success(
            title: l10n.toastVerifyEmailSuccessTitle,
            description: l10n.toastVerifyEmailSuccessDescription,
          );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 220));

      expect(find.text(l10n.toastVerifyEmailSuccessTitle), findsOneWidget);
      expect(
        find.text(l10n.toastVerifyEmailSuccessDescription),
        findsOneWidget,
      );
    });
  }

  testWidgets('toast fits a 320px portrait screen without overflow', (
    tester,
  ) async {
    final container = await _pumpToastApp(tester, size: const Size(320, 568));
    final l10n = appLocalizationsFor(const Locale('ja'));

    container
        .read(rikiToastServiceProvider.notifier)
        .error(
          title: l10n.toastActionFailedTitle,
          description: l10n.profileErrorNetwork,
        );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(RikiToastHost)).width, 320);
  });

  testWidgets('rebuilding the app does not duplicate a one-shot toast', (
    tester,
  ) async {
    final container = await _pumpToastApp(tester, home: const _RebuildBody());
    final l10n = appLocalizationsFor(const Locale('vi'));

    container
        .read(rikiToastServiceProvider.notifier)
        .success(title: l10n.toastProfileUpdateSuccessTitle);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    await tester.tap(find.byKey(const ValueKey<String>('rebuild_body')));
    await tester.pump();

    expect(
      find.byKey(const ValueKey<String>('riki_toast_success')),
      findsOneWidget,
    );
    expect(container.read(rikiToastServiceProvider), hasLength(1));
  });
}

Future<ProviderContainer> _pumpToastApp(
  WidgetTester tester, {
  Locale locale = const Locale('vi'),
  Size size = const Size(390, 844),
  Widget home = const Scaffold(body: SizedBox.expand()),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final container = ProviderContainer();
  addTearDown(container.dispose);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (context, child) =>
            RikiToastHost(child: child ?? const SizedBox.shrink()),
        home: home,
      ),
    ),
  );
  await tester.pump();
  return container;
}

class _RouteStart extends ConsumerWidget {
  const _RouteStart();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: const ValueKey<String>('show_and_navigate'),
          onPressed: () {
            ref
                .read(rikiToastServiceProvider.notifier)
                .info(title: context.l10n.appTitle);
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) =>
                    const Scaffold(body: Center(child: Text('destination'))),
              ),
            );
          },
          child: const Text('show'),
        ),
      ),
    );
  }
}

class _RebuildBody extends StatefulWidget {
  const _RebuildBody();

  @override
  State<_RebuildBody> createState() => _RebuildBodyState();
}

class _RebuildBodyState extends State<_RebuildBody> {
  var _count = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: const ValueKey<String>('rebuild_body'),
          onPressed: () => setState(() => _count += 1),
          child: Text('rebuild $_count'),
        ),
      ),
    );
  }
}
