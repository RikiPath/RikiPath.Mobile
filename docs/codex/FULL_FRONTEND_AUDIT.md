# RikiPath Flutter Full Frontend Audit

Audit date: 2026-09-12 (Asia/Bangkok)

Scope: C0 through the current uncommitted C10 lesson work. This is an audit only; no application finding was fixed.

## Executive Summary

The repository has a coherent feature-first Flutter source foundation, centralized configuration/network/storage, a reusable visual system, a state-preserving learner shell, real login/register calls, and fixture-backed Auth, Onboarding, Home, Learning, Roadmap, Progress, and lesson UI tests. It is not yet ready for mobile release or broad API integration.

There are **26 findings**:

| Severity | Count |
|---|---:|
| CRITICAL | 3 |
| HIGH | 9 |
| MEDIUM | 11 |
| LOW | 3 |

The three stop-ship items are the absence of Android/iOS host projects, live Swagger publishing no typed response/status contract, and two sensitive account-change routes lacking source authorization enforcement.

Safe areas to continue after the P0 items are acknowledged:

- configuration parsing, production HTTPS/logging guards, centralized Dio construction, and secure access-token storage;
- the feature-first Controller/Repository separation already used by Auth, Home, and Learning;
- the indexed-stack learner shell and nested Learn routes;
- RikiPath design tokens/widgets and fixture-only UI development within JLPT N5/N4/N3;
- the exact live login/register request contracts, while response parsing remains explicitly source-backed.

Areas needing correction before integration or release:

- mobile platform hosts, authenticated-session restoration/guards/role enforcement, registration verification, password recovery, and JLPT ID discovery;
- lesson discovery/detail composition and real playback progress;
- local SRS/offline schema alignment;
- Profile, Notebook, and Practice data architecture;
- response/error integration tests and Drift migration tests.

Audit evidence:

- Live OpenAPI returned HTTP 200 from http://140.245.43.97/swagger/v1/swagger.json at 2026-09-12T10:21:35+07:00.
- The document is OpenAPI 3.0.1, RikiPath API v1, with 66 paths, 69 operations, and 33 component schemas.
- The fetched JSON SHA-256 is a2079ec3f6b5ace0d6bb1b82a3ec697cfc25b6d762c46c2afd42c4a088c53de4.
- Backend cross-check used the strictly read-only revision 959cad6567ba0101e7fed00c3384948f51c0f47d.
- Flutter inventory contains 91 lib files and 12 test files with 99 declared tests.

## API Contract Audit

API_CONTRACT.md accounts for all 69 live operations. Only two endpoints are currently called by Flutter:

| Frontend call | Live method/route | Request result | Response result | Auth result |
|---|---|---|---|---|
| Login | POST /api/Auth/login | email/password names, types, and required status match | LoginResponse is source-backed; live schema absent | Source public; global live Bearer is inaccurate |
| Register | POST /api/Auth/register | email/password/confirmPassword required; firstName/lastName optional/nullable match | RegisterResponse is source-backed; live schema absent | Source public; global live Bearer is inaccurate |

No frontend endpoint mismatch, invented endpoint, direct Widget HTTP call, DTO field-name/type mismatch, hardcoded numeric JLPT ID, pagination bug, or enum misuse was found in the two implemented calls. All non-Auth feature data is local fixture/hardcoded data rather than a disguised API response. The blockers are missing/incomplete contracts and integration architecture, detailed below.

### F001

- **ID:** F001
- **Feature:** Mobile project foundation
- **Severity:** CRITICAL
- **Category:** ARCHITECTURE
- **Problem:** No Flutter platform host exists, so the repository cannot build or run as an Android or iOS mobile application.
- **Evidence:** The repository root has no android/, ios/, web/, windows/, linux/, or macos/ directory; it contains only the Dart/package layer.
- **Swagger/backend says:** Not applicable; this is a frontend packaging requirement.
- **Frontend currently does:** flutter test can execute package/widget tests, but flutter run and mobile builds have no host project or manifest.
- **Recommended fix:** In a dedicated phase, generate only the approved Android/iOS hosts, preserve the current package identifier decisions, and add scoped development-network configuration where required.
- **Backend change needed:** NO

### F002

