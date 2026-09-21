# Localization Implementation

Reviewed on: 2026-09-19 (Asia/Bangkok)

## Architecture

RikiPath uses Flutter's official localization pipeline:

- `flutter_localizations` and `intl` provide framework localization support.
- `gen_l10n` reads `lib/l10n/app_vi.arb` and `lib/l10n/app_ja.arb`.
- Generated Dart files live under `lib/l10n/generated/`.
- `LocaleController` is the single Riverpod source of truth for the active
  locale.
- `MaterialApp.router` watches that controller and configures `locale`,
  `localizationsDelegates`, and `supportedLocales` without recreating the
  router.
- Presentation code reads translated labels through `context.l10n`; controllers
  that create user-facing validation/error text read `appLocalizationsProvider`.

Supported locale codes are exactly:

- Vietnamese: `vi`
- Japanese: `ja`

`jp` is not accepted as a locale code.

## Default and persistence behavior

`LocaleController` starts with Japanese only when the device language is
Japanese; every other device language starts in Vietnamese. It then restores
the stored preference. A valid stored `vi` or `ja` value always wins over the
device locale and is not replaced when the system language later changes.

The non-sensitive preference is stored by
`SharedPreferencesLocalePreferenceStore` under
`preferred_language_code`. Locale storage is intentionally separate from
secure authentication token storage. A storage failure does not prevent the app
from booting or changing its current in-memory language.

## Language switcher

`RikiLanguageSwitcher` replaces the old static language badge. Its collapsed
pill uses Flutter's language icon and displays `VI` or `JA`. The anchored
`OverlayPortal` menu contains Vietnamese and Japanese rows, a Sakura selected
state, semantic labels, keyboard focus traversal, Escape/Back dismissal, and an
outside-tap barrier.

Opening uses a 220 ms fade, `0.96 → 1.0` scale, and small upward-offset
transition with `easeOutCubic`. Closing uses 160 ms and `easeInCubic`. Reduced
motion removes scale/translation timing. Selecting a row gives brief feedback,
closes the menu, then updates the global locale. The current route, navigation
stack, form state, and authentication session are not reset.

The switcher is available in shared authentication headers and the learner
Profile app bar, so both signed-out and signed-in users can reach it.

## Translated production coverage

The ARB resources cover current user-facing application chrome and state text
for:

- Splash, Login, Register, Register Success, Verify Email, Forgot Password,
  Account Settings, Update Email, and Change Password
- Home, onboarding, Learning roadmap/progress/lesson surfaces
- Vocabulary, Kanji, Grammar, and Personal Notebook
- Practice and Profile
- bottom navigation, shared buttons, fields, banners, dialogs, accessibility
  labels, loading, empty, validation, and error states

The Register Success celebration remains structurally unchanged and is tested
in both locales. The Register response can now hand a trusted `userId` to the
localized six-digit Verify Email screen when the backend returns it; older
responses without that field retain the explicit safe blocker.

## Content intentionally not translated

The application does not translate user-entered values, email addresses,
server/API content, or Japanese vocabulary/Kanji examples. Local fixture
repositories still contain Vietnamese demonstration meanings, explanations,
lesson copy, and roadmap descriptions. Those values represent sample study
content rather than reusable UI labels; automatically translating them in the
presentation layer could alter Japanese-learning meaning. They should move to
localized content fixtures or backend-managed localized content in a dedicated
content phase.

## Maintenance

When adding a user-facing label:

1. Add the same key to both `app_vi.arb` and `app_ja.arb`.
2. Run `flutter gen-l10n`.
3. Read the generated value through `context.l10n` or
   `appLocalizationsProvider`.
4. Add narrow-width and both-locale widget coverage where the text can affect
   layout.
5. Run `dart format .`, `flutter analyze`, `flutter test`, and
   `git diff --check`.

Do not pass language flags through widget constructors, use scattered
`language == ...` conditions, or translate API/study data as though it were UI
chrome.
