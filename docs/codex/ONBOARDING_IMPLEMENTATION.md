# RikiPath Learner Onboarding Implementation

Implemented on: 2026-09-11 (Asia/Bangkok)

## Scope

C7 implements the learner onboarding presentation and local interaction state only:

1. Select a JLPT target.
2. Select a daily study duration.
3. Review the selected setup and enter the learner home shell.

Authentication, home content, and backend source were not changed. The implementation uses the approved portrait Stitch screenshots as its primary visual reference and reuses the C4B theme tokens and shared controls.

## Frontend structure

- `lib/features/onboarding/application/onboarding_controller.dart` contains the single Riverpod controller and immutable state.
- `lib/features/onboarding/presentation/onboarding_screen.dart` renders all three internal states from that controller.
- `lib/app/router/app_router.dart` imports the screen from the dedicated feature directory while retaining the existing `/onboarding` route.

The temporary onboarding screen formerly located under the authentication presentation folder was removed. No screen owns network or repository code.

## State model

`OnboardingState` contains:

- `currentStep`: `jlptTarget`, `studyTime`, or `complete`.
- `selectedJlptLevel`: nullable typed `JlptLevel` limited to `n5`, `n4`, and `n3`.
- `selectedStudyTime`: nullable typed `DailyStudyTime` limited to 15, 30, 45, and 60 minutes.
- Derived `canContinue` and `canComplete` guards.

Nothing is preselected. The target action is disabled until a target is selected, and the completion action is disabled until both selections exist. Back navigation updates only `currentStep`, so prior choices remain available. The completion summary reads both values from state and does not contain a fixed sample level or duration.

## API decision

The backend source and API reference confirm:

- `POST /api/UserProfile/me/jlpt-goal`
- Bearer authentication with Learner role
- Body fields `targetJlptLevelId` and `dailyStudyMinutes`
- Source service validation for daily minutes from 0 through 1440
- Atomic persistence of both the level ID and daily minutes

The API does not expose a JLPT level catalog or a documented numeric mapping for N5/N4/N3. The source service looks up `targetJlptLevelId` and rejects an unknown ID. Sending an assumed ID would violate `CODEX_RULES.md`, and sending only daily minutes would bind an unconfirmed/default level ID while the service still requires a valid level.

Therefore C7 is **NOT YET SYNCED TO BACKEND**. It creates no profile repository, DTO, fake HTTP request, fake success delay, or invented completion field. The selected values live in the application Riverpod scope for the current app process. Durable local storage was not added because the phase asked for one onboarding state/controller and did not define a persistence lifecycle.

Backend synchronization can be implemented only after the backend supplies a contract-derived N5/N4/N3 ID mapping, for example through a level-catalog endpoint or an explicitly documented stable mapping.

## UI behavior

- Step one renders only N5, N4, and N3 with the requested Vietnamese descriptions.
- Step two renders only 15, 30, 45, and 60 minutes with the requested intensity labels.
- Both steps use `RikiSelectionCard`, `RikiPrimaryButton`, `RikiProgressIndicator`, typed `JlptBadge`, and centralized theme tokens.
- The layout is a scrollable portrait-first native Flutter layout with a constrained readable width and wrapping text.
- Completion shows “Sẵn sàng bắt đầu!”, the required supporting sentence, a dynamic selection summary, and “Bắt đầu học”.
- The completion header uses the truthful local status “Thiết lập hoàn tất”; it does not repeat the Stitch sample's unverified “Đã kích hoạt lộ trình” claim.
- The completion copy does not claim that a backend profile, AI plan, or onboarding-completion flag was created.
- “Bắt đầu học” navigates to `/home` and does not alter the C6 login lifecycle.

## Test coverage

`test/features/onboarding/onboarding_screen_test.dart` contains focused unit/widget coverage for:

- The typed N5/N4/N3-only domain and absence of N1/N2.
- The exact four daily-duration values.
- Disabled target and completion actions before required selection.
- Typed selection storage and step advancement.
- Selection preservation when moving backward from study time and completion.
- Dynamic JLPT and study-time completion content.
- Navigation from completion to `/home` in the learner shell.
- Absence of learner bottom navigation on `/onboarding`.

The existing router smoke test now imports onboarding from its feature-first location.

## Verification

The required commands for this phase are:

```text
flutter pub get
dart format .
flutter analyze
flutter test
```

- `flutter pub get` — **NOT EXECUTED — Flutter/Dart SDK unavailable** (`flutter` command not found).
- `dart format .` — **NOT EXECUTED — Flutter/Dart SDK unavailable** (`dart` command not found).
- `flutter analyze` — **NOT EXECUTED — Flutter/Dart SDK unavailable** (`flutter` command not found).
- `flutter test` — **NOT EXECUTED — Flutter/Dart SDK unavailable** (`flutter` command not found).

Real-device checks remain required for Japanese glyph fallback, text scaling, screen readers, and compact portrait devices.
