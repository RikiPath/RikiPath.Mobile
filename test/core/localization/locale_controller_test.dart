import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rikipath_mobile/core/localization/locale_controller.dart';
import 'package:rikipath_mobile/core/localization/locale_preference_store.dart';

void main() {
  test('unsupported device language defaults to Vietnamese', () {
    expect(resolveSupportedLocale(const Locale('en')), const Locale('vi'));
  });

  test('Japanese device language defaults to Japanese', () {
    expect(resolveSupportedLocale(const Locale('ja')), const Locale('ja'));
  });

  test('saved preference wins over the device default', () async {
    final store = _MemoryLocalePreferenceStore('ja');
    final container = ProviderContainer(
      overrides: [localePreferenceStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    container.read(localeControllerProvider);
    await container
        .read(localeControllerProvider.notifier)
        .restoreSavedLocale();

    expect(container.read(localeControllerProvider), const Locale('ja'));
  });

  test(
    'changing locale updates state and persists only the language code',
    () async {
      final store = _MemoryLocalePreferenceStore();
      final container = ProviderContainer(
        overrides: [localePreferenceStoreProvider.overrideWithValue(store)],
      );
      addTearDown(container.dispose);

      await container
          .read(localeControllerProvider.notifier)
          .changeLocale(const Locale('ja', 'JP'));

      expect(container.read(localeControllerProvider), const Locale('ja'));
      expect(store.languageCode, 'ja');
      expect(store.writes, <String>['ja']);

      await container
          .read(localeControllerProvider.notifier)
          .changeLocale(const Locale('vi'));
      expect(container.read(localeControllerProvider), const Locale('vi'));
      expect(store.writes, <String>['ja', 'vi']);
    },
  );

  test('an unsupported saved value is ignored', () async {
    final store = _MemoryLocalePreferenceStore('jp');
    final container = ProviderContainer(
      overrides: [localePreferenceStoreProvider.overrideWithValue(store)],
    );
    addTearDown(container.dispose);

    final initial = container.read(localeControllerProvider);
    await container
        .read(localeControllerProvider.notifier)
        .restoreSavedLocale();

    expect(container.read(localeControllerProvider), initial);
  });
}

class _MemoryLocalePreferenceStore implements LocalePreferenceStore {
  _MemoryLocalePreferenceStore([this.languageCode]);

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