- **ID:** F002
- **Feature:** All API integrations
- **Severity:** CRITICAL
- **Category:** API_MISMATCH
- **Problem:** Live Swagger has no typed JSON response schema for any operation and declares only a generic 200 response.
- **Evidence:** All 69 operations in the live document have an untyped 200 response. API_CONTRACT.md can map responses only from the supplied controller/service/response source.
- **Swagger/backend says:** Source returns ApiResponse response bodies and may return 201, 204, 400, 401, 403, 404, or 500, while live OpenAPI does not describe these bodies/statuses.
- **Frontend currently does:** Auth parses source-backed envelope and LoginResponse/RegisterResponse fields that cannot be verified from live OpenAPI.
- **Recommended fix:** Backend should publish response schemas and actual status codes. Until then, keep response DTOs labeled source-backed and add captured runtime contract tests before expanding integration.
- **Backend change needed:** YES

### F003

- **ID:** F003
- **Feature:** Account email/password changes
- **Severity:** CRITICAL
- **Category:** API_MISMATCH
- **Problem:** Sensitive account-change routes appear Bearer-protected in global Swagger/comments but have no authorization attribute in the supplied executable controller source.
- **Evidence:** RikiPath.Backend/RikiPath.WebApi/Controllers/AuthController.cs exposes PUT /api/Auth/update-email/{userId} and POST /api/Auth/change-password/{userId}; neither the controller nor actions have Authorize.
- **Swagger/backend says:** Live Swagger applies global Bearer to every operation, and controller comments say Bearer is required; source enforcement disagrees and accepts a path userId.
- **Frontend currently does:** It does not call these routes, which is the safe behavior.
- **Recommended fix:** Do not integrate. Backend must enforce authenticated self-service identity, preferably derive the user ID from claims, and republish accurate per-operation security.
- **Backend change needed:** YES

## Core / Network Audit

Verified strengths:

- AppConfig requires APP_ENV, API_BASE_URL, SWAGGER_URL, and ENABLE_API_LOGGING; it rejects non-HTTPS production API origins and production API logging.
- The API origin is injected at bootstrap. Widgets contain no hardcoded URL and no direct Dio/ApiClient usage.
- ApiClient centralizes timeouts, JSON headers, bearer injection, metadata-only development logs, envelope failures, and Dio failures.
- TokenStorage uses flutter_secure_storage for persisted access tokens and memory for non-persisted sessions. No refresh flow has been invented.
- Auth transport DTOs remain in data code; no backend DTO type is passed directly into a presentation widget.
- The reviewed hand-written null assertions are guarded by the same state/nullable condition or derive from required GoRouter path parameters. No demonstrated unsafe-null defect was found.

### F014

- **ID:** F014
- **Feature:** API error mapping
- **Severity:** MEDIUM
- **Category:** API_MISMATCH
- **Problem:** Automatic ASP.NET Core validation ProblemDetails is not parsed, so field-level validation details can be lost.
- **Evidence:** ApiErrorMapper only recognizes the custom statusCode/isSuccess/errorMessage/errors envelope. ApiController automatic model validation can return title/status/errors where errors is a map of field names to string arrays.
- **Swagger/backend says:** Live Swagger publishes no error response schema; backend controllers use ApiController and DataAnnotations, so automatic model-validation responses are possible before controller code executes.
- **Frontend currently does:** A 400 ProblemDetails body becomes a generic ValidationError without its field messages.
- **Recommended fix:** Extend the centralized mapper with a tested ProblemDetails parser while preserving the custom-envelope parser. Do not put this logic in feature widgets.
- **Backend change needed:** NO

### F024

- **ID:** F024
- **Feature:** Core dependencies and routing support
- **Severity:** LOW
- **Category:** DEAD_CODE
- **Problem:** Declared packages and a placeholder widget have no current consumer.
- **Evidence:** connectivity_plus and just_audio are declared in pubspec.yaml but have no lib import; lib/app/router/route_placeholder_screen.dart has no reference.
- **Swagger/backend says:** Not applicable.
- **Frontend currently does:** Carries dependency/maintenance surface and obsolete placeholder code.
- **Recommended fix:** Confirm near-term ownership, then remove unused dependencies/code or implement them only in an approved feature phase.
- **Backend change needed:** NO

### F026

