# RikiPath Routing Architecture

Reviewed on: 2026-09-11 (Asia/Bangkok)

## Router setup

RikiPath uses `go_router` through `createAppRouter()` in `lib/app/router/app_router.dart`. `appRouterProvider` owns the router for the application and disposes it with the root Riverpod scope. Route constants are centralized in `lib/app/router/app_routes.dart`.

The router does not currently implement authentication redirects or an onboarding-completion redirect. Those behaviors must not be added until the authentication lifecycle and a durable onboarding-completion contract are defined.

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

`RikiBottomNavigationBar` is presentation-only: it receives the shell's current index and reports a destination index. It does not know route strings, instantiate feature screens, or own navigation state.

Splash, authentication, and onboarding routes sit outside the stateful shell and therefore do not show bottom navigation.

## Current transitions

- Splash advances to `/auth/login` after its existing timer.
- Successful login goes directly to `/home`. C7 does not change this approved C6 behavior.
- Login can navigate to registration or forgot password.
- Registration success and forgot-password success return to login.
- The first onboarding step leaves for login when there is no previous route; later onboarding back actions move to the preceding internal step and preserve controller state.
- The onboarding completion action goes to `/home`.
- Home's learning CTAs select `/learn`, its notebook shortcut selects `/notebook`, its practice shortcut selects `/practice`, and its avatar selects `/profile`; these are existing shell branches, not new deep routes.

The `/home` transition means only that the local onboarding flow is finished. It does not prove that a server-side completion flag or profile update has been stored.

## Guardrails for future routing changes

- Keep route paths in `AppRoutes`; do not hardcode paths in Widgets.
- Keep splash, authentication, and onboarding outside the learner shell.
- Preserve `StatefulShellRoute.indexedStack` unless a proven navigation requirement supersedes it.
- Do not add completion/auth redirects without a defined source of truth and restoration behavior.
- Add router smoke tests whenever a route, shell branch, or redirect changes.
