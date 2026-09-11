# RikiPath Mobile Project Audit

Audit date: 2026-09-11

This is a read-only architecture and contract audit. No Flutter feature code was implemented or refactored. The backend reference copy was inspected without modification.

## Audit scope and evidence

Inspected frontend sources:

- `pubspec.yaml`, `analysis_options.yaml`, `.gitignore`, `README.md`, and `FILE_INVENTORY.txt`;
- all current files under `lib/` and `docs/`, including the five PNG/HTML auth-screen exports under `docs/ui_reference/stitch_mobile/` that appeared after the initial inventory and were inspected before completion;
- the expected `test/` location, which is absent;
- platform, localization, generated-code, asset, and lockfile locations, which are also absent where noted below.

Inspected contract sources in read-only mode:

- `RikiPath.Backend/RikiPath.WebApi/Controllers/`;
- `RikiPath.Backend/RikiPath.Application/Requests/` and `Responses/`;
- relevant services and service interfaces for authentication behavior;
- domain entities and enums, including `JlptLevel`, `UserAccount`, roles, review ratings, and submission types;
- data-annotation validation;
- `RikiPath.Backend/RikiPath.WebApi/Program.cs` for JWT, JSON enum, CORS, and Swagger configuration;
- deployed [RikiPath API Swagger](http://140.245.43.97/swagger/index.html) and `/swagger/v1/swagger.json` using read-only GET navigation.

## Current Flutter structure

The source is a small Sprint 0 starter rather than a complete generated Flutter application.

```text
lib/
├── main.dart
├── app/
│   ├── app.dart
│   ├── router/
│   │   ├── app_router.dart
│   │   └── main_shell.dart
│   └── theme/
│       └── app_theme.dart
├── core/
│   ├── database/
│   │   ├── app_database.dart
│   │   └── database_provider.dart
│   ├── network/
│   │   └── api_client.dart
│   ├── storage/
│   │   └── token_storage.dart
│   └── widgets/
│       ├── app_section_card.dart
│       └── jlpt_badge.dart
└── features/
    ├── auth/presentation/
    ├── home/presentation/
    ├── learning/presentation/
    ├── mock_test/presentation/
    ├── notebook/presentation/
    └── profile/presentation/
```

Observed structure details:

- `main.dart` initializes Flutter and wraps `RikiPathApp` in Riverpod `ProviderScope`.
- The feature folders currently contain presentation screens only. There are no feature data sources, repositories, domain models/use cases, or Riverpod feature controllers/notifiers.
- The screens use static placeholder content and empty callbacks. Login/register/onboarding navigate locally without calling an API.
- `core/network`, `core/storage`, and `core/database` are foundation drafts but are not yet integrated into the screens.
- There is no `test/` or `integration_test/` directory.
- There are no `android/`, `ios/`, `web/`, `windows/`, `macos/`, or `linux/` platform directories.
- There is no `pubspec.lock`, asset directory, localization configuration, or generated `app_database.g.dart` file.

## Current packages

Declared runtime dependencies:

| Package | Version | Current evidence of use |
|---|---:|---|
| Flutter SDK | SDK | Material app and all screens |
| `flutter_riverpod` | `^3.4.3` | root `ProviderScope`; router, Dio, secure storage, and database providers |
| `go_router` | `^18.0.1` | top-level routes and stateful bottom-tab shell |
| `dio` | `^5.11.1` | centralized client draft with bearer-token interceptor |
| `flutter_secure_storage` | `^11.0.0` | access/refresh token storage abstraction |
| `drift` | `^2.34.4` | local notebook/review/sync table definitions |
| `drift_flutter` | `^0.3.1` | default SQLite database opening |
| `connectivity_plus` | `^7.3.1` | declared but not used in current `lib/` code |
| `video_player` | `^2.14.0` | declared but not used in current `lib/` code |
| `just_audio` | `^0.10.6` | declared but not used in current `lib/` code |

Declared development dependencies are `flutter_test`, `flutter_lints ^6.0.0`, `build_runner ^2.16.1`, and `drift_dev ^2.34.6`.

`analysis_options.yaml` includes `flutter_lints` and adds `prefer_single_quotes` and `use_super_parameters`. No project-specific analyzer exclusions, strict language settings, or architectural lint rules are configured.

## Existing architecture

The intended organization is feature-first with shared application infrastructure:

- `app/` owns bootstrap, router, navigation shell, and theme.
- `core/` owns cross-feature network, secure storage, local database, and reusable widgets.
- `features/` owns feature UI by bounded area.

The implemented architecture is currently presentation plus infrastructure stubs. Riverpod is available as the dependency-injection/state-management mechanism, but no feature state flow has been established. There is no model mapping boundary between backend DTOs, local Drift rows, and UI/domain models.

The Dio provider reads `API_BASE_URL` through `String.fromEnvironment`, applies timeouts and an `Accept: application/json` header, and adds the stored access token as a bearer token. It currently has an emulator-oriented default URL and only a TODO for token-refresh error handling.

`TokenStorage` wraps `flutter_secure_storage` and exposes access-token and refresh-token methods. This abstraction is reusable, but its required two-token `saveTokens` contract does not match the inspected backend login response, which contains only `accessToken`.

The Drift draft defines vocabulary lists, personal vocabulary entries, review queue items, review logs, and pending sync operations. It has no generated implementation in this checkout, and several local identifiers/fields do not match current backend DTOs.

## Current routing approach

`appRouterProvider` returns one `GoRouter` with `initialLocation: '/splash'`.

Top-level routes:

- `/splash`
- `/login`
- `/register`
- `/onboarding`

The authenticated-looking area is a `StatefulShellRoute.indexedStack` with five branches:

- `/home`
- `/learn`
- `/practice`
- `/notebook`
- `/profile`

`MainShell` maps those branches to a Material 3 `NavigationBar` and uses `goBranch`, preserving branch navigation state through the indexed stack. This shell and five-destination information architecture are reusable.

There is no authentication redirect/guard, route refresh notifier, named-route abstraction, nested feature route hierarchy, or implemented deep-link handling. The splash screen waits 700 ms and always routes to login. Successful form validation in the login screen routes directly to home.

## Current theme and visual language

`AppTheme.light` is the only configured theme. It uses Material 3 and centralizes:

- blue primary and purple secondary brand placeholders;
- background, surface, text, border, success, warning, and danger colors;
- spacing values from 4 to 32;
- radii of 10, 14, and 20;
- app bar, card, input, filled-button, and navigation-bar defaults;
- font fallbacks for `Noto Sans`, `Noto Sans JP`, and `Roboto`.

The existing UI language is light, card-based, moderately rounded, and built around a five-tab portrait mobile shell. `AppSectionCard` and `JlptBadge` are the two reusable shared visual components.

The source and README explicitly label the Flutter theme values as temporary because RikiPath/Stitch design tokens were not available when the starter was created. The currently available `docs/ui_reference/stitch_mobile/` set contains five portrait auth-state exports: login, login validation, login loading, forgot password, and forgot-password success. The exports consistently show a red RikiPath identity centered on `#B7131A`, white or pale-slate surfaces, dark-slate text, rounded inputs/buttons/cards, compact pills, and phone canvases capped between 390 and 430 CSS pixels. The exports use system sans-serif stacks and do not supply a bundled font asset.

The current Flutter primary token is blue `#2563EB`, so it has not been reconciled with the red auth references. The HTML files also contain simulated iOS status bars and Tailwind/browser implementation details; those are reference presentation artifacts, not Flutter components to copy.

No font files are bundled or declared in `pubspec.yaml`, so listing `Noto Sans JP` as a fallback does not guarantee that font is present on every device. The reference screenshots include the kanji `文` in the logo treatment but do not demonstrate general Japanese learning-content rendering.

There is no orientation lock in the current bootstrap. The layouts are phone-oriented, but portrait support has not been enforced or tested in this checkout.

## Backend and deployed contract findings

The local backend is an ASP.NET Core solution organized into Domain, Application, Infrastructure, and WebApi projects. Controllers use the `api/[controller]` route pattern. JWT bearer authentication, role authorization, string enum JSON conversion, and a global Swagger bearer scheme are configured in `Program.cs`.

Most service-backed controller responses use an `ApiResponse<T>` envelope with `statusCode`, `isSuccess`, optional `errorMessage`, optional `errors`, and optional `result`.

The deployed OpenAPI document was reachable on the audit date. It exposed 69 operations and 33 component schemas. Its component schemas cover request types, but none of the 69 operations publishes a typed JSON response schema; each inspected response is an untyped `200` description. Local backend response classes therefore provide useful evidence, but deployed response payloads still need verification before binding production DTOs.

The deployed Swagger and the provided backend copy are not identical. For example, deployed Swagger includes a `CoursePurchase` controller group with four operations, while that controller is absent from the local reference copy. This means future work must record which contract source and date it used and must not assume the source copy always equals the deployed API.

The local backend models JLPT levels as admin-configurable master data and includes a comment describing N5 through N1. However, the deployed Swagger has no endpoint that enumerates JLPT levels or their supported values; learner requests accept an integer `targetJlptLevelId`. The current mobile README, onboarding UI, learning UI, and project documents consistently scope learner support to N5/N4/N3. The frontend should therefore remain N5/N4/N3 until a usable learner-facing contract and approved scope explicitly establish more levels.

## Confirmed contract gaps and mismatches

These are observed differences, not proposed API designs:

| Area | Current frontend/draft | Backend or deployed Swagger evidence |
|---|---|---|
| API routes | Draft uses paths such as `/auth/login`, `/users/me`, and `/vocabulary` | Deployed paths use controller routes such as `/api/Auth/login`, `/api/UserProfile/me`, and `/api/SharedBank/vocabulary/search` |
| Login tokens | `TokenStorage.saveTokens` requires access and refresh tokens; draft lists refresh/logout | `LoginResponse` contains `accessToken`, `userId`, `email`, `fullName`, and `role`; no refresh/logout endpoint is exposed |
| Registration | Current UI asks for one full-name field and does not submit | Request requires `email`, `password`, and `confirmPassword`; `firstName` and `lastName` are separate optional fields; verification is a separate request |
| Profile | Draft lists `GET/PATCH /users/me` | Swagger exposes `GET/PUT /api/UserProfile/me`, avatar upload, JLPT goal, and notification settings |
| Shared banks | Draft describes GET list/filter endpoints | Swagger exposes POST search bodies plus GET-by-integer-ID routes under `/api/SharedBank` |
| Notebook | Draft uses generic entry lists, PATCH updates, and unspecified ID shape | Backend uses integer IDs, list-scoped entry reads, PUT list updates, bookmark-specific routes, manual entry creation, and delete; no entry update route is exposed |
| Review/SRS | Drift comment and draft use ratings `0..3` | `SubmitReviewRequest.quality` is validated from 1 through 5; routes are `/api/Review/daily-queue` and `/api/Review/submit-result` |
| Mock tests | Draft assumes exam sessions, per-answer autosave, expiry, history, and session result routes | Swagger exposes start, whole-attempt submit, result, detailed result, and tests-by-level routes under `/api/PracticeTest`; no answer-autosave route is exposed |
| AI learning path | Draft lists latest and generate endpoints | Swagger exposes only `POST /api/LearningPath/generate` |
| Identifiers | Local Drift tables use text IDs and optional text source IDs | Inspected backend request/response contracts use integer IDs for users, lists, entries, lessons, tests, attempts, submissions, and JLPT levels |
| Offline sync | Draft assumes versions, client event IDs, batch review upload, and conflict behavior | Those fields/endpoints are not exposed by the inspected Swagger or relevant request DTOs |

The existing `docs/API_CONTRACT_DRAFT.md`, `docs/OFFLINE_SYNC.md`, and parts of `docs/SCREEN_MATRIX.md` are planning material. They must not be used as implementation truth where they differ from Swagger/backend evidence.

## What can be reused

Reusable now, with the noted limits:

- the `ProviderScope` and `ConsumerWidget` application bootstrap;
- the `GoRouter` provider, stateful five-branch shell, and bottom navigation structure;
- centralized Material 3 theme/token classes as the single styling seam, while replacing only approved temporary values;
- `AppSectionCard` and `JlptBadge` as basic visual building blocks;
- the five `docs/ui_reference/stitch_mobile/` auth-state PNG/HTML pairs as concrete visual evidence for login, validation, loading, and password-recovery states, subject to confirmation of their approval status;
- the centralized Dio provider pattern, timeouts, bearer interceptor, and environment-driven base-URL seam;
- the secure-storage wrapper concept, after aligning its methods with the actual authentication contract;
- the Drift database/provider pattern and table intent, after reconciling identifiers, review quality, and sync behavior with backend contracts;
- the feature-first top-level folder names and the existing screen information architecture;
- the Vietnamese and Japanese sample text as rendering test fixtures, not as live API data.

Static metrics, learner names, progress, scores, review counts, lesson labels, and test data in screens are mock content and must not become DTO assumptions.

## Technical debt and missing foundation

- The checkout is missing generated Flutter platform projects, `pubspec.lock`, and the Drift generated part file.
- No unit, widget, integration, golden, localization, or Japanese-rendering tests exist.
- Flutter and Dart executables are unavailable in the audit environment, so dependency resolution, code generation, `flutter analyze`, and `flutter test` could not be run.
- Feature screens have no data/domain/state layers and no consistent loading, empty, retry, validation, or error-state architecture.
- Authentication state and route protection are absent.
- The current auth storage abstraction assumes a refresh token that the backend does not issue.
- The deployed OpenAPI contract does not publish typed response bodies.
- The frontend API draft materially diverges from the deployed routes and request shapes.
- Local Drift schema fields, identifier types, rating values, and offline-sync assumptions are not aligned with the current backend contracts.
- Japanese-capable fonts are named as fallbacks but not bundled; localization infrastructure is absent and user-facing strings are hardcoded in screens.
- Portrait is the apparent layout target, but orientation policy and small-device/keyboard behavior are not tested.
- The temporary blue Flutter tokens have not been reconciled with the newly available red auth-screen references, and the repository does not identify whether those exports are final/approved.
- Several declared media/connectivity packages are not yet used. Their presence alone is not an implemented capability.

## Recommended next steps

1. Freeze a dated mobile contract map from deployed Swagger plus the exact local request/response classes. Resolve deployed/local differences and replace or clearly supersede the speculative API draft.
2. Obtain a working Flutter SDK, generate the Android/iOS host projects, resolve dependencies, generate Drift code, and establish a clean `flutter analyze`/`flutter test` baseline before feature work.
3. Establish frontend data boundaries: API envelope parsing, contract-derived DTOs, mappers, repositories, and Riverpod feature state. Keep endpoints out of Widgets.
4. Align the authentication slice first: registration fields, email verification, access-token-only storage behavior, authenticated user state, and router redirects. Treat refresh/logout as blocked until exposed by the backend.
5. Reconcile the offline schema with integer server IDs and the actual review contract. Do not implement sync batching, idempotency, version conflict, or local SRS assumptions until the backend contract supports them.
6. Add localization/string organization, bundle or verify a Japanese-capable font, define portrait behavior, and add representative Japanese rendering tests on target platforms.
7. Confirm the status of the auth references, reconcile their red identity and component styling with centralized Flutter tokens, and define any missing non-auth visual tokens before implementing one vertical feature slice at a time with unit/widget tests and contract fixtures.
8. Add CI checks for formatting, analysis, tests, generated-code consistency, secret scanning, and a backend-directory no-change guard.

## Audit blockers

- The repository root is not a Git working tree in this checkout, so an outer frontend `git diff` is unavailable.
- The nested backend reference is a clean Git working tree and can be verified independently.
- Flutter/Dart tooling is unavailable, and the project lacks generated platform and Drift files, so analysis/tests cannot run here.
- Deployed Swagger omits typed response schemas and differs from the local backend copy in at least the deployed `CoursePurchase` surface.
- Five auth-state visual exports are present, but their final/approved status is not documented and they do not cover the five-tab learner experience or provide reusable font/logo assets.

## Backend integrity verification

Before the audit, the nested backend Git repository had no tracked or untracked changes. A content inventory baseline covered 317 files, 1,424,541 bytes, with aggregate inventory SHA-256:

`6453C990C52A45138E5D34C525C70EAB9ECA66C0428FFDB8D028D5DF0D9E43CB`

The same Git status/diff and content inventory must remain unchanged after creation of these audit documents.