- **ID:** F026
- **Feature:** Development networking
- **Severity:** LOW
- **Category:** ARCHITECTURE
- **Problem:** The current development API origin is plain HTTP, but no platform-scoped development transport policy can exist while platform hosts are absent.
- **Evidence:** .env.example uses http://140.245.43.97 and ENVIRONMENT.md documents the HTTP limitation; no Android Network Security Config or iOS host configuration exists.
- **Swagger/backend says:** The currently verified deployment and Swagger UI are HTTP.
- **Frontend currently does:** Correctly refuses non-HTTPS production configuration, but a future Android/iOS development build still needs a narrowly scoped exception if the backend remains HTTP.
- **Recommended fix:** After F001, allow only the named development host in development builds. Do not globally enable cleartext or weaken production transport security.
- **Backend change needed:** NO

## Auth Audit

The two implemented network endpoints are exact: POST /api/Auth/login and POST /api/Auth/register. Their request JSON names match live Swagger. The access token is stored securely and no unsupported refresh behavior exists.

### F004

- **ID:** F004
- **Feature:** Authentication lifecycle and protected navigation
- **Severity:** HIGH
- **Category:** ARCHITECTURE
- **Problem:** There is no app-wide authenticated session, token restoration, route guard, logout transition, or local 401 invalidation.
- **Evidence:** SplashScreen always waits 700 ms then goes to /auth/login; createAppRouter has no redirect; /home, /learn, /practice, /notebook, and /profile are directly reachable; UnauthorizedError does not clear TokenStorage.
- **Swagger/backend says:** Learner profile, analytics, progress, notebook, review, practice-test, and most learner operations require a Bearer token. No refresh/logout endpoint exists.
- **Frontend currently does:** Stores a token after login but never uses it to choose the initial route or protect learner routes.
- **Recommended fix:** Add a single session controller that restores/clears TokenStorage, drives GoRouter refresh/redirects, and treats 401 as local session expiry. Do not invent refresh or server logout.
- **Backend change needed:** NO

### F005

- **ID:** F005
- **Feature:** Login authorization
- **Severity:** HIGH
- **Category:** ARCHITECTURE
- **Problem:** Login accepts every backend role and sends it to the learner shell.
- **Evidence:** LoginResponseDto parses role, but the login flow does not require role == Learner before navigation.
- **Swagger/backend says:** Source role values are Learner, ContentAuthor, Consultant, and Admin; learner endpoints use Authorize(Roles = Learner).
- **Frontend currently does:** Treats any successful token/role as a learner session.
- **Recommended fix:** Validate the source-backed role at the session boundary, clear incompatible tokens, and show a supported error. Reconfirm this behavior once responses are typed in live Swagger.
- **Backend change needed:** NO

### F006

- **ID:** F006
- **Feature:** Registration and email verification
- **Severity:** HIGH
- **Category:** MISSING_FIELD
- **Problem:** The mobile client cannot continue from registration to the existing verification endpoint without inventing a user ID.
- **Evidence:** RegisterResponseDto/source RegisterResponse returns only fullName and email. POST /api/Auth/verify-email requires userId and verificationCode.
- **Swagger/backend says:** Register creates an unverified Learner and login rejects unverified accounts, but the registration response does not expose the new userId.
- **Frontend currently does:** Shows local registration success and cannot call verify-email.
- **Recommended fix:** Backend should return a safe verification correlation/user identifier or offer an email/token-based verification contract, then publish the response schema.
- **Backend change needed:** YES

### F007

- **ID:** F007
- **Feature:** Forgot password
- **Severity:** HIGH
- **Category:** MISSING_API
- **Problem:** A routed forgot-password screen exists but can never submit successfully against the API.
- **Evidence:** ApiAuthRepository.requestPasswordReset always throws PasswordRecoveryUnavailableException; live Swagger has no forgot/reset-password operation.
- **Swagger/backend says:** POST /api/Email/send-validation accepts arbitrary HTML and is backend/admin-oriented, not a password-recovery contract.
- **Frontend currently does:** Presents a production-looking form and then reports unavailability.
- **Recommended fix:** Keep the limitation explicit; connect only after purpose-built forgot/reset contracts, expiry/rate-limit behavior, and response schemas exist.
- **Backend change needed:** YES

### F021

