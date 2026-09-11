# RikiPath Home Implementation

Reviewed on: 2026-09-11 (Asia/Bangkok)

## Scope

C8 implements the final learner-shell bottom navigation and the first final Home composition. It does not implement lesson, practice, notebook, profile, notification, or other post-auth feature flows. `RikiPath.Backend/` remains read-only.

## Visual sources

`screen.png` was treated as primary and `code.html` as secondary measurement/color evidence.

| Reference | C8 use |
|---|---|
| `HOME_01_Trang chủ - Người học mới/` | Default Home success composition and presentation fixture. |
| `HOME_02_Trang chủ - Trạng thái ngoại tuyến/` | Documents a future cached/offline state; not enabled without a cache contract. |
| `HOME_03_Trang chủ - Trạng thái đang tải/` | Static skeleton hierarchy for Home loading. |
| `HOME_04_Thông báo/` | Header notification affordance evidence only; no route was invented. |
| `SHELL_01_Trang chủ - Mobile Shell/` through `SHELL_05_Cá nhân - Mobile Shell/` | Shared five-tab labels, selected/unselected treatment, dimensions, safe-area behavior, and branch ownership. |

The learner shell uses a 16-pixel content edge, pale blue-white canvas, white surface-led header/navigation, warm subtle borders, compact metadata, and the established RikiPath red for active controls. Flutter uses responsive constraints and safe areas rather than reproducing the raster dimensions.

## Architecture

Home follows the required one-way boundary:

`HomeScreen` → `HomeController` → `HomeRepository`

- `HomeScreen` watches `homeControllerProvider` and selects loading, success, or error presentation.
- `HomeController` is an `AsyncNotifier<HomeDashboard>` and owns loading/retry transitions.
- `HomeRepository` is a domain interface.
- `FixtureHomeRepository` is the current presentation data source and is outside Widgets.
- `HomeDashboard` and its child models are typed immutable presentation-domain values. JLPT uses the existing `JlptLevel` enum, which contains only N5/N4/N3.

This phase deliberately does not add DTO parsing, Dio calls, endpoint paths, persistence, or an artificial Home aggregation service.

## Data and API boundary

The approved new-learner Home contains combined greeting, target, lesson, roadmap, setup, and tool-summary content. `API_CONTRACT.md` proves some independent endpoints that are relevant to parts of that composition.

Confirmed source-backed APIs that could supply individual future Home fragments are:

- `GET /api/UserProfile/me` for learner/profile fields.
- `GET /api/Analytics/study-streak`, `GET /api/Analytics/completion-stats`, and `GET /api/Analytics/skill-breakdown` for independent analytics.
- `GET /api/Review/daily-queue` for the current review queue.
- `GET /api/LessonProgress/lessons/{lessonId}` only when a lesson ID is already known.
- `GET /api/PracticeTest/level/{jlptLevelId}/tests` only when a level ID is already known.
- `GET /api/Notification/unread-count` for the notification count.
- `POST /api/LearningPath/generate` can generate a path, but it is not a read-latest endpoint and must not be triggered merely to paint Home.

C8 integrates none of these endpoints. Combining independent calls, loading behavior, and partial failure policy requires a separate remote repository decision.

The contract does not prove:

- A Home/dashboard aggregation response.
- A lesson/roadmap listing suitable for discovering the first lesson.
- A JLPT display level to backend `jlptLevelId` mapping.
- A latest AI recommendation endpoint.
- A learner attempt-history endpoint for the established Home variant.

The Home therefore uses a clearly named fixture repository. The fixture is presentation evidence, not an API claim. It does not assign backend IDs, add JSON fields, or call a speculative endpoint. Its setup copy was kept neutral where the PNG implied backend state that the current contract cannot prove.

These gaps were already recorded in `API_GAPS.md`, so C8 does not duplicate them.

## Implemented states

- **Loading:** the content hierarchy from `HOME_03` rendered as static skeleton blocks; no spinner and no fake progress percentage. Because there is no persisted shell-identity source, N4/14-day/MA sample header values are replaced by restrained placeholders until the repository resolves.
- **Success:** the new-learner hierarchy from `HOME_01`, including greeting/goal, first action, roadmap, setup checklist, and notebook/practice shortcuts.
- **Error:** a restrained reusable connection/error card with retry. There is no approved generic error export, so it does not masquerade as the cached offline design.
- **Offline:** documented but deferred. `HOME_02` assumes cached content, and the application has no proven Home cache/freshness/reconciliation implementation.

Errors shown to learners do not expose raw exception messages.

## Navigation

`MainShell` still owns the existing `StatefulShellRoute.indexedStack` branches:

1. `/home` — Trang chủ
2. `/learn` — Học tập
3. `/practice` — Luyện tập
4. `/notebook` — Sổ từ
5. `/profile` — Cá nhân

`RikiBottomNavigationBar` renders the approved shell design and reports destination indices to `MainShell`. This preserves each branch widget tree. Splash, Auth, and Onboarding stay outside the shell.

Home actions only select existing branches. The notification icon remains non-navigating because no notification route or unambiguous tab ownership exists. No new deep route was added.

The other four branch screens keep their pre-C8 placeholder content. Their only C8 page-level adjustment is the approved learner canvas color so the persistent shell feels coherent; C8 does not convert screenshot content into unverified feature data or deep implementations.

## Reuse and responsive behavior

- Global: centralized `AppColors`, `AppTypography`, `AppSpacing`, `AppRadius`, `AppShadows`, `RikiCard`, `RikiPrimaryButton`, and typed `JlptBadge`.
- Shared shell: `RikiBottomNavigationBar`.
- Home-local: `HomeHeader`, loading view, dashboard cards/shortcuts, and error view.
- Greeting/status and tool shortcuts adapt at narrow widths rather than clipping.
- Vietnamese labels and the `文` brand glyph remain Unicode strings; no screenshot text is rasterized.
- The project still has no bundled canonical font. Runtime Japanese glyph coverage must be verified on supported devices when the SDK/device toolchain is available.

## Tests

C8 adds or updates coverage for:

- Home route rendering inside the learner shell.
- Home pending repository and skeleton state without a circular spinner.
- Home fixture success hierarchy.
- Home repository failure and retry presentation.
- Typed N5/N4/N3 scope and absence of N1/N2.
- Home shortcuts selecting Learn and Practice branches.
- All five learner navigation labels.
- Selected navigation semantics and icon treatment.
- Navigation tap-index reporting.
- Existing indexed-stack tab-state preservation smoke tests.
- Existing checks that Splash, Auth, and Onboarding do not show learner navigation.

## Verification

The required commands were attempted on 2026-09-11:

- `flutter pub get` — **NOT EXECUTED — Flutter/Dart SDK unavailable** (`flutter` is not installed or not on `PATH`).
- `dart format .` — **NOT EXECUTED — Flutter/Dart SDK unavailable** (`dart` is not installed or not on `PATH`).
- `flutter analyze` — **NOT EXECUTED — Flutter/Dart SDK unavailable**.
- `flutter test` — **NOT EXECUTED — Flutter/Dart SDK unavailable**.

Backend verification on the same date returned an empty status, empty staged diff, and empty unstaged diff. Backend HEAD remained `959cad6567ba0101e7fed00c3384948f51c0f47d`; its 317-file/1,424,541-byte inventory also matched the pre-C8 baseline. No file under `RikiPath.Backend/` was modified.
