# RikiPath Routing Architecture

Reviewed on: 2026-09-12 (Asia/Bangkok)

## Router setup

RikiPath uses `go_router` through `createAppRouter()` in `lib/app/router/app_router.dart`. `appRouterProvider` owns the router for the application and disposes it with the root Riverpod scope. Route constants are centralized in `lib/app/router/app_routes.dart`.

`AuthSessionController` restores the existing secure access token and exposes
typed `unknown`, `unauthenticated`, and `authenticated` states. The router
listens to that controller directly and applies authentication redirects. It
does not implement an onboarding-completion redirect because no durable
backend completion field exists.

## Registered routes

| Path | Screen | Shell |
|---|---|---|
| `/splash` | `SplashScreen` | None |
| `/auth/login` | `LoginScreen` | None |
| `/auth/register` | `RegisterScreen` | None |
| `/auth/forgot-password` | `ForgotPasswordScreen` | None |
| `/onboarding` | `OnboardingScreen` | None |
| `/home` | `HomeScreen` | Learner shell, branch 0 |
| `/learn` | `LearnScreen` | Learner shell, branch 1 |
| `/learn/roadmap` | `LearningRoadmapScreen` | Learner shell, branch 1 |
| `/learn/progress` | `JlptProgressScreen` | Learner shell, branch 1 |
| `/learn/lesson/:lessonId` | `LessonScreen` | Learner shell, branch 1 |
| `/practice` | `PracticeScreen` | Learner shell, branch 2 |
| `/notebook` | `NotebookScreen` | Learner shell, branch 3 |
| `/profile` | `ProfileScreen` | Learner shell, branch 4 |

There are no separate `/onboarding/jlpt-target`, `/onboarding/study-time`, or `/onboarding/complete` routes in the current router. C7 keeps a single `/onboarding` route and renders its three internal states from one Riverpod controller. This prevents duplicate route stacks while preserving selections when the learner moves backward.

## Learner shell

The five learner destinations are branches of `StatefulShellRoute.indexedStack`. `MainShell` renders the active branch and the Stitch-backed `RikiBottomNavigationBar` with:

1. Trang chủ — `/home`
2. Học tập — `/learn`
3. Luyện tập — `/practice`
4. Sổ từ — `/notebook`
5. Cá nhân — `/profile`

`StatefulNavigationShell.goBranch()` switches tabs and retains each branch widget tree. Selecting the active destination returns that branch to its initial location.

The learning routes are children of `/learn` in branch 1. Navigation from Learning Home to the roadmap, progress, and lesson screens therefore preserves both the learner shell and the selected **Học tập** destination. Back navigation returns through the Learning stack; a directly opened nested route falls back to the appropriate Learning parent.

`RikiBottomNavigationBar` is presentation-only: it receives the shell's current index and reports a destination index. It does not know route strings, instantiate feature screens, or own navigation state.

Splash, authentication, and onboarding routes sit outside the stateful shell and therefore do not show bottom navigation.

## Current transitions

- Splash remains visible while secure token restoration is `unknown`.
- A restored token moves `/splash` to `/home`; an empty/unreadable secure store moves it to `/auth/login`.
- Logged-out users can reach all three auth routes. Other routes redirect to `/auth/login`.
- Authenticated users can reach learner-shell and onboarding routes. Attempts to open splash/auth routes redirect to `/home`.
- Successful Learner login marks the local session authenticated; non-Learner roles are rejected before token storage.
- Local sign-out clears `TokenStorage` and the route guard returns to `/auth/login`. No server logout or token revocation is claimed.
- Login can navigate to registration or forgot password.
- Registration success and forgot-password success return to login.
- The first onboarding step leaves for login when there is no previous route; later onboarding back actions move to the preceding internal step and preserve controller state.
- The onboarding completion action goes to `/home`.
- Home's learning CTAs select `/learn`, its notebook shortcut selects `/notebook`, its practice shortcut selects `/practice`, and its avatar selects `/profile`; these are existing shell branches, not new deep routes.
- Learning Home opens `/learn/roadmap`; the roadmap result action opens `/learn/progress`; the progress screen links back to `/learn/roadmap`.
- The Learning Home continue action and the current Roadmap chapter open `/learn/lesson/:lessonId`.
- Lesson video, article, completion, loading, error, and locked experiences are internal states of `LessonScreen`; they do not create parallel route stacks.
- C10 route parameters are local fixture route keys. They are not presented as numeric backend lesson IDs because no discovery contract provides that mapping.

The `/home` transition means only that the local onboarding flow is finished. It does not prove that a server-side completion flag or profile update has been stored.

## Guardrails for future routing changes

- Keep route paths in `AppRoutes`; do not hardcode paths in Widgets.
- Keep splash, authentication, and onboarding outside the learner shell.
- Preserve `StatefulShellRoute.indexedStack` unless a proven navigation requirement supersedes it.
- Keep authentication redirects driven by the single secure-token session controller.
- Do not add an onboarding-completion redirect without a durable source of truth.
- Do not infer refresh, logout/revocation, expiry, or profile state from the access-token presence check.
- Add router smoke tests whenever a route, shell branch, or redirect changes.