- **ID:** F021
- **Feature:** Auth repository integration
- **Severity:** MEDIUM
- **Category:** TEST_GAP
- **Problem:** The real auth repository path is not proven against a mocked Dio transport and token side effects.
- **Evidence:** Tests cover DTO parsing, validators, controller/screen behavior with fakes, ApiClient construction, and TokenStorage separately; no test executes ApiAuthRepository through a mock HTTP response/error.
- **Swagger/backend says:** Success uses a source-backed ApiResponse envelope, and live response schemas/statuses are absent.
- **Frontend currently does:** Relies on isolated unit/widget tests, leaving envelope parsing plus token persistence behavior unverified as one flow.
- **Recommended fix:** Add repository contract tests for success, malformed envelope, typed errors, persisted/non-persisted tokens, and role rejection after F005.
- **Backend change needed:** NO

## Onboarding Audit

The UI correctly limits the product scope to typed N5/N4/N3 values and typed 15/30/45/60-minute choices. It does not invent numeric backend IDs.

### F008

- **ID:** F008
- **Feature:** JLPT goal onboarding
- **Severity:** HIGH
- **Category:** MISSING_MAPPING
- **Problem:** N5/N4/N3 cannot be mapped safely to the integer targetJlptLevelId required by the API.
- **Evidence:** Live Swagger has no JLPT catalog/name-to-ID endpoint and publishes no allowed IDs. POST /api/UserProfile/me/jlpt-goal requires targetJlptLevelId.
- **Swagger/backend says:** Source has admin-configurable JLPT entities covering N5 through N1; no stable ID mapping is exposed to the learner client.
- **Frontend currently does:** Uses the correct product enum N5/N4/N3 and completes onboarding locally without an API call.
- **Recommended fix:** Backend should expose an authenticated/public JLPT catalog with stable IDs and supported states. Until then, retain typed labels and never hardcode numeric IDs.
- **Backend change needed:** YES

### F009

- **ID:** F009
- **Feature:** Onboarding-to-dashboard state
- **Severity:** HIGH
- **Category:** ARCHITECTURE
- **Problem:** A learner's completed onboarding choices are not persisted or shared with downstream screens.
- **Evidence:** OnboardingController owns transient provider state; completeLocally only changes the step. Home and Learning load independent N4 fixtures regardless of the selected level/time.
- **Swagger/backend says:** A JLPT-goal update exists but is blocked by F008; no server onboarding-complete field exists.
- **Frontend currently does:** Can let a user select N5 and immediately show N4 content/setup after entering /home.
- **Recommended fix:** Introduce one learner-preference/session source for local continuity, then synchronize it only after JLPT IDs are contract-derived.
- **Backend change needed:** NO

## Home Audit

Home uses a clean HomeController → HomeRepository boundary, and its fixture is explicitly documented as visual-development data. No fixture ID is sent to an API.

### F015

- **ID:** F015
- **Feature:** Home dashboard data
- **Severity:** MEDIUM
- **Category:** ARCHITECTURE
- **Problem:** Several dashboard fragments remain fixtures even though matching real APIs now exist.
- **Evidence:** FixtureHomeRepository supplies learnerName, JLPT target, streak, unread state, and setup/progress data. The only frontend API paths implemented are Auth login/register.
- **Swagger/backend says:** GET /api/UserProfile/me, GET /api/Analytics/study-streak, GET /api/Analytics/completion-stats, GET /api/Analytics/skill-breakdown, GET /api/Review/daily-queue, and GET /api/Notification/unread-count exist.
- **Frontend currently does:** Uses one static N4 new-learner dashboard. First-lesson discovery, roadmap, and a full dashboard aggregate do not exist in the API.
- **Recommended fix:** After auth/session correction, compose a remote Home repository for the contract-covered fragments and retain explicit unavailable states for roadmap/current lesson instead of inventing data.
- **Backend change needed:** NO

### F017

- **ID:** F017
- **Feature:** Cross-feature learner state
- **Severity:** MEDIUM
- **Category:** UI_MISMATCH
- **Problem:** Main-shell screens present mutually inconsistent learner identity/progress as if all were current.
- **Evidence:** Home is a new N4 learner with a 1-day streak and lesson 1; Learning is N4 with a 12-day streak, 58% progress, and lesson 19; Profile is N3 with 68% and score 112; Practice is also a hardcoded N3 test.
- **Swagger/backend says:** UserProfile/me and analytics provide one authenticated learner's profile and metrics; no API supports simultaneous contradictory states.
- **Frontend currently does:** Each screen owns unrelated constants/fixtures with no shared learner state.
- **Recommended fix:** Establish a single learner profile/progress source and label isolated visual fixtures clearly until replaced. Keep selected onboarding level consistent across tabs.
- **Backend change needed:** NO

## Learning Audit

Learning, Roadmap, Progress, and C10 lessons follow Controller → Repository → domain model → Widget boundaries. C10 uses non-numeric fixture route keys and remoteLessonId == null, so it does not pretend fixture IDs are backend IDs. Its media adapter never hardcodes a URL.

### F010

- **ID:** F010
- **Feature:** Learning roadmap and lesson detail
- **Severity:** HIGH
- **Category:** MISSING_API
- **Problem:** The backend cannot discover lessons or supply the complete Stitch lesson composition.
- **Evidence:** The only lesson read is GET /api/LessonProgress/lessons/{lessonId}, which requires a known numeric ID. There is no course catalog, roadmap, lesson list/by-level/by-skill, prerequisite, or next-lesson route.
- **Swagger/backend says:** Source LessonDetailResponse supplies basic title/content/media/order/progress fields but not JLPT/category/chapter objective, structured parts/examples/vocabulary/related grammar/notes/mastery, duration, prerequisites, or next/previous links.
- **Frontend currently does:** Builds Learning and C10 from typed N4 fixtures with local route IDs.
- **Recommended fix:** Keep fixture work isolated. Backend must expose discovery and a structured detail/navigation contract before the remote repository is implemented.
- **Backend change needed:** YES

### F011

- **ID:** F011
- **Feature:** Lesson video progress
- **Severity:** HIGH
- **Category:** ARCHITECTURE
- **Problem:** Playback position is not connected to the lesson controller, and completion can be granted from a CTA without proving actual playback.
- **Evidence:** LessonMediaDriver exposes initialize/play/pause but no position stream/current-position API; savePlaybackPosition has no caller; completeLesson sends positionSeconds equal to full fixture duration.
- **Swagger/backend says:** PATCH /api/LessonProgress/lessons/{lessonId}/playback-position calculates completion at at least 95% using positionSeconds and durationSeconds.
- **Frontend currently does:** Implements fixture playback state and can mark the fixture complete through a direct full-duration repository update.
- **Recommended fix:** Before remote integration, expose actual media position/duration, throttle persistence, flush on lifecycle/pause, and let the server-returned progress determine completion.
- **Backend change needed:** NO

### F016

- **ID:** F016
- **Feature:** Learning summary and progress
- **Severity:** MEDIUM
- **Category:** ARCHITECTURE
- **Problem:** Contract-covered profile/analytics fragments are not used in Learning and Progress.
- **Evidence:** FixtureLearningRepository supplies initials, JLPT target, streak, overall completion, and skill totals; no Learning API repository exists.
- **Swagger/backend says:** UserProfile/me plus study-streak, completion-stats, and skill-breakdown endpoints exist; roadmap chapters, lesson totals, exam date, and current lesson discovery do not.
- **Frontend currently does:** Displays a complete static N4 snapshot.
- **Recommended fix:** Compose the available endpoints after session correction and model unsupported roadmap/current-lesson fields as unavailable, not inferred.
- **Backend change needed:** NO

### F018

- **ID:** F018
- **Feature:** Lesson content tabs
- **Severity:** MEDIUM
- **Category:** UI_MISMATCH
- **Problem:** The Notes tab looks interactive but cannot be selected.
- **Evidence:** LessonContentView invokes onSelected(LessonContentTab.notes), while LessonController.selectTab returns immediately for notes.
- **Swagger/backend says:** LessonDetailResponse has no learner note field or lesson-note endpoint.
- **Frontend currently does:** Silently ignores the tap rather than disabling/explaining the unavailable feature.
- **Recommended fix:** Until a notes contract exists, render the control disabled with an honest state or remove it from the implemented interaction.
- **Backend change needed:** NO

### F020

- **ID:** F020
- **Feature:** Lesson mutations
- **Severity:** MEDIUM
- **Category:** ARCHITECTURE
- **Problem:** Playback-save and completion repository failures have no modeled loading/error/retry state.
- **Evidence:** savePlaybackPosition and completeLesson await repository updates outside AsyncValue.guard/try-catch; only media initialize/play/pause errors are converted to view state.
- **Swagger/backend says:** Progress updates can return validation, unauthorized, forbidden/not-found, or server failures even though live Swagger does not type them.
- **Frontend currently does:** Works with an in-memory fixture repository; a future network exception could escape the UI event handler.
- **Recommended fix:** Add explicit mutation state and mapped retry/error behavior before swapping in a remote repository.
- **Backend change needed:** NO

## UI / Stitch Audit

The implemented Auth, Register, Onboarding, Home, shell, Learning 01–03, and C10 Learning 07–14 flows consistently reuse AppColors, AppTypography, spacing/radius/shadow tokens, and Riki shared widgets. Portrait/mobile assumptions are preserved. Stitch was used only as UI evidence in this audit.

### F019

- **ID:** F019
- **Feature:** Practice, Notebook, and Profile shell tabs
- **Severity:** MEDIUM
- **Category:** ARCHITECTURE
- **Problem:** Three routed screens are production-looking hardcoded demos with no controller/repository and no-op actions.
- **Evidence:** practice_screen.dart, notebook_screen.dart, and profile_screen.dart embed N3 scores/counts/content and onPressed/onTap empty callbacks directly in widgets.
- **Swagger/backend says:** Practice-test, Notebook, Review, UserProfile, and Analytics APIs exist with the gaps documented below.
- **Frontend currently does:** Bypasses the architecture used by Home/Learning and does not implement the approved MOCK_TEST, NOTEBOOK, and SHELL/Profile Stitch references as stateful flows.
- **Recommended fix:** Treat these screens as explicit placeholders until their feature phases; then introduce feature repositories/controllers and map only verified contracts.
- **Backend change needed:** NO

### F025

- **ID:** F025
- **Feature:** Japanese typography and visual regression
- **Severity:** LOW
- **Category:** TEST_GAP
- **Problem:** Japanese rendering and Stitch fidelity have not been verified on a real mobile font stack or by golden/screenshot tests.
- **Evidence:** AppTheme lists Noto Sans, Noto Sans JP, and Roboto fallbacks but bundles no font asset; current tests assert widget behavior/text, not rendered glyphs/layout.
- **Swagger/backend says:** Not applicable; Stitch is the UI source of truth.
- **Frontend currently does:** Relies on fonts installed by the target platform and manual visual comparison.
- **Recommended fix:** After platform hosts exist, verify N5/N4/N3 Japanese samples on Android/iOS and add focused golden tests at approved portrait sizes for stable core components/screens.
- **Backend change needed:** NO

## Database / Offline Audit

Drift generated code is present and matches a schemaVersion of 1. The database/provider has no application consumer yet, which prevents current user data corruption but also means offline behavior shown in Notebook is not implemented.

### F012

- **ID:** F012
- **Feature:** Review/SRS local schema
- **Severity:** HIGH
- **Category:** API_MISMATCH
- **Problem:** The draft local review scale and identifiers do not match the verified submit contract.
- **Evidence:** ReviewLogs.rating documents 0 Again, 1 Hard, 2 Good, 3 Easy and stores a vocabularyId; live SubmitReviewRequest requires reviewItemId and quality 1..5.
- **Swagger/backend says:** Backend source maps quality 1–2 to Again, 3 to Hard, 4 to Good, and 5 to Easy; it updates by integer ReviewItem ID.
- **Frontend currently does:** Has no sync consumer, but the generated schema encodes a mapping that would submit invalid 0 values and different semantics.
- **Recommended fix:** Before SRS implementation, model the server reviewItemId and numeric quality 1..5 explicitly; keep any four-button UI-to-quality choice as a product decision grounded in the source mapping.
- **Backend change needed:** NO

### F013

- **ID:** F013
- **Feature:** Offline notebook/SRS synchronization
- **Severity:** MEDIUM
- **Category:** ARCHITECTURE
- **Problem:** The database assumes a sync protocol that the backend does not expose.
- **Evidence:** Local tables contain dirty, serverVersion, synced, PendingSyncOperations, operation strings, retryCount, and text client IDs; appDatabaseProvider is otherwise unused.
- **Swagger/backend says:** There is no sync push/pull, version, tombstone, idempotency, client-event, batch-review, or conflict-resolution API.
- **Frontend currently does:** Defines queue/version semantics and claims offline capability in the hardcoded Notebook banner without an end-to-end protocol.
- **Recommended fix:** Quarantine the draft tables from feature logic. Backend must define sync identities, ordering, idempotency, deletion, and conflict semantics before offline synchronization is implemented.
- **Backend change needed:** YES

### F022

- **ID:** F022
- **Feature:** Drift correctness and migrations
- **Severity:** MEDIUM
- **Category:** TEST_GAP
- **Problem:** No test proves table constraints, queries, upgrades, or generated/schema consistency.
- **Evidence:** There is no test/core/database test; AppDatabase schemaVersion is 1 with no migration strategy.
- **Swagger/backend says:** Backend notebook/review IDs are int32 and several local fields currently diverge, increasing migration risk once data is stored.
- **Frontend currently does:** Tracks app_database.g.dart and exposes watchDueVocabulary/upsert/enqueue helpers without database tests.
- **Recommended fix:** After the schema contract is corrected, add in-memory Drift tests and an explicit migration strategy before shipping persistent user data.
- **Backend change needed:** NO

## Routing Audit

The app uses one centralized GoRouter and StatefulShellRoute.indexedStack. Splash/Auth/Onboarding sit outside the shell; Home/Learn/Practice/Notebook/Profile are five preserved branches; Roadmap, Progress, and Lesson are correctly nested under Learn. Route constants are centralized, and smoke tests cover the shell and major paths.

The single /onboarding route intentionally renders three controller states rather than creating parallel stacks. The principal routing defect is the missing session/authorization redirect in F004. No duplicate router or feature-owned navigation state was found.

## Test Coverage Audit

The current suite covers environment parsing, ApiClient construction/error cases, secure storage, shared design widgets, route/shell smoke behavior, Auth DTO/controller/screen behavior, Onboarding state/navigation, Home states, Learning/Roadmap/Progress, and C10 detail/video/article/completion/locked/loading/error states.

Important gaps are recorded in F021 (auth repository), F022 (Drift/migrations), and F025 (rendered Japanese/Stitch fidelity). Session restoration/guards, unauthorized transitions, and real API repository behavior also need tests when F004 and remote repositories are implemented.

### F023

- **ID:** F023
- **Feature:** Project documentation
- **Severity:** MEDIUM
- **Category:** DOCUMENTATION
- **Problem:** Several tracked implementation/audit documents report an obsolete environment and project state.
- **Evidence:** PROJECT_AUDIT.md says the root is not a Git repository, Flutter/Dart are unavailable, and generated Drift code is absent; AUTH_IMPLEMENTATION.md, ONBOARDING_IMPLEMENTATION.md, and HOME_IMPLEMENTATION.md retain not-executed SDK validation; README lists a 73-test baseline while 99 tests are currently declared; LEARNING_IMPLEMENTATION.md predates current C10.
- **Swagger/backend says:** Live Swagger is accessible and current API_CONTRACT/API_GAPS have been revalidated on 2026-09-12.
- **Frontend currently does:** Leaves historical phase documents readable as if they were current status.
- **Recommended fix:** Preserve useful phase history but label it historical, replace false current-state assertions, and update the README baseline only after the final validation result is known.
- **Backend change needed:** NO

## Backend Gaps

### Existing APIs that can replace fixture fragments

| Frontend area | Existing live operations | What can be replaced now | What remains blocked |
|---|---|---|---|
| Auth | Auth/login, Auth/register, Auth/verify-email | Login/register requests are already real | Typed live responses, session lifecycle, verification handoff, password recovery |
| Home | UserProfile/me; three Analytics reads; Review/daily-queue; Notification/unread-count | Name/profile target, streak, completion/skill metrics, review count, unread count | Dashboard aggregate, roadmap, current/first lesson discovery |
| Learning/Progress | UserProfile/me; three Analytics reads | Learner target, streak, completion, skill breakdown | Course/roadmap/chapters, totals, current lesson, exam date |
| Profile | UserProfile/me and update/avatar/JLPT-goal/notification settings | Profile details and supported mutations, after JLPT mapping/session fixes | Safe email change and session/device management |
| Notebook/SRS | Notebook list/entry/bookmark operations; Review daily-queue/submit-result | Online notebook and single-review flows | Offline sync/reconciliation/history and edit/move/search/pagination |
| Practice | PracticeTest list/start/submit/result routes | A known-level, whole-attempt flow | JLPT discovery, test detail, resume/expiry/autosave/history |
| Lesson | LessonProgress detail/update | Known numeric lesson detail and video position update | Discovery, structured Stitch content, navigation/prerequisites, non-video completion |

The table does not authorize inventing aggregate DTOs. Each remote repository must compose only fields documented in API_CONTRACT.md.

### Major missing backend capabilities

- Typed live response/error schemas and real status-code declarations.
- JLPT level catalog with stable N5/N4/N3 identifiers.
- Refresh/revocation, password recovery, and a usable registration-to-verification handoff.
- Course, roadmap, lesson-list/discovery, prerequisite, navigation, structured lesson content, and non-video completion contracts.
- Notebook/SRS offline sync, versioning, tombstones, idempotency, batch review, and review history.
- Practice-test detail, active-attempt resume, server expiry, answer autosave, abandon, and attempt history.
- AI advisory retrieval/history/accept/dismiss and a complete asynchronous grading lifecycle.
- Consultation package, consultant, and availability discovery; booking cancel/reschedule; consultation purchase history.
- Push-device token registration and notification archive/delete.

### Live Swagger/source mismatches

- All live responses are untyped and only 200 is declared; source uses typed envelopes and multiple statuses.
- Global Swagger Bearer is applied even to source-public Auth, SharedBank, Email, and PayOS webhook operations.
- Auth update-email/change-password are globally documented as Bearer but unprotected in supplied source.
- Four CoursePurchase operations are live but absent from the supplied backend copy, so role/response behavior is unknown.
- BulkImport is modeled as JSON containing a binary stream and is not a usable upload contract as published.
- Every request body is optional in Swagger even where controller/DTO validation requires values.
- Several required/validation claims in comments disagree with annotations, including file delete and email send.
- Review quality labels are absent from live Swagger; the 1–5 label mapping is known only from source.

See API_GAPS.md for the endpoint-by-endpoint gap register.

## Recommended Fix Order

### P0 — fix before continuing toward release/integration

1. F001: add approved mobile platform hosts.
2. F003: require backend authorization correction for sensitive account routes.
3. F002: obtain typed live response/error/status contracts, or explicitly accept source-backed runtime contract testing as an interim team decision.
4. F004 and F005: implement one learner session lifecycle, protected routing, 401 invalidation, and learner-role enforcement.

### P1 — fix before connecting the affected feature

1. F006 and F007: unblock verification and password recovery with backend contracts.
2. F008: obtain stable JLPT IDs before onboarding/profile/practice/search integration.
3. F010: obtain lesson discovery and structured detail/navigation contracts.
4. F011 and F020: wire real media progress and resilient mutation state.
5. F012: correct the local SRS quality/identifier model.
6. F014: parse validated backend error shapes centrally.
7. F021 and F022: add Auth repository and Drift/migration tests.

### P2 — fixture work may continue with explicit limitations

1. F009 and F017: create one consistent learner/onboarding state.
2. F015 and F016: replace only the Home/Learning fragments covered by existing APIs.
3. F013: keep speculative sync storage quarantined pending backend protocol.
4. F018 and F019: make unavailable/no-op UI honest, then implement in dedicated phases.
5. F025 and F026: perform real-device Japanese/layout checks and add scoped development HTTP policy after platform generation.

### P3 — cleanup later

1. F023: normalize historical documentation and current validation baselines.
2. F024: remove or assign ownership to unused dependencies and placeholder code.

## Validation Record

The mandatory audit validation commands are recorded here after execution. They are not a permanent guarantee and do not change any finding above.

- flutter pub get: PASS — dependencies resolved; three newer versions are outside current constraints.
- dart run build_runner build: PASS — build_runner completed and generated Drift output successfully.
- dart format .: PASS — 103 files inspected, 0 changed.
- flutter analyze: PASS — No issues found.
- flutter test: PASS — 99 tests passed.
